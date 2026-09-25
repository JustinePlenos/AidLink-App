const fs = require('fs');
const path = require('path');
const vm = require('vm');
const layout = fs.readFileSync(path.join(__dirname, '../ux-testing/build_reports.cjs'), 'utf8')
  .replace(/^writeDoc\('AidLink_LINGAP_Week[12].*$/gm, '')
  .replace('APP + WEB UX TESTING', 'CAPSTONE CHECKING')
  .replace('Testing workbook • Record actual evidence', 'AidLink / LINGAP • Objectives and user requirements');
const content = String.raw`
const samplePages = [];
function identity() {
  return p('AidLink / LINGAP Applicant App and Web Administration System', 'Label')+
    p('Proponents: __________________________________________________________________')+
    p('Project stage: __________________________  Date: ________________________________');
}
samplePages.push(page('PROJECT OBJECTIVES', '', identity()+
  note('Working title and proposed objectives: replace with the exact approved proposal wording where available.')+
  h('General objective')+
  p('The general objective of AidLink is to provide an integrated mobile and web system for LINGAP assistance processing that allows applicants to submit and monitor requests and enables authorized personnel to review supporting information, record decisions and communicate request outcomes.')+
  h('Specific objectives')+
  h('OBJ-01. Applicant registration and assistance submission')+
  p('Provide a mobile application through which applicants can register, sign in, enter patient information, select an assistance type, attach the required supporting documents, review their information and submit an assistance request.')+
  h('OBJ-02. Request review and decision management')+
  p('Provide authorized LINGAP personnel with a web workspace for locating requests, reviewing applicant and patient details and supporting documents, and recording review, approval or denial decisions with remarks and a decision history.')+
  h('OBJ-03. Applicant tracking and approval information')+
  p('Enable applicants to monitor their request status, receive request-related notifications, and access the guarantee letter, QR verification information and assigned-facility details associated with an approved request.')+
  h('OBJ-04. Facility and document-requirement management')+
  p('Enable authorized personnel to maintain facility records and required-document lists by assistance type, assign eligible facilities to requests and make the corresponding information available to applicants.')+
  h('OBJ-05. Controlled access and usable system interaction')+
  p('Provide role-appropriate access and account-specific applicant information, with understandable validation and status feedback, accessible controls, responsive layouts and clear recovery from connection problems. Evaluate these behaviors through functional and usability testing.')
));
const choices = '☐ Verified\n☐ Needs Revision\n☐ Not Yet Tested\n☐ Not Applicable';
function reqTable(rows) {
  return table(['ID','User requirement','Verification status','Remarks'], rows.map(([id,text])=>[id,text,choices,'']), [1550,4440,2260,1816], 1130);
}
const statusGuide = note('Choose one status per requirement. Verified = successfully demonstrated; Needs Revision = missing, incorrect or partly working; Not Yet Tested = no completed check; Not Applicable = outside the approved scope, with a reason in Remarks.');
const shared = [
 ['UR-01','The user shall be able to sign in with valid credentials and sign out. Signing out shall end access to the private session.'],
 ['UR-02','The system shall permit access to functions according to the user’s authorized role. Applicants shall not be able to make staff decisions.'],
 ['UR-03','The system shall restrict applicants to their own request records, notifications and protected request information.'],
 ['UR-04','The system shall provide clear navigation and understandable assistance descriptions, labels and request statuses for each user role.'],
 ['UR-05','The system shall provide understandable validation, error, loading, empty-state and confirmation messages where applicable.'],
 ['UR-06','The interface shall remain usable on supported phone and desktop screens, with enlarged text and 200% browser zoom where applicable.'],
 ['UR-07','Web controls shall support keyboard operation with visible focus; important app controls and feedback shall have meaningful screen-reader labels.'],
 ['UR-08','The app shall explain a lost connection and allow recovery after reconnecting, without falsely reporting that a request was submitted.']
];
const applicant = [
 ['UR-APP-01','The applicant shall be able to register an account using the required personal and contact details.'],
 ['UR-APP-02','The applicant shall be able to enter patient details and the relationship to the patient. The form shall reject missing required fields and invalid birthdates.'],
 ['UR-APP-03','The applicant shall be able to select an assistance type and view its applicable document requirements.'],
 ['UR-APP-04','The applicant shall be able to select and replace supporting documents before submission, with clear feedback for unsupported or oversized files.'],
 ['UR-APP-05','The applicant shall be able to review entered information, selected documents and consent before submitting the request.'],
 ['UR-APP-06','The applicant shall receive a request reference and confirmation for a successful submission. The corresponding request shall be available to authorized staff.'],
 ['UR-APP-07','The applicant shall be able to view, search and filter their request history and open the intended request details.'],
 ['UR-APP-08','The applicant shall be able to see the current Pending, Under Review, Approved or Denied status after refreshing the matching request.'],
 ['UR-APP-09','The applicant shall be able to view notifications for their requests, open the related request and distinguish read from unread alerts.'],
 ['UR-APP-10','The applicant shall be able to open the correct guarantee letter and view the QR code or verification ID for an approved request.'],
 ['UR-APP-11','The applicant shall be able to view the assigned facility and available address/contact details. If no facility is assigned, the app shall explain that state.'],
 ['UR-APP-12','When starting a new request, the applicant shall see the document requirements currently configured by authorized staff for the selected assistance type.']
];
const staff = [
 ['UR-STF-01','Authorized staff shall be able to view an overview of assistance-request activity and processing statuses.'],
 ['UR-STF-02','Authorized staff shall be able to locate a request using its reference, search or filters and inspect its applicant/patient information and supporting documents.'],
 ['UR-STF-03','Authorized processing staff shall be able to mark a request Under Review with required remarks.'],
 ['UR-STF-04','Authorized processing staff shall be able to approve a request with required remarks and a valid guarantee-letter file. Approval shall be prevented when these are missing.'],
 ['UR-STF-05','Authorized processing staff shall be able to deny a request with required remarks. The decision shall be saved against the correct request.'],
 ['UR-STF-06','Authorized staff shall be able to review the request’s decision history, including recorded remarks, the person who acted and the action date/time.'],
 ['UR-STF-07','Authorized staff shall be able to view requestor profiles and the requests belonging to the selected requestor.'],
 ['UR-STF-08','Authorized staff shall be able to create and update facility records, including available contact/location information and supported assistance types.'],
 ['UR-STF-09','Authorized staff shall be able to activate/deactivate facilities and assign an eligible active facility to a request. The app shall show the saved assignment.'],
 ['UR-STF-10','Authorized staff shall be able to edit required-document lists for each assistance type. The saved list shall appear in a newly started applicant request.'],
 ['UR-STF-11','Saved review, approval and denial decisions shall appear on the corresponding applicant request after refresh, together with relevant request notifications.']
];
samplePages.push(page('USER REQUIREMENTS CHECKLIST', '', identity()+
  p('System: AidLink mobile applicant app and LINGAP web administration system')+
  h('Purpose')+
  p('This checklist presents AidLink/LINGAP user requirements for capstone review and testing. It covers shared system behavior, applicant tasks and authorized staff workflows. Each requirement is an expected behavior to demonstrate; inclusion does not mean the feature is complete or verified.')+
  statusGuide+
  note('In Remarks, record the test date/build, evidence reference and any problem. Retest requirements marked Needs Revision after correction. Leave the choices unmarked until the result or scope decision is recorded.')+
  h('A. Shared requirements for all applicable users')+
  reqTable(shared.slice(0,4))+
  note('Use two test applicant accounts to verify account-specific access. Use a staff account for web-only actions.')
));
samplePages.push(page('USER REQUIREMENTS CHECKLIST', 'A. Shared requirements for all applicable users — continued',
  reqTable(shared.slice(4))+
  h('Verification notes')+
  p('Use fictional records and a test environment for decisions and submissions. Confirm each part of a combined requirement before marking it Verified. A feature that works only partly should be marked Needs Revision and explained in Remarks.')+
  p('For keyboard checks, try navigation and closing request dialogs without a mouse. For screen-reader checks, use the phone’s screen reader rather than judging the screen visually.')+
  p('For connection recovery, confirm the message during disconnection, then reconnect and refresh. If submitting a test request, check the web record before reporting success.')+
  note('Reviewer: __________________________  Date / build: __________________________')
));
samplePages.push(page('USER REQUIREMENTS CHECKLIST', 'B. Applicant / Requestor — mobile app',
  p('The applicant app provides Home, Requests, Facilities, Alerts and Account areas. The new-request workflow includes patient information, assistance selection, document attachment and a review step.')+
  reqTable(applicant.slice(0,6))+
  note('Related objectives: OBJ-01 and OBJ-05. For birthdate validation, repeat the exact invalid date reported in your Week 1 audit and record the current result.')
));
samplePages.push(page('USER REQUIREMENTS CHECKLIST', 'B. Applicant / Requestor — continued',
  reqTable(applicant.slice(6))+
  note('Related objectives: OBJ-03, OBJ-04 and OBJ-05.')+
  note('To test notifications, save a known status change for this applicant on the web, then refresh Alerts. “No notifications yet” by itself does not demonstrate a defect. Test the expected update before selecting a status.')
));
samplePages.push(page('USER REQUIREMENTS CHECKLIST', 'C. Authorized LINGAP staff — web system',
  p('The staff website provides Overview, Assistance requests, Requestors, Facilities and account information. Request decisions and maintenance actions require an authorized processing or administrator role.')+
  reqTable(staff.slice(0,6))+
  note('Related objectives: OBJ-02 and OBJ-05. Use separate sample requests for approval and denial. Prepare a valid sample guarantee letter for the approval case.')
));
samplePages.push(page('USER REQUIREMENTS CHECKLIST', 'C. Authorized LINGAP staff — continued',
  reqTable(staff.slice(6))+
  note('Related objectives: OBJ-02, OBJ-03 and OBJ-04. Restore any training facility or document-list changes after testing.')+
  h('Review record')+
  p('Reviewed by: __________________________  Date: ______________________________')+
  p('App build: ____________________________  Website version: _____________________')+
  p('Follow-up items / evidence references: __________________________________________')+
  note('Format adapted from the supplied project-objectives-and-user-checklist.pdf. The objectives and requirements here describe AidLink/LINGAP; project title, proponents, project stage and verification results must be completed by your group.')
));
writeDoc('AidLink_LINGAP_Objectives_and_User_Checklist_Sample_Format.docx', samplePages, 'PROJECT CHECKING');
`;
vm.runInNewContext(layout+content,{require,__dirname,console,Buffer},{filename:'sample_format_generator.cjs'});
