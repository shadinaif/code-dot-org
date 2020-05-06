import PropTypes from 'prop-types';
import React from 'react';
import LessonGroup from './LessonGroup';
import LessonDescriptions from './LessonDescriptions';
import ScriptAnnouncementsEditor from './ScriptAnnouncementsEditor';
import ProgressLegend from '@cdo/apps/templates/progress/ProgressLegend';
import $ from 'jquery';
import ResourcesEditor from '@cdo/apps/templates/courseOverview/ResourcesEditor';
import DropdownButton from '@cdo/apps/templates/DropdownButton';
import Button from '@cdo/apps/templates/Button';
import ResourceType, {
  resourceShape,
  stringForType
} from '@cdo/apps/templates/courseOverview/resourceType';
import {announcementShape} from '@cdo/apps/code-studio/scriptAnnouncementsRedux';
import VisibleAndPilotExperiment from './VisibleAndPilotExperiment';

const styles = {
  input: {
    width: '100%',
    boxSizing: 'border-box',
    padding: '4px 6px',
    color: '#555',
    border: '1px solid #ccc',
    borderRadius: 4
  },
  checkbox: {
    margin: '0 0 0 7px'
  },
  dropdown: {
    margin: '0 6px'
  }
};

const VIDEO_KEY_REGEX = /video_key_for_next_level/g;

const CURRICULUM_UMBRELLAS = ['CSF', 'CSD', 'CSP'];

/**
 * Component for editing course scripts.
 */
export default class ScriptEditor extends React.Component {
  static propTypes = {
    beta: PropTypes.bool,
    betaWarning: PropTypes.string,
    name: PropTypes.string.isRequired,
    i18nData: PropTypes.object.isRequired,
    hidden: PropTypes.bool,
    isStable: PropTypes.bool,
    loginRequired: PropTypes.bool,
    hideableLessons: PropTypes.bool,
    studentDetailProgressView: PropTypes.bool,
    professionalLearningCourse: PropTypes.string,
    peerReviewsRequired: PropTypes.number,
    wrapupVideo: PropTypes.string,
    projectWidgetVisible: PropTypes.bool,
    projectWidgetTypes: PropTypes.arrayOf(PropTypes.string),
    teacherResources: PropTypes.arrayOf(resourceShape).isRequired,
    lessonExtrasAvailable: PropTypes.bool,
    lessonLevelData: PropTypes.string,
    hasVerifiedResources: PropTypes.bool,
    hasLessonPlan: PropTypes.bool,
    curriculumPath: PropTypes.string,
    pilotExperiment: PropTypes.string,
    editorExperiment: PropTypes.string,
    announcements: PropTypes.arrayOf(announcementShape).isRequired,
    supportedLocales: PropTypes.arrayOf(PropTypes.string),
    locales: PropTypes.arrayOf(PropTypes.arrayOf(PropTypes.string)).isRequired,
    projectSharing: PropTypes.bool,
    curriculumUmbrella: PropTypes.oneOf(CURRICULUM_UMBRELLAS),
    familyName: PropTypes.string,
    versionYear: PropTypes.string,
    scriptFamilies: PropTypes.arrayOf(PropTypes.string).isRequired,
    versionYearOptions: PropTypes.arrayOf(PropTypes.string).isRequired,
    isLevelbuilder: PropTypes.bool,
    tts: PropTypes.bool
  };

  constructor(props) {
    super(props);

    this.state = {
      curriculumUmbrella: this.props.curriculumUmbrella
    };
  }

  handleClearProjectWidgetSelectClick = () => {
    $(this.projectWidgetSelect)
      .children('option')
      .removeAttr('selected', true);
  };

  handleClearSupportedLocalesSelectClick = () => {
    $(this.supportedLocaleSelect)
      .children('option')
      .removeAttr('selected', true);
  };

  handleUmbrellaSelectChange = event => {
    const curriculumUmbrella = event.target.value;
    this.setState({curriculumUmbrella});
  };

