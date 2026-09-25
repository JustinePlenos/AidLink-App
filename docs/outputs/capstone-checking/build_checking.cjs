const fs = require('fs');
const path = require('path');
const vm = require('vm');
// Reuse the existing local Word layout without regenerating the Week 1/2 files.
const layout = fs.readFileSync(path.join(__dirname, '../ux-testing/build_reports.cjs'), 'utf8')
  .replace(/^writeDoc\('AidLink_LINGAP_Week[12].*$/gm, '')
  .replace('APP + WEB UX TESTING', 'CAPSTONE CHECKING')
  .replace('Testing workbook • Record actual evidence', 'Capstone checking • Record actual results');
const content = String.raw`
const checkingPages = [];
checkingPages.push(page('CAPSTONE OBJECTIVES', 'AidLink / LINGAP applicant app and web administration system',
  table(['Presentation details', 'Complete before checking'], [
    ['Approved capstone title', '________________________________________________________\nWorking label: AidLink / LINGAP App and Web System'],
    ['Group / members; Section', '________________________________________________________'],
    ['Instructor; Checking date', '________________________________________________________'],
    ['App build; Website version', '________________________________________________________']
  ], [2900,7166])+
  note('Draft for review: these objectives are based on the project workflows. If your proposal already has approved objectives, use that wording and align this checklist with it.')+
  h('General objective')+
  p('To develop and evaluate AidLink, an integrated mobile and web system that enables applicants to submit and monitor LINGAP assistance requests and enables authorized staff to review applications, record decisions and manage supporting information.')+
  h('Specific objectives')+
  p('O1. To provide applicants with account registration and sign-in, patient-information forms, assistance selection and supporting-document submission through a mobile app.')+
  p('O2. To enable applicants to track request status, view request notifications, and access guarantee letters, QR verification information and assigned-facility details for approved requests.')+
  p('O3. To provide authorized staff with a web interface for locating and reviewing requests, inspecting supporting documents, and recording review, approval or denial decisions with remarks and a decision history.')+
  p('O4. To enable authorized staff to manage facility information and required-document lists, and to keep applicant-facing request information consistent with web records.')+
  p('O5. To evaluate the system through functional and usability checks covering input validation, account-specific access, accessibility, responsive layouts and recovery from connection problems.')+
  note('These statements describe intended outcomes. They do not claim that every feature is complete or has passed testing.')
));
const legend = note('Status: ✓ = demonstrated and met; Partial = partly met; ✗ = not met; NT = not tested. Record the actual build, test case and screenshot/reference in Evidence. A blank cell is not a pass.');
function requirementTable(rows) { return table(['ID / objective','User requirement and completion check','Status','Evidence / remarks'], rows.map(r=>[r[0],r[1],'','']),[1400,5100,950,2616],850); }
checkingPages.push(page('USER REQUIREMENTS CHECKLIST', 'Applicant requirements — demonstrate using a fictional test account',legend+
  requirementTable([
    ['UR01 / O1','Applicants can create an account with valid details; missing or invalid registration information receives clear feedback.'],
    ['UR02 / O1','Applicants can sign in with valid credentials and sign out. Wrong credentials show a useful error, and signed-out users cannot access the previous private session.'],
    ['UR03 / O1','Applicants can enter patient information and their relationship to the patient. Required fields and invalid birthdates are checked before continuing.'],
    ['UR04 / O1','Applicants can choose an assistance type and understand its description and required-document list.'],
    ['UR05 / O1','Applicants can select and replace documents before submission. Unsupported or oversized files receive understandable feedback.'],
    ['UR06 / O1','Applicants can review their details and consent before submission. One submitted request receives a reference and appears in the staff system.'],
    ['UR07 / O2','Applicants can find their own requests, search/filter their history, and see the current status after refreshing.'],
    ['UR08 / O2','Applicants can receive request-related notifications, open the matching request and distinguish read from unread alerts.'],
    ['UR09 / O2','For an approved request, applicants can open the correct guarantee letter and view its QR code or verification ID.'],
    ['UR10 / O2','Applicants can view the assigned facility and its available address/contact details. An unassigned request is clearly explained.']
  ])+
  note('Notification check: change this applicant’s request status on the web, refresh Alerts and inspect the result. An empty Notifications screen alone does not establish whether notifications work.')
));
checkingPages.push(page('USER REQUIREMENTS CHECKLIST', 'Staff and integration requirements — use separate approval and denial cases',legend+
  requirementTable([
    ['UR11 / O3','Authorized staff can sign in to the website and sign out; request-decision controls are restricted to authorized staff roles.'],
    ['UR12 / O3','Staff can locate the intended request using its reference/search or filters and inspect applicant/patient details and supporting documents.'],
    ['UR13 / O3','Staff can mark a request Under Review with remarks; the saved status appears on the matching applicant request after refresh.'],
    ['UR14 / O3','Staff can approve a request with required remarks and a valid guarantee letter. Missing remarks or a missing letter prevents approval.'],
    ['UR15 / O3','Staff can deny a separate test request with remarks; the decision is saved and its status appears in the app.'],
    ['UR16 / O3','Staff can inspect the decision history, including status changes, remarks, who acted and when.'],
    ['UR17 / O4','Staff can add/edit a training facility, change its active status and assign an eligible active facility to a request. The app shows the same assignment.'],
    ['UR18 / O4','Staff can change required documents for an assistance type. A newly started app request of that type shows the updated list.'],
    ['UR19 / O3','Staff can view requestor profiles and the requests associated with the selected requestor.']
  ])+
  note('Use a training facility and sample guarantee letter. Restore changed test requirements after the demonstration. Approval and denial should be tested on separate requests.')
));
checkingPages.push(page('USER REQUIREMENTS CHECKLIST', 'Shared quality requirements and demonstration preparation',legend+
  requirementTable([
    ['UR20 / O5','Each applicant sees only their own requests and notifications. Confirm with two different test accounts and existing records.'],
    ['UR21 / O5','Users can understand labels, instructions, statuses and errors. Important errors explain a useful next action.'],
    ['UR22 / O5','Users can read and reach controls at larger phone text sizes, different web widths and 200% browser zoom.'],
    ['UR23 / O5','Keyboard users can navigate web controls and dialogs with visible focus. A phone screen reader announces app navigation, labels and feedback.'],
    ['UR24 / O5','Connection loss produces clear feedback. Reconnecting and refreshing restore operation without falsely reporting a successful submission.']
  ])+
  h('Prepare for the demonstration')+
  p('Bring the running app and website, a reachable test server, two fictional applicant accounts, an authorized staff account, sample patient details and requirements, a sample guarantee letter and an active training facility.')+
  p('Demonstrate: sign in → submit an app request → locate it on the web → review and approve with a sample letter → refresh the app → show status, letter, verification information and facility. Use a separate case for denial and check its notification.')+
  h('Carry forward the audit observations')+
  p('Birthdate validation was reported as an issue in the Week 1 audit. Repeat the exact invalid-date case and record the current result under UR03. For notifications, test a known request update before deciding whether UR08 is met. Required-document synchronization still needs a direct check under UR18.')+
  p('Evaluator: __________________________  Date: __________________________')+
  note('This draft is not a statement of instructor approval or stakeholder sign-off. Keep the final checklist consistent with the approved capstone scope.')
));
writeDoc('AidLink_LINGAP_Objectives_User_Requirements_Checklist.docx', checkingPages, 'OBJECTIVES & REQUIREMENTS');
`;
vm.runInNewContext(layout + content, {require, __dirname, console, Buffer}, {filename:'capstone_checking_generator.cjs'});
