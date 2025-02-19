class FoormPreviewController < ApplicationController
  # GET '/foorm/preview/:name'
  def index
    return render_404 if Rails.env.production?

    name = params[:name]

    form_questions, latest_version = Foorm::Form.get_questions_and_latest_version_for_name(name)

    return render_404 unless form_questions

    survey_data = {
      facilitators: [
        {
          facilitator_id: 1,
          facilitator_name: 'Alice',
          facilitator_position: 1
        },
        {
          facilitator_id: 2,
          facilitator_name: 'Bob',
          facilitator_position: 2
        },
        {
          facilitator_id: 3,
          facilitator_name: 'Chris',
          facilitator_position: 3
        }
      ],
      workshop_course: "Summer Course",
      workshop_subject: "Sample Subject",
      regional_partner_name: "Regional Partner A",
      is_virtual: false,
      num_facilitators: 3
    }

    @script_data = {
      props: {
        formQuestions: form_questions,
        formName: name,
        formVersion: latest_version,
        surveyData: survey_data,
        submitApi: "/none",
        submitParams: {
          user_id: current_user&.id,
          pd_workshop_id: Pd::Workshop.first.id
        }
      }.to_json
    }

    view_options(full_width: true, responsive_content: true)

    render 'foorm/preview/index'
  end
end