  presubmit = e => {
    const videoKeysBefore = (
      this.props.lessonLevelData.match(VIDEO_KEY_REGEX) || []
    ).length;
    const scriptText = this.props.beta ? '' : this.scriptTextArea.value;
    const videoKeysAfter = (scriptText.match(VIDEO_KEY_REGEX) || []).length;
    if (videoKeysBefore !== videoKeysAfter) {
      if (
        !confirm(
          'WARNING: adding or removing video keys will also affect ' +
            'uses of this level in other scripts. Are you sure you want to ' +
            'continue?'
        )
      ) {
        e.preventDefault();
      }
    }
  };

  render() {
    const {betaWarning} = this.props;
    const textAreaRows = this.props.lessonLevelData
      ? this.props.lessonLevelData.split('\n').length + 5
      : 10;
    return (
      <div>
        <h2>I18n Strings</h2>
        <label>
          Title
          <input
            name="title"
            defaultValue={this.props.i18nData.title}
            style={styles.input}
          />
        </label>
        <label>
          Audience
          <input
            name="description_audience"
            defaultValue={this.props.i18nData.descriptionAudience}
            style={styles.input}
          />
        </label>
        <label>
          Short Description
          <input
            name="description_short"
            defaultValue={this.props.i18nData.descriptionShort}
            style={styles.input}
          />
        </label>
        <label>
          Description
          <textarea
            name="description"
            defaultValue={this.props.i18nData.description}
            rows={5}
            style={styles.input}
          />
        </label>
        <LessonDescriptions
          scriptName={this.props.name}
          currentDescriptions={this.props.i18nData.stageDescriptions}
        />
        <ScriptAnnouncementsEditor
          defaultAnnouncements={this.props.announcements}
          inputStyle={styles.input}
        />
        <h2>Basic Settings</h2>

        {this.props.isLevelbuilder && (
          <div>
            <label>
              Is this script part of one of the core courses?
              <select
                name="curriculum_umbrella"
                style={styles.dropdown}
                defaultValue={this.props.curriculumUmbrella}
                onChange={this.handleUmbrellaSelectChange}
              >
                <option value="">(None)</option>
                {CURRICULUM_UMBRELLAS.map(curriculumUmbrella => (
                  <option key={curriculumUmbrella} value={curriculumUmbrella}>
                    {curriculumUmbrella}
                  </option>
                ))}
              </select>
              <p>
                By selecting one of the above, this script will have a property,
                curriculum_umbrella, specific to that course regardless of
                version.
              </p>
              <p>
                If you select CSF, CSF-specific elements will show in the
                progress tab of the teacher dashboard. For example, the progress
                legend will include a separate column for levels completed with
                too many blocks and there will be information about CSTA
                Standards.
              </p>
              <ProgressLegend
                excludeCsfColumn={this.state.curriculumUmbrella !== 'CSF'}
              />
            </label>
            <label>
              Family Name
              <select
                name="family_name"
                defaultValue={this.props.familyName}
                style={styles.dropdown}
              >
                <option value="">(None)</option>
                {this.props.scriptFamilies.map(familyOption => (
                  <option key={familyOption} value={familyOption}>
                    {familyOption}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Version Year
              <select
                name="version_year"
                defaultValue={this.props.versionYear}
                style={styles.dropdown}
              >
                <option value="">(None)</option>
                {this.props.versionYearOptions.map(year => (
                  <option key={year} value={year}>
                    {year}
                  </option>
                ))}
              </select>
            </label>
            <VisibleAndPilotExperiment
              visible={!this.props.hidden}
              pilotExperiment={this.props.pilotExperiment}
            />
            <label>
              Can be recommended (aka stable)
              <input
                name="is_stable"
                type="checkbox"
                defaultChecked={this.props.isStable}
                style={styles.checkbox}
              />
              <p>
                If checked, this unit will be eligible to be the recommended
                version of the unit. The most recent eligible version will be
                the recommended version.
              </p>
            </label>
          </div>
        )}
        <label>
          Display project sharing column in Teacher Dashboard
          <input
            name="project_sharing"
            type="checkbox"
            defaultChecked={this.props.projectSharing}
            style={styles.checkbox}
          />
          <p>
            If checked, the "Sharing" column in the "Manage Students" tab of
            Teacher Dashboard will be displayed by default for sections assigned
            to this script.
          </p>
        </label>
        <label>
          Login Required
          <input
            name="login_required"
            type="checkbox"
            defaultChecked={this.props.loginRequired}
            style={styles.checkbox}
          />
          <p>Require users to log in before viewing this script.</p>
        </label>
        <label>
          Hideable Lessons
          <input
            name="hideable_stages"
            type="checkbox"
            defaultChecked={this.props.hideableLessons}
            style={styles.checkbox}
          />
          <p>
            Allow teachers to toggle whether or not specific lessons in this
            script are visible to students in their section.
          </p>
        </label>
        <label>
          Default Progress to Detail View
          <input
            name="student_detail_progress_view"
            type="checkbox"
            defaultChecked={this.props.studentDetailProgressView}
            style={styles.checkbox}
          />
          <p>
            By default students start in the summary view. When this box is
            checked, we instead stick everyone into detail view to start for
            this script.
          </p>
        </label>
        <label>
          Lesson Extras Available
          <input
            name="stage_extras_available"
            type="checkbox"
            defaultChecked={this.props.lessonExtrasAvailable}
            style={styles.checkbox}
          />
          <p>
            If also enabled by the teacher, show the lesson extras page at the
            end of each lesson.
          </p>
        </label>
        <label>
          Verified Resources
          <input
            name="has_verified_resources"
            type="checkbox"
            defaultChecked={this.props.hasVerifiedResources}
            style={styles.checkbox}
          />
          <p>
            Check if this course has resources for verified teachers, and we
            want to notify non-verified teachers that this is the case.
          </p>
        </label>
        <label>
          Lesson Plan
          <input
            name="has_lesson_plan"
            type="checkbox"
            defaultChecked={this.props.hasLessonPlan}
            style={styles.checkbox}
          />
          <p>
            Check if this course has lesson plans (on Curriculum Builder or in
            PDF form) that we should provide links to.
          </p>
        </label>
        <label>
          Text-to-Speech
          <input
            name="tts"
            type="checkbox"
            defaultChecked={this.props.tts}
            style={styles.checkbox}
          />
          <p>Check to enable text-to-speech for this course.</p>
        </label>
        {this.props.isLevelbuilder && (
          <label>
            Editor Experiment. If specified, users with this experiment on the
            levelbuilder machine will be able to edit this script.
            <input
              name="editor_experiment"
              defaultValue={this.props.editorExperiment}
              style={styles.input}
            />
          </label>
        )}
        <label>
          Curriculum Path
          <input
            name="curriculum_path"
            defaultValue={this.props.curriculumPath}
            style={styles.input}
          />
        </label>
        {this.props.isLevelbuilder && (
          <label>
            Professional Learning Course. When filled out, the course unit
            associated with this script will be associated with the course named
            in this box. If the course unit does not exist, and if the course
            does not exist it will be created.
            <input
              name="professional_learning_course"
              defaultValue={this.props.professionalLearningCourse}
              style={styles.input}
            />
          </label>
        )}
        <label>
          Peer Reviews to Complete. Currently only supported for professional
          learning courses
          <input
            name="peer_reviews_to_complete"
            defaultValue={this.props.peerReviewsRequired}
            style={styles.input}
          />
        </label>
        <label>
          Wrap-up Video
          <input
            name="wrapup_video"
            defaultValue={this.props.wrapupVideo}
            style={styles.input}
          />
        </label>

        <h3>Project widget options</h3>
        <label>
          Project widget visible
          <input
            name="project_widget_visible"
            type="checkbox"
            defaultChecked={this.props.projectWidgetVisible}
            style={styles.checkbox}
          />
          <p>
            If checked this script will have the projects widget (recent
            projects and new project buttons) visible in lesson extras.
          </p>
        </label>
        <label>
          Project widget new project types
          <p>
            Select up to 4 project type options to appear in the 'Start a new
            project' section. Select
            <a onClick={this.handleClearProjectWidgetSelectClick}> none </a>
            or shift-click or cmd-click to select multiple.
          </p>
          <select
            name="project_widget_types[]"
            multiple
            defaultValue={this.props.projectWidgetTypes}
            ref={select => (this.projectWidgetSelect = select)}
          >
            <option value="playlab">Play Lab</option>
            <option value="playlab_k1">Play Lab K1</option>
            <option value="artist">Artist</option>
            <option value="artist_k1">Artist K1</option>
            <option value="applab">App Lab</option>
            <option value="gamelab">Game Lab</option>
            <option value="weblab">Web Lab</option>
            <option value="calc">Calc</option>
            <option value="eval">Eval</option>
            <option value="frozen">Frozen</option>
            <option value="minecraft_adventurer">Minecraft Adventurer</option>
            <option value="minecraft_designer">Minecraft Designer</option>
            <option value="minecraft_hero">Minecraft Hero</option>
            <option value="starwars">Star Wars</option>
            <option value="starwarsblocks">Star Wars Blocks</option>
            <option value="flappy">Flappy</option>
            <option value="sports">Sports</option>
            <option value="basketball">Basketball</option>
            <option value="bounce">Bounce</option>
            <option value="infinity">Infinity</option>
            <option value="iceage">Ice Age</option>
            <option value="gumball">Gumball</option>
          </select>
        </label>

        <label>
          Supported locales
          <p>
            Select additional locales supported by this script. Select
            <a onClick={this.handleClearSupportedLocalesSelectClick}> none </a>
            or shift-click or cmd-click to select multiple.
          </p>
          <select
            name="supported_locales[]"
            multiple
            defaultValue={this.props.supportedLocales}
            ref={select => (this.supportedLocaleSelect = select)}
          >
            {this.props.locales
              .filter(locale => !locale[1].startsWith('en'))
              .map(locale => (
                <option key={locale[1]} value={locale[1]}>
                  {locale[1]}
                </option>
              ))}
          </select>
        </label>

        <div>
          <h4>Teacher Resources</h4>
          <div>
            Select the Teacher Resources buttons you'd like to have show up on
            the top of the course overview page
          </div>
          <ResourcesEditor
            inputStyle={styles.input}
            resources={this.props.teacherResources}
            maxResources={Object.keys(ResourceType).length}
            renderPreview={resources => (
              <DropdownButton
                text="Teacher resources"
                color={Button.ButtonColor.blue}
              >
                {resources.map(({type, link}, index) => (
                  <a key={index} href={link}>
                    {stringForType[type]}
                  </a>
                ))}
              </DropdownButton>
            )}
          />
        </div>
        <h2>Lessons and Levels</h2>
        {this.props.beta ? (
          <LessonGroup />
        ) : (
          <div>
            {betaWarning || (
              <a href="?beta=true">
                Try the beta Script Editor (will reload the page without saving)
              </a>
            )}
            <textarea
              id="script_text"
              name="script_text"
              rows={textAreaRows}
              style={styles.input}
              defaultValue={
                this.props.lessonLevelData ||
                "lesson_group 'lesson group', display_name: 'display name'\nstage 'new lesson'\n"
              }
              ref={textArea => (this.scriptTextArea = textArea)}
            />
          </div>
        )}
        <button
          className="btn btn-primary"
          type="submit"
          style={{margin: 0}}
          onClick={this.presubmit}
        >
          Save Changes
        </button>
      </div>
    );
  }
}
