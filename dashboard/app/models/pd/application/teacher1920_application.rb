# == Schema Information
#
# Table name: pd_applications
#
#  id                          :integer          not null, primary key
#  user_id                     :integer
#  type                        :string(255)      not null
#  application_year            :string(255)      not null
#  application_type            :string(255)      not null
#  regional_partner_id         :integer
#  status                      :string(255)
#  locked_at                   :datetime
#  notes                       :text(65535)
#  form_data                   :text(65535)      not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  course                      :string(255)
#  response_scores             :text(65535)
#  application_guid            :string(255)
#  accepted_at                 :datetime
#  properties                  :text(65535)
#  deleted_at                  :datetime
#  status_timestamp_change_log :text(65535)
#
# Indexes
#
#  index_pd_applications_on_application_guid     (application_guid)
#  index_pd_applications_on_application_type     (application_type)
#  index_pd_applications_on_application_year     (application_year)
#  index_pd_applications_on_course               (course)
#  index_pd_applications_on_regional_partner_id  (regional_partner_id)
#  index_pd_applications_on_status               (status)
#  index_pd_applications_on_type                 (type)
#  index_pd_applications_on_user_id              (user_id)
#

module Pd::Application
  class Teacher1920Application < TeacherApplicationBase
    include Pd::Teacher1920ApplicationConstants

    PRINCIPAL_APPROVAL_STATE = [
      NOT_REQUIRED = 'Not required',
      IN_PROGRESS = 'Incomplete - Principal email sent on ',
      COMPLETE = 'Complete - '
    ]

    REVIEWING_INCOMPLETE = 'Reviewing Incomplete'

    TAUGHT_IN_PAST_NO_BONUS_POINT_RESPONSES = [
      "CS Discoveries",
      "CS Principles (intro or AP-level)",
      "AP CS A",
      "Beauty and Joy of Computing",
      "Code HS",
      "Edhesive",
      "Exploring Computer Science",
      "Mobile CSP",
      "NMSI",
      "Project Lead the Way",
      TEXT_FIELDS[:other_please_list]
    ]

    # These statuses are considered "decisions", and will queue an email that will be sent by cronjob the next morning
    # In these decision emails, status and email_type are the same.
    AUTO_EMAIL_STATUSES = %w(
      accepted_no_cost_registration
      declined
      waitlisted
      registration_sent
    )

    # If the regional partner's emails are SENT_BY_SYSTEM, the application must
    # have an assigned workshop to be set to one of these statuses because they
    # trigger emails with a link to the workshop registration form
    WORKSHOP_REQUIRED_STATUSES = %w(
      accepted_no_cost_registration
      registration_sent
    )

    has_many :emails, class_name: 'Pd::Application::Email', foreign_key: 'pd_application_id'

    validates_uniqueness_of :user_id
    validate :workshop_present_if_required_for_status, if: -> {status_changed?}

    before_save :log_status, if: -> {status_changed?}

    serialized_attrs %w(
      status_log
      principal_approval_not_required
    )

    # @override
    def self.statuses
      %w(
        unreviewed
        pending
        waitlisted
        declined
        accepted_not_notified
        accepted_notified_by_partner
        accepted_no_cost_registration
        registration_sent
        paid
        withdrawn
      )
    end

    def workshop_present_if_required_for_status
      if regional_partner&.applications_decision_emails == RegionalPartner::SENT_BY_SYSTEM &&
          WORKSHOP_REQUIRED_STATUSES.include?(status) && !pd_workshop_id
        errors.add :status, "#{status} requires workshop to be assigned"
      end
    end

    def should_send_decision_email?
      if regional_partner&.applications_decision_emails == RegionalPartner::SENT_BY_PARTNER
        false
      else
        AUTO_EMAIL_STATUSES.include?(status)
      end
    end

    def log_status
      self.status_log ||= []
      status_log.push({status: status, at: Time.zone.now})

      # delete any unsent emails, and queue a new status email if appropriate
      emails.unsent.destroy_all
      queue_email(status) if should_send_decision_email?
    end

    # @override
    # @param [Pd::Application::Email] email
    # Note - this should only be called from within Pd::Application::Email.send!
    def deliver_email(email)
      unless email.pd_application_id == id
        raise "Expected application id #{id} from email #{email.id}. Actual: #{email.pd_application_id}"
      end

      # email_type maps to the mailer action
      TeacherApplicationMailer.send(email.email_type, self).deliver_now
    end

    # Return a string if the principal approval state is complete, in-progress, or not required.
    # Otherwise return nil.
    def principal_approval_state
      response = Pd::Application::PrincipalApproval1920Application.find_by(application_guid: application_guid)
      return COMPLETE + response.full_answers[:do_you_approve] if response

      principal_approval_email = emails.where(email_type: 'principal_approval').order(:created_at).last
      if principal_approval_email
        # Format sent date as short-month day, e.g. Oct 8
        return IN_PROGRESS + principal_approval_email.sent_at&.strftime('%b %-d')
      end

      return NOT_REQUIRED if principal_approval_not_required

      nil
    end

    def formatted_principal_email
      "\"#{principal_greeting}\" <#{principal_email}>"
    end

    def effective_regional_partner_name
      regional_partner&.name || 'Code.org'
    end

    def accepted?
      status.start_with? 'accepted'
    end

    # @override
    def queue_email(email_type, deliver_now: false)
      if email_type == :principal_approval_completed_partner && formatted_partner_contact_email.nil?
        CDO.log.info "Skipping principal_approval_completed_partner for application id #{id}"
      else
        super
      end
    end

    # @override
    def self.options
      {
        country: [
          'United States',
          'Other country'
        ],

        title: COMMON_OPTIONS[:title],
        state: COMMON_OPTIONS[:state],
        gender_identity: COMMON_OPTIONS[:gender_identity],
        race: COMMON_OPTIONS[:race],

        school_state: COMMON_OPTIONS[:state],
        school_type: COMMON_OPTIONS[:school_type],

        principal_title: COMMON_OPTIONS[:title],

        current_role: [
          'Teacher',
          'Instructional coach',
          'Librarian',
          'School administrator',
          'District administrator',
          TEXT_FIELDS[:other_please_list]
        ],

        grades_at_school: GRADES,
        grades_teaching: [
          *GRADES,
          TEXT_FIELDS[:not_teaching_this_year],
          TEXT_FIELDS[:other_please_explain]
        ],
        grades_expect_to_teach: [
          *GRADES,
          TEXT_FIELDS[:not_teaching_next_year],
          TEXT_FIELDS[:other_please_explain]
        ],

        subjects_teaching: SUBJECTS_THIS_YEAR,
        subjects_expect_to_teach: SUBJECTS_THIS_YEAR,

        does_school_require_cs_license: [
          YES,
          NO,
          "I'm not sure",
        ],

        have_cs_license: [
          YES,
          NO,
          "I'm not sure",
          'Not applicable - My district does not require a specific license, certification, or endorsement to teach computer science.'
        ],

        subjects_licensed_to_teach: [
          'Computer Science',
          'Career and Technical Education',
          'Math',
          'Science',
          'History',
          'Social Studies',
          'English/Language Arts',
          'Music',
          'Art',
          'Multimedia',
          'Foreign Language',
          'Business',
          'Special Education',
          'Physical Education',
          'I am not currently licensed',
          TEXT_FIELDS[:other_please_list]
        ],

        previous_yearlong_cdo_pd: [
          'CS Discoveries',
          'CS Principles',
          'Exploring Computer Science',
          'CS in Algebra',
          'CS in Science',
          "I haven't participated in a yearlong Code.org Professional Learning Program"
        ],

        cs_offered_at_school: [
          'AP CS A',
          'Beauty and Joy of Computing',
          'Bootstrap',
          'Code HS',
          'Code Monkey',
          'Codesters',
          'CS in Algebra',
          'CS Discoveries',
          'CS Fundamentals',
          'CS Principles (intro or AP-level)',
          'CS in Science',
          'Edhesive',
          'Exploring Computer Science',
          'Globaloria',
          'Hour of Code',
          'Mobile CSP',
          'NMSI',
          'Project Lead the Way',
          'Pythonroom',
          'Robotics',
          'Scalable Game Design',
          'ScratchEd',
          'Tynker',
          'UC Davis C-Stem',
          'UTeach',
          TEXT_FIELDS[:other_please_list],
          'No computer science courses are offered at my school'
        ],

        cs_opportunities_at_school: [
          'Courses for credit',
          'After school clubs',
          'Lunch clubs',
          'Hour of Code',
          'No computer science opportunities are currently available at my school',
          TEXT_FIELDS[:other_with_text]
        ],

        program: PROGRAM_OPTIONS,

        csd_which_grades: (6..12).map(&:to_s) <<
          'Not sure yet if my school plans to offer CS Discoveries in the 2019-20 school year',

        csd_course_hours_per_week: [
          '5 or more course hours per week',
          '4 to less than 5 course hours per week',
          '3 to less than 4 course hours per week',
          'Less than 3 course hours per week',
          TEXT_FIELDS[:other_please_list]
        ],

        csd_course_hours_per_year: COMMON_OPTIONS[:course_hours_per_year],

        csd_terms_per_year: COMMON_OPTIONS[:terms_per_year],

        csp_which_grades: (9..12).map(&:to_s) <<
          'Not sure yet if my school plans to offer CS Principles in the 2019-20 school year',

        csp_course_hours_per_week: [
          'More than 5 course hours per week',
          '4 - 5 course hours per week',
          'Less than 4 course hours per week'
        ],

        csp_course_hours_per_year: COMMON_OPTIONS[:course_hours_per_year],

        csp_terms_per_year: COMMON_OPTIONS[:terms_per_year],

        csp_how_offer: [
          'As an introductory course',
          'As an AP course',
          'We will offer both introductory and AP-level courses'
        ],

        csp_ap_exam: [
          'Yes, all students will be expected to take the AP CS Principles exam',
          "Students will be encouraged to take the exam, but it won't be required",
          "No, I don't plan for my students to take the AP CS Principles exam"
        ],

        plan_to_teach: [
          'Yes, I plan to teach this course this year (2019-20)',
          'I hope to be able teach this course this year (2019-20)',
          'No, I don’t plan to teach this course this year (2019-20), but I hope to teach this course the following year (2020-21)',
          'No, someone else from my school will teach this course this year (2019-20)',
          TEXT_FIELDS[:dont_know_if_i_will_teach_explain]
        ],

        pay_fee: [
          'Yes, my school will be able to pay the full program fee.',
          TEXT_FIELDS[:no_pay_fee_1920],
          "I don't know."
        ],

        how_heard: [
          'Code.org website',
          'Code.org email',
          'Regional Partner website',
          'Regional Partner email',
          'Regional Partner event or workshop',
          'From a teacher',
          'From an administrator',
          TEXT_FIELDS[:other_with_text]
        ],

        committed: [
          YES,
          'No (Please Explain):'
        ],

        willing_to_travel: [
          'Up to 10 miles',
          'Up to 25 miles',
          'Up to 50 miles',
          'Any distance',
          'I am unable to travel to the school year workshops'
        ],

        taught_in_past: SUBJECTS_TAUGHT_IN_PAST + [
          TEXT_FIELDS[:other_please_list],
          "I don't have experience teaching any of these courses"
        ],
        completing_on_behalf_of_someone_else: [YES, NO],
        replace_existing: [
          YES,
          "No, this course will be added to the schedule in addition to an existing computer science course",
          "No, this course will be added to the existing schedule, but it won't replace an existing computer science course",
          TEXT_FIELDS[:i_dont_know_explain]
        ],
        cs_terms: COMMON_OPTIONS[:terms_per_year],
        travel_to_another_workshop: [
          'Yes, please provide me with additional information about attending a local summer workshop outside of my region.',
          'No, I’m not interested in travelling to attend a local summer workshop outside of my region.',
          TEXT_FIELDS[:not_sure_explain]
        ],
        interested_in_online_program: [YES, NO]
      }
    end

    # @override
    def self.required_fields
      %i(
        country
        school
        first_name
        last_name
        phone
        zip_code
        principal_first_name
        principal_last_name
        principal_email
        principal_confirm_email
        principal_phone_number
        completing_on_behalf_of_someone_else
        current_role

        program
        cs_how_many_minutes
        cs_how_many_days_per_week
        cs_how_many_weeks_per_year
        cs_terms
        plan_to_teach
        replace_existing

        subjects_teaching
        taught_in_past
        previous_yearlong_cdo_pd

        willing_to_travel
        interested_in_online_program

        gender_identity
        race

        agree
      )
    end

    # @override
    def dynamic_required_fields(hash)
      [].tap do |required|
        if hash[:completing_on_behalf_of_someone_else] == YES
          required << :completing_on_behalf_of_name
        end

        if hash[:able_to_attend_multiple]
          if ([TEXT_FIELDS[:not_sure_explain], TEXT_FIELDS[:unable_to_attend_1920]] & hash[:able_to_attend_multiple]).any?
            required << :travel_to_another_workshop
          end
        end

        if hash[:pay_fee] == TEXT_FIELDS[:no_pay_fee_1920]
          required << :scholarship_reasons
        end

        if hash[:program] == PROGRAMS[:csd]
          required << :csd_which_grades
        elsif hash[:program] == PROGRAMS[:csp]
          required << :csp_which_grades
          required << :csp_how_offer
        end

        if hash[:regional_partner_workshop_ids].presence
          required << :able_to_attend_multiple
          required << :committed
        end
      end
    end

    # @override
    def additional_text_fields
      [
        [:current_role, TEXT_FIELDS[:other_please_list]],
        [:grades_teaching, TEXT_FIELDS[:not_teaching_this_year], :grades_teaching_not_teaching_explanation],
        [:grades_teaching, TEXT_FIELDS[:other_please_explain], :grades_teaching_other],
        [:grades_expect_to_teach, TEXT_FIELDS[:not_teaching_next_year], :grades_expect_to_teach_not_expecting_to_teach_explanation],
        [:grades_expect_to_teach, TEXT_FIELDS[:other_please_explain], :grades_expect_to_teach_other],
        [:subjects_teaching, TEXT_FIELDS[:other_please_list]],
        [:subjects_expect_to_teach, TEXT_FIELDS[:other_please_list]],
        [:subjects_licensed_to_teach, TEXT_FIELDS[:other_please_list]],
        [:taught_in_past, TEXT_FIELDS[:other_please_list]],
        [:cs_offered_at_school, TEXT_FIELDS[:other_please_list]],
        [:cs_opportunities_at_school, TEXT_FIELDS[:other_please_list]],
        [:csd_course_hours_per_week, TEXT_FIELDS[:other_please_list]],
        [:plan_to_teach, TEXT_FIELDS[:dont_know_if_i_will_teach_explain], :plan_to_teach_other],
        [:able_to_attend_single, TEXT_FIELDS[:unable_to_attend], :able_to_attend_single_explain],
        [:able_to_attend_multiple, TEXT_FIELDS[:no_explain], :able_to_attend_multiple_explain],
        [:committed, TEXT_FIELDS[:no_explain], :committed_other],
        [:cs_terms, TEXT_FIELDS[:other_with_text]],
        [:plan_to_teach, TEXT_FIELDS[:dont_know_if_i_will_teach_explain]],
        [:replace_existing, TEXT_FIELDS[:i_dont_know_explain]],
        [:able_to_attend_multiple, TEXT_FIELDS[:not_sure_explain], :able_to_attend_multiple_not_sure_explain],
        [:able_to_attend_multiple, TEXT_FIELDS[:unable_to_attend_1920], :able_to_attend_multiple_unable_to_attend],
        [:travel_to_another_workshop, TEXT_FIELDS[:not_sure_explain], :travel_to_another_workshop_not_sure],
        [:how_heard, TEXT_FIELDS[:other_with_text]]
      ]
    end

    # @override
    def year
      YEAR_19_20
    end

    # @override
    def check_idempotency
      Teacher1920Application.find_by(user: user)
    end

    def assigned_workshop
      Pd::Workshop.find_by(id: pd_workshop_id)&.date_and_location_name
    end

    def friendly_scholarship_status
      Pd::ScholarshipInfo.find_by(user: user, application_year: application_year, course: course)&.friendly_status_name
    end

    def allow_sending_principal_email?
      response = Pd::Application::PrincipalApproval1920Application.find_by(application_guid: application_guid)
      last_principal_approval_email = emails.where(email_type: 'principal_approval').order(:created_at).last
      last_principal_approval_email_created_at = last_principal_approval_email&.created_at

      # Do we allow manually sending/resending the principal email?

      # Only if this teacher application is currently unreviewed, pending, or waitlisted.
      return false unless unreviewed? || pending? || waitlisted?

      # Only if the principal approval is required.
      return false if principal_approval_not_required

      # Only if we haven't gotten a principal response yet.
      return false if response

      # Only if it's been more than 5 days since we last created an email for the principal.
      return false if last_principal_approval_email_created_at && last_principal_approval_email_created_at > 5.days.ago

      true
    end

    def allow_sending_principal_approval_teacher_reminder_email?
      reminder_emails = emails.where(email_type: 'principal_approval_teacher_reminder')

      # Do we allow the cron job to send a reminder email to the teacher?

      # Only if this teacher application is currently unreviewed or pending.
      # (Unlike allow_sending_principal_email?, don't allow for waitlisted.)
      return false unless unreviewed? || pending?

      # Only if we haven't already sent one.
      return false if reminder_emails.any?

      # Only if we've sent at least one principal approval email before.
      return false unless emails.where(email_type: 'principal_approval').exists?

      # If it's valid to send another principal email at this time.
      return allow_sending_principal_email?
    end

    # memoize in a hash, per course
    FILTERED_LABELS = Hash.new do |h, key|
      labels_to_remove = (
      if key == 'csd'
        [
          :csp_which_grades,
          :csp_how_offer,
          :csp_ap_exam,
        ]
      else
        [
          :csd_which_grades
        ]
      end
      )

      # school contains NCES id
      # the other fields are empty in the form data unless they selected "Other" school,
      # so we add it when we construct the csv row.
      labels_to_remove.push(:school, :school_name, :school_address, :school_type, :school_city, :school_state, :school_zip_code)

      h[key] = ALL_LABELS_WITH_OVERRIDES.except(*labels_to_remove)
    end

    # @override
    # Filter out extraneous answers based on selected program (course)
    def self.filtered_labels(course)
      raise "Invalid course #{course}" unless VALID_COURSES.include?(course)
      FILTERED_LABELS[course]
    end

    # List of columns to be filtered out based on selected program (course)
    def self.columns_to_remove(course)
      if course == 'csd'
        {
          teacher: [
            :csp_which_grades,
            :csp_how_offer,
          ],
          principal: [
            :share_ap_scores,
            :replace_which_course_csp,
            :csp_implementation
          ]
        }
      else
        {
          teacher: [
            :csd_which_grades
          ],
          principal: [
            :replace_which_course_csd,
            :csd_implementation
          ]
        }
      end
    end

    def self.csv_filtered_labels(course)
      labels = {
        teacher: {},
        principal: {},
        nces: {}
      }
      labels_to_remove = columns_to_remove(course)

      CSV_COLUMNS.keys.each do |source|
        CSV_COLUMNS[source].each do |k|
          unless labels_to_remove[source]&.include? k.to_sym
            labels[source][k] = CSV_LABELS[source][k] || ALL_LABELS_WITH_OVERRIDES[k]
          end
        end
      end
      labels
    end

    def self.csv_header(course)
      labels = csv_filtered_labels(course)
      CSV.generate do |csv|
        columns = []
        labels.keys.each do |source|
          labels[source].keys.each do |k|
            columns.push(labels[source][k])
          end
        end
        csv << columns
      end
    end

    # @override
    def to_csv_row(course)
      columns_to_exclude = Pd::Application::Teacher1920Application.columns_to_remove(course)
      teacher_answers = full_answers
      principal_application = Pd::Application::PrincipalApproval1920Application.where(application_guid: application_guid).first
      principal_answers = principal_application&.csv_data
      school_stats = School.find_by_id(school_id)&.school_stats_by_year&.order(school_year: :desc)&.first
      CSV.generate do |csv|
        row = []
        CSV_COLUMNS[:teacher].each do |k|
          if columns_to_exclude[:teacher]&.include? k.to_sym
            next
          end
          row.push(teacher_answers[k] || try(k) || "")
        end
        CSV_COLUMNS[:principal].each do |k|
          if columns_to_exclude[:principal]&.include? k.to_sym
            next
          end
          if principal_answers
            row.push(principal_answers[k] || principal_application.try(k) || "")
          else
            row.push("")
          end
        end
        CSV_COLUMNS[:nces].each do |k|
          if school_stats
            if [:title_i_status, :students_total, :urm_percent].include? k
              row.push(school_stats[k] || school_stats.try(k) || "")
            else
              row.push(school_stats.percent_of_students(school_stats[k]) || "")
            end
          else
            row.push("")
          end
        end
        csv << row
      end
    end

    # @override
    # Additional labels to include in the form data hash
    def self.additional_labels
      ADDITIONAL_KEYS_IN_ANSWERS
    end

    # @override
    # Called once after the application is submitted. Called again after principal
    # approval is done. Generates scores for responses, is idempotent and does not
    # override existing scores
    #
    # @override
    def auto_score!
      responses = sanitize_form_data_hash

      options = self.class.options
      principal_options = Pd::Application::PrincipalApproval1920Application.options

      meets_minimum_criteria_scores = {
        regional_partner_name: regional_partner.presence ? YES : NO
      }
      meets_scholarship_criteria_scores = {}
      bonus_points_scores = {}

      # Section 2
      if course == 'csd'
        meets_minimum_criteria_scores[:csd_which_grades] = (responses[:csd_which_grades] & options[:csd_which_grades].first(5)).any? ? YES : NO

        meets_minimum_criteria_scores[:cs_total_course_hours] = responses[:cs_total_course_hours].to_i >= 50 ? YES : NO

        bonus_points_scores[:cs_terms] = responses[:cs_terms] == options[:cs_terms][4] ? 2 : 0
      elsif course == 'csp'
        meets_minimum_criteria_scores[:csp_which_grades] = (responses[:csp_which_grades] & options[:csp_which_grades].first(4)).any? ? YES : NO
        meets_minimum_criteria_scores[:cs_total_course_hours] = (responses[:cs_total_course_hours]&.>= 100) ? YES : NO

        bonus_points_scores[:csp_how_offer] = responses[:csp_how_offer].in?(options[:csp_how_offer].last(2)) ? 2 : 0
      end

      if responses[:plan_to_teach].in? options[:plan_to_teach].first(4)
        meets_minimum_criteria_scores[:plan_to_teach] = responses[:plan_to_teach].in?(options[:plan_to_teach].first(2)) ? YES : NO
        meets_scholarship_criteria_scores[:plan_to_teach] = responses[:plan_to_teach] == options[:plan_to_teach].first ? YES : NO
      end

      meets_minimum_criteria_scores[:replace_existing] =
        if responses[:replace_existing] == YES
          NO
        elsif responses[:replace_existing] == TEXT_FIELDS[:i_dont_know_explain]
          nil
        else
          YES
        end

      # Section 3
      if course == 'csd'
        meets_scholarship_criteria_scores[:previous_yearlong_cdo_pd] = (responses[:previous_yearlong_cdo_pd] & ['CS Discoveries', 'Exploring Computer Science']).empty? ? YES : NO
      elsif course == 'csp'
        meets_scholarship_criteria_scores[:previous_yearlong_cdo_pd] = responses[:previous_yearlong_cdo_pd].exclude?('CS Principles') ? YES : NO
      end

      bonus_points_scores[:taught_in_past] = (responses[:taught_in_past] & TAUGHT_IN_PAST_NO_BONUS_POINT_RESPONSES).any? ? 0 : 2

      # Section 4
      meets_minimum_criteria_scores[:committed] = responses[:committed] == options[:committed].first ? YES : NO

      # Section 5
      bonus_points_scores[:race] = ((responses[:race] || []) & (options[:race].values_at(1, 2, 4, 5))).any? ? 2 : 0

      # Principal Approval
      if responses[:principal_approval]
        meets_scholarship_criteria_scores[:principal_approval] =
          responses[:principal_approval] == principal_options[:do_you_approve].first ? YES : NO

        meets_scholarship_criteria_scores[:principal_diversity_recruitment] =
          responses[:principal_diversity_recruitment] == principal_options[:committed_to_diversity].first ? YES : NO

        meets_minimum_criteria_scores[:plan_to_teach] =
          if responses[:principal_plan_to_teach]&.in? principal_options[:plan_to_teach].first(2)
            YES
          elsif responses[:principal_plan_to_teach]&.in? principal_options[:plan_to_teach].slice(2..3)
            NO
          else
            nil
          end

        meets_scholarship_criteria_scores[:plan_to_teach] =
          if responses[:principal_plan_to_teach]&.in? principal_options[:plan_to_teach].first
            YES
          elsif responses[:principal_plan_to_teach]&.in? principal_options[:plan_to_teach].slice(1..3)
            NO
          else
            nil
          end

        meets_minimum_criteria_scores[:principal_schedule_confirmed] =
          if responses[:principal_schedule_confirmed]&.in?(principal_options[:committed_to_master_schedule].slice(0..1))
            YES
          elsif responses[:principal_schedule_confirmed] == principal_options[:committed_to_master_schedule][2]
            NO
          else
            nil
          end

        meets_scholarship_criteria_scores[:principal_schedule_confirmed] =
          if responses[:principal_schedule_confirmed] == principal_options[:committed_to_master_schedule][0]
            YES
          elsif responses[:principal_schedule_confirmed]&.in?(principal_options[:committed_to_master_schedule].slice(1..2))
            NO
          else
            nil
          end

        meets_minimum_criteria_scores[:replace_existing] =
          if responses[:principal_wont_replace_existing_course] == principal_options[:replace_course][1]
            YES
          elsif responses[:principal_wont_replace_existing_course] == TEXT_FIELDS[:i_dont_know_explain]
            nil
          else
            NO
          end

        if course == 'csd'
          meets_minimum_criteria_scores[:principal_implementation] = responses[:principal_implementation]&.in?(principal_options[:csd_implementation].first(2)) ? YES : NO
          bonus_points_scores[:principal_implementation] = responses[:principal_implementation] == principal_options[:csd_implementation][1] ? 2 : 0
        elsif course == 'csp'
          meets_minimum_criteria_scores[:principal_implementation] = responses[:principal_implementation] == principal_options[:csp_implementation].first ? YES : NO
        end

        bonus_points_scores[:free_lunch_percent] = (responses[:principal_free_lunch_percent]&.to_i&.>= 50) ? 5 : 0
        bonus_points_scores[:underrepresented_minority_percent] = ((responses[:principal_underrepresented_minority_percent]).to_i >= 50) ? 5 : 0
      end

      update(
        response_scores: response_scores_hash.deep_merge(
          {
            meets_minimum_criteria_scores: meets_minimum_criteria_scores,
            meets_scholarship_criteria_scores: meets_scholarship_criteria_scores,
            bonus_points_scores: bonus_points_scores
          }
        ) {|key, old, new| key.in?([:plan_to_teach, :replace_existing]) ? new : old}.to_json
      )
    end

    def meets_criteria
      response_scores = response_scores_hash[:meets_minimum_criteria_scores] || {}

      scored_questions = SCOREABLE_QUESTIONS["criteria_score_questions_#{course}".to_sym]

      scores = scored_questions.map {|q| response_scores[q]}

      if scores.uniq == [YES]
        YES
      elsif NO.in? scores
        NO
      else
        REVIEWING_INCOMPLETE
      end
    end

    def meets_scholarship_criteria
      if principal_approval_state == NOT_REQUIRED
        # If there is no needed principal approval, then criteria is just whether
        # the one scholarship question is yes
        response_scores_hash[:meets_scholarship_criteria_scores][:previous_yearlong_cdo_pd] || REVIEWING_INCOMPLETE
      else
        response_scores = response_scores_hash[:meets_scholarship_criteria_scores] || {}
        scored_questions = SCOREABLE_QUESTIONS[:scholarship_questions]

        scores = scored_questions.map {|q| response_scores[q]}

        if scores.uniq == [YES]
          YES
        elsif NO.in? scores
          NO
        else
          REVIEWING_INCOMPLETE
        end
      end
    end

    # @override
    def total_score
      (response_scores_hash[:bonus_points_scores] || {}).values.map(&:to_i).reduce(:+) || 0
    end

    # @override
    def on_successful_create
      update_user_school_info!
      queue_email :confirmation, deliver_now: true

      form_data_hash = sanitize_form_data_hash

      update_form_data_hash(
        {
          cs_total_course_hours: form_data_hash.slice(
            :cs_how_many_minutes,
            :cs_how_many_days_per_week,
            :cs_how_many_weeks_per_year
          ).values.map(&:to_i).reduce(:*) / 60
        }
      )

      auto_score!
      save

      unless regional_partner&.applications_principal_approval == RegionalPartner::SELECTIVE_APPROVAL
        queue_email :principal_approval, deliver_now: true
      end
    end

    # @override
    def on_successful_principal_approval_create(principal_approval)
      # Approval application created, now score corresponding teacher application
      principal_response = principal_approval.sanitize_form_data_hash

      response = principal_response.values_at(:replace_course, :replace_course_other).compact.join(": ")
      replaced_courses = principal_response.values_at(:replace_which_course_csp, :replace_which_course_csd).compact.join(', ')
      # Sub out :: for : because "I don't know:" has a colon on the end
      replace_course_string = "#{response}#{replaced_courses.present? ? ': ' + replaced_courses : ''}".gsub('::', ':')

      implementation_string = principal_response.values_at("#{course}_implementation".to_sym, "#{course}_implementation_other".to_sym).compact.join(" ")
      principal_school = School.find_by(id: principal_response[:school])
      update_form_data_hash(
        {
          principal_response_first_name: principal_response[:first_name],
          principal_response_last_name: principal_response[:last_name],
          principal_response_email: principal_response[:email],
          principal_school_name: principal_school.try(:name) || principal_response[:school_name],
          principal_school_type: principal_school.try(:school_type),
          principal_school_district: principal_school.try(:district).try(:name),
          principal_approval: principal_response.values_at(:do_you_approve, :do_you_approve_other).compact.join(" "),
          principal_plan_to_teach: principal_response.values_at(:plan_to_teach, :plan_to_teach_other).compact.join(" "),
          principal_schedule_confirmed: principal_response.values_at(:committed_to_master_schedule, :committed_to_master_schedule_other).compact.join(" "),
          principal_implementation: implementation_string,
          principal_total_enrollment: principal_response[:total_student_enrollment],
          principal_diversity_recruitment: principal_response.values_at(:committed_to_diversity, :committed_to_diversity_other).compact.join(" "),
          principal_free_lunch_percent: format("%0.02f%%", principal_response[:free_lunch_percent]),
          principal_underrepresented_minority_percent: format("%0.02f%%", principal_approval.underrepresented_minority_percent),
          principal_american_indian_or_native_alaskan_percent: format("%0.02f%%", principal_response[:american_indian]),
          principal_asian_percent: format("%0.02f%%", principal_response[:asian]),
          principal_black_or_african_american_percent: format("%0.02f%%", principal_response[:black]),
          principal_hispanic_or_latino_percent: format("%0.02f%%", principal_response[:hispanic]),
          principal_native_hawaiian_or_pacific_islander_percent: format("%0.02f%%", principal_response[:pacific_islander]),
          principal_white_percent: format("%0.02f%%", principal_response[:white]),
          principal_other_percent: format("%0.02f%%", principal_response[:other]),
          principal_wont_replace_existing_course: replace_course_string,
          principal_send_ap_scores: principal_response[:send_ap_scores],
          principal_pay_fee: principal_response[:pay_fee],
          principal_contact_invoicing: principal_response[:contact_invoicing],
          principal_contact_invoicing_detail: principal_response[:contact_invoicing_detail]
        }
      )
      save!
      auto_score!
      queue_email(:principal_approval_completed, deliver_now: true)
      queue_email(:principal_approval_completed_partner, deliver_now: true)
    end

    # @override
    def default_response_score_hash
      {
        meets_minimum_criteria_scores: {},
        meets_scholarship_criteria_scores: {},
        bonus_points_scores: {}
      }
    end
  end
end
