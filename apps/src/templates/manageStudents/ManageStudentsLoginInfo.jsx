import PropTypes from 'prop-types';
import React, {Component} from 'react';
import {SectionLoginType} from '@cdo/apps/util/sharedConstants';
import i18n from '@cdo/locale';
import color from '@cdo/apps/util/color';
import {teacherDashboardUrl} from '@cdo/apps/templates/teacherDashboard/urlHelpers';
import {pegasus} from '@cdo/apps/lib/util/urlHelpers';
import SafeMarkdown from '@cdo/apps/templates/SafeMarkdown';
import {ParentLetterButtonMetricsCategory} from '@cdo/apps/templates/manageStudents/manageStudentsRedux';
import DownloadParentLetter from './DownloadParentLetter';

const styles = {
  explanation: {
    clear: 'both',
    paddingTop: 20
  },
  heading: {
    color: color.purple
  },
  listAlign: {
    marginLeft: 10
  },
  sublistAlign: {
    marginLeft: 20
  }
};

class ManageStudentsLoginInfo extends Component {
  static propTypes = {
    sectionId: PropTypes.number,
    sectionCode: PropTypes.string,
    loginType: PropTypes.string,
    // The prefix for the code studio url in the current environment,
    // e.g. 'https://studio.code.org' or 'http://localhost-studio.code.org:3000'.
    studioUrlPrefix: PropTypes.string
  };

  render() {
    const {loginType, sectionId, sectionCode, studioUrlPrefix} = this.props;

    return (
      <div style={styles.explanation}>
        <h2 style={styles.heading}>{i18n.setUpClass()}</h2>
        {loginType === SectionLoginType.word && (
          <div>
            <p>{i18n.setUpClassWordIntro()}</p>
            <p style={styles.listAlign}>{i18n.setUpClassWordPic1()}</p>
            <SafeMarkdown
              markdown={i18n.setUpClassWord2({
                printLoginCardLink: teacherDashboardUrl(
                  sectionId,
                  '/login_info'
                )
              })}
            />
            <SafeMarkdown
              markdown={i18n.setUpClass3({
                parentLetterLink: teacherDashboardUrl(
                  sectionId,
                  '/parent_letter'
                )
              })}
            />
            <p style={styles.listAlign}>{i18n.setUpClass4()}</p>
            <h2 style={styles.heading}>{i18n.signingInWord()}</h2>
            <p>{i18n.signingInWordIntro()}</p>
            <SafeMarkdown
              markdown={i18n.signingInWordPic1({
                joinLink: `${studioUrlPrefix}/join/${sectionCode}`,
                sectionCode: sectionCode,
                codeOrgLink: pegasus('/')
              })}
            />
            <p style={styles.listAlign}>{i18n.signingInWordPic2()}</p>
            <p style={styles.listAlign}>{i18n.signingInWord3()}</p>
          </div>
        )}
        {loginType === SectionLoginType.picture && (
          <div>
            <p>{i18n.setUpClassPicIntro()}</p>
            <p style={styles.listAlign}>{i18n.setUpClassWordPic1()}</p>
            <SafeMarkdown
              markdown={i18n.setUpClassPic2({
                printLoginCardLink: teacherDashboardUrl(
                  sectionId,
                  '/login_info'
                )
              })}
            />
            <SafeMarkdown
              markdown={i18n.setUpClass3({
                parentLetterLink: teacherDashboardUrl(
                  sectionId,
                  '/parent_letter'
                )
              })}
            />
            <p style={styles.listAlign}>{i18n.setUpClass4()}</p>
            <h2 style={styles.heading}>{i18n.signingInPic()}</h2>
            <p>{i18n.signingInPicIntro()}</p>
            <SafeMarkdown
              markdown={i18n.signingInWordPic1({
                joinLink: `${studioUrlPrefix}/join/${sectionCode}`,
                sectionCode: sectionCode,
                codeOrgLink: pegasus('/')
              })}
            />
            <p style={styles.listAlign}>{i18n.signingInWordPic2()}</p>
            <p style={styles.listAlign}>{i18n.signingInPic3()}</p>
          </div>
        )}
        {loginType === SectionLoginType.email && (
          <div>
            <p>{i18n.setUpClassEmailIntro()}</p>
            <SafeMarkdown
              markdown={i18n.setUpClassEmail1({
                createAccountLink: `${studioUrlPrefix}/users/sign_up`
              })}
            />
            <SafeMarkdown
              markdown={i18n.setUpClassEmail2({
                joinLink: `${studioUrlPrefix}/join/${sectionCode}`
              })}
            />
            <SafeMarkdown
              markdown={i18n.setUpClass3({
                parentLetterLink: teacherDashboardUrl(
                  sectionId,
                  '/parent_letter'
                )
              })}
            />
            <p style={styles.listAlign}>{i18n.setUpClass4()}</p>
            <h2 style={styles.heading}>{i18n.signingInEmail()}</h2>
            <p>{i18n.signingInEmailIntro()}</p>
            <SafeMarkdown
              markdown={i18n.signingInEmailGoogle1({
                codeOrgLink: pegasus('/')
              })}
            />
            <p style={styles.listAlign}>{i18n.signingInEmail2()}</p>
          </div>
        )}
        {loginType === SectionLoginType.google_classroom && (
          <div>
            <p>{i18n.setUpClassGoogleIntro()}</p>
            <p style={styles.listAlign}>{i18n.setUpClassGoogle1()}</p>
            <p style={styles.listAlign}>{i18n.setUpClassGoogle2()}</p>
            <p>{i18n.setUpClassGoogleFinished()}</p>
            <h2 style={styles.heading}>{i18n.signingInGoogle()}</h2>
            <p>{i18n.signingInGoogleIntro()}</p>
            <SafeMarkdown
              markdown={i18n.signingInEmailGoogle1({
                codeOrgLink: pegasus('/')
              })}
            />
            <p style={styles.listAlign}>{i18n.signingInGoogle2()}</p>
            <p style={styles.listAlign}>{i18n.signingInGoogle3()}</p>
          </div>
        )}
        {loginType === SectionLoginType.clever && (
          <div>
            <p>{i18n.setUpClassCleverIntro()}</p>
            <p style={styles.listAlign}>{i18n.setUpClassClever1()}</p>
            <p style={styles.listAlign}>{i18n.setUpClassClever2()}</p>
            <p>{i18n.setUpClassCleverFinished()}</p>
            <h2 style={styles.heading}>{i18n.signingInClever()}</h2>
            <p>{i18n.signingInCleverIntro()}</p>
            <p style={styles.listAlign}>{i18n.signingInClever1()}</p>
            <div style={styles.sublistAlign}>
              <SafeMarkdown markdown={i18n.signingInClever1a()} />
            </div>
            <p style={styles.sublistAlign}>{i18n.signingInClever1b()}</p>
            <img
              style={styles.sublistAlign}
              src="/shared/images/clever_code_org_logo.png"
            />
          </div>
        )}

        <h2 style={styles.heading}>{i18n.privacyHeading()}</h2>
        <p id="uitest-privacy-text">{i18n.privacyDocExplanation()}</p>
        <DownloadParentLetter
          sectionId={this.props.sectionId}
          buttonMetricsCategory={ParentLetterButtonMetricsCategory.BELOW_TABLE}
        />
        <br />
        <span id="uitest-privacy-link">
          <SafeMarkdown
            markdown={i18n.privacyLinkToPolicy({
              privacyPolicyLink: pegasus('/privacy/student-privacy')
            })}
          />
        </span>
      </div>
    );
  }
}

export default ManageStudentsLoginInfo;
