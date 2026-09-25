const fs = require('fs');
const path = require('path');
const vm = require('vm');
const extracted = JSON.parse(fs.readFileSync(path.join(__dirname,'manuscript-extracted.json'),'utf8'));
const objectivePages = extracted.filter(p=>p.page===12||p.page===13).map(p=>p.text).join('\n');
const general = 'To design and develop AidLink, a secure centralized assistance management system for transparent social assistance services for the Lingap Para sa Mahirap program of Davao City.';
const objectives = [
 'To design and develop a digital application interface that enables applicants to submit assistance requests and upload required documents.',
 'To develop a web-based administrative portal for authorized personnel to review, verify, and process submitted applications.',
 'To implement server-side rule-based business logic and API controls that manage request status transitions and maintain administrative audit records.',
 'To evaluate system performance, user acceptance, and administrative usability while documenting a deployment roadmap for planned PostgreSQL integration, IPFS document storage, and dynamic QR voucher verification.'
];
for(const text of [general,...objectives]) if(!objectivePages.includes(text)) throw new Error('Objective differs from supplied manuscript: '+text);
let layout = fs.readFileSync(path.join(__dirname,'../ux-testing/build_reports.cjs'),'utf8')
 .replace(/^writeDoc\('AidLink_LINGAP_Week[12].*$/gm,'')
 .replace('APP + WEB UX TESTING','CAPSTONE CHECKING')
 .replace('Testing workbook • Record actual evidence','AidLink • Objectives and user requirements');
const data = {
 title:'AidLink: A Centralized Digital Assistance Management System for Davao City',
 general, objectives,
 proponents:'Micko Jay Niño P. Llanos; Allyson M. Manulat; Justine M. Pleños',
 shared:[
  ['UR-01','The user shall be able to authenticate using valid account credentials and sign out of the private session.','FR-1'],
  ['UR-02','The system shall restrict each user to authorized functions and records. Applicant accounts shall not have administrative decision privileges.','§4.2.2'],
  ['UR-03','Applicants shall see only their own assistance records and protected information; authorized personnel shall see records within their permitted scope.','§4.2.2'],
  ['UR-04','Users shall receive clear navigation and understandable validation, error, loading, empty-state and confirmation feedback.','FR-2; §4.2.2'],
  ['UR-05','Users shall be able to read information and reach essential actions on supported phone and desktop screens.','§4.2.2'],
  ['UR-06','Users shall be informed when a connection problem prevents an action and shall be able to recover after reconnecting without a false success message.','§1.4.2']
 ],
 applicant:[
  ['UR-APP-01','The applicant shall be able to register an account using the personal, identification and authentication information required by the approved workflow.','FR-1'],
  ['UR-APP-02','The applicant shall be able to enter patient and case information. Required fields and invalid dates shall be checked before continuing.','FR-2'],
  ['UR-APP-03','The applicant shall be able to select an assistance type and identify the documents required for that request.','FR-2; FR-3'],
  ['UR-APP-04','The applicant shall be able to upload required document copies or images and receive useful feedback when a selected file fails validation.','FR-3'],
  ['UR-APP-05','The applicant shall be able to read and agree to the data-privacy consent declaration before submitting entered information and selected documents.','UC-03'],
  ['UR-APP-06','A successful submission shall save the request for staff review and provide the applicant with confirmation and a reference for follow-up.','FR-2; UC-03'],
  ['UR-APP-07','The applicant shall be able to open their request and view its current processing status and official evaluator remarks.','FR-4'],
  ['UR-APP-08','The applicant shall be able to view an approved request’s guarantee letter or eligibility output and download or print it through the supported workflow.','FR-10']
 ],
 evaluator:[
  ['UR-EVL-01','Authorized evaluators shall be able to view an intake dashboard with incoming requests, summary information and filterable processing queues.','FR-5'],
  ['UR-EVL-02','The evaluator shall be able to locate a specific application and inspect the applicant/patient details and uploaded requirements together.','FR-6'],
  ['UR-EVL-03','The evaluator shall be able to review documents manually and assess compliance with the assistance requirements.','FR-6; §1.4.2'],
  ['UR-EVL-04','Authorized evaluators shall be able to record review, approval or rejection decisions with compulsory remarks.','FR-7'],
  ['UR-EVL-05','The system shall enforce permitted status transitions through server-side controls and prevent unauthorized decision changes.','OBJ-03; FR-7'],
  ['UR-EVL-06','Saved decisions and evaluator remarks shall be available on the corresponding applicant request after an update or refresh.','FR-4; FR-7'],
  ['UR-EVL-07','Authorized personnel shall be able to inspect timestamped decision records identifying the action, responsible user and associated request.','FR-9']
 ],
 intake:[
  ['UR-INT-01','The intake officer shall be able to monitor the incoming application queue and identify records needing initial review.','§4.1; FR-5'],
  ['UR-INT-02','The intake officer shall be able to retrieve baseline applicant information and inspect submitted files for data verification within assigned permissions.','§4.1; FR-6'],
  ['UR-INT-03','Authorized intake personnel shall be able to assist with manual back-scanning or digitizing records through the supported intake workflow.','§4.1']
 ],
 admin:[
  ['UR-ADM-01','The system administrator shall be able to maintain authorized user roles and system settings through the supported administration workflow.','§4.1'],
  ['UR-ADM-02','The system administrator shall be able to review administrative actions, status changes and user-access audit events within authorized scope.','FR-9'],
  ['UR-ADM-03','The system administrator shall be able to obtain the analytical reports needed for administrative monitoring through the documented reporting workflow.','§4.1; §3.2']
 ],
 advanced:[
  ['UR-ADV-01','The system shall automatically detect duplicate assistance claims across active and historical records using beneficiary identifiers.','FR-8'],
  ['UR-ADV-02','The system shall automatically generate a downloadable or printable guarantee letter or eligibility form for an approved application.','FR-10'],
  ['UR-ADV-03','The system shall deliver automated SMS/email notifications to the intended applicant when a relevant status update or required action occurs.','FR-11'],
  ['UR-ADV-04','Authorized staff shall be able to record grant calculations as part of the decision workflow described in the manuscript.','FR-7']
 ],
 planned:[
  ['UR-PAR-01','For the planned module, the system shall generate a unique dynamic QR voucher for an approved assistance claim.','FR-12'],
  ['UR-PAR-02','An authorized partner shall be able to scan the voucher and inspect the associated claim’s validity through the planned verification workflow.','FR-12'],
  ['UR-PAR-03','A partner shall be able to record redemption, after which a single-use voucher shall not be accepted for another redemption.','FR-12']
 ],
 evaluation:[
  ['UR-QUA-01','Under normal network conditions, standard pages and interface transitions shall load in less than 3 seconds.','§4.2.2'],
  ['UR-QUA-02','Record retrieval shall meet the documented 1–2 second target, and controlled load testing shall assess support for 100–200 active concurrent users.','§4.2.2'],
  ['UR-QUA-03','The team shall evaluate user acceptance and administrative usability; the documented SUS target is above 80 out of 100.','OBJ-04; §4.2.2'],
  ['UR-QUA-04','The team shall document the deployment roadmap for PostgreSQL integration, IPFS document storage and dynamic QR voucher verification.','OBJ-04']
 ]
};
const content = String.raw`
const finalPages=[];
function titleBlock(){return p(data.title,'Label')+p('Proponents: '+data.proponents)+p('Adviser: Ms. Christine Marie D. Ordaneza')+p('Institution: Assumption College of Davao')+p('Project stage: Capstone checking     Date: September 10, 2026');}
const choices='☐ Verified\n☐ Needs Revision\n☐ Not Yet Tested\n☐ Not Applicable';
function rowsTable(rows){return table(['ID / source','User requirement','Verification status','Remarks'],rows.map(([id,requirement,source])=>[id+'\n'+source,requirement,choices,'']),[1610,4440,2230,1786],1130);}
const guide=note('Select one status: Verified = demonstrated successfully; Needs Revision = missing, incorrect or partly working; Not Yet Tested = no completed check; Not Applicable = outside the agreed current scope, with a reason. Keep evidence and observations in Remarks.');
finalPages.push(page('PROJECT OBJECTIVES','',titleBlock()+
 h('General objective')+p(data.general)+h('Specific objectives')+
 data.objectives.map((v,i)=>h('OBJ-0'+(i+1))+p(v)).join('')+
 note('Source: manuscript §1.3, PDF pages 12–13 (printed pages 11–12). Objective statements are reproduced exactly; OBJ identifiers are added for checklist references.')+
 h('Current prototype boundary')+
 p('Chapter I describes applicant submission and tracking, administrative review, server-side status rules and audit records. It identifies dynamic QR vouchers/partner verification as planned. Core workflows require internet access; AI-based document verification or eligibility scoring and direct financial/cash disbursement are excluded.')+
 note('Source: manuscript §1.4, PDF pages 13–14. Later chapters contain different completion claims; scope questions are identified on the relevant checklist pages.')
));
finalPages.push(page('USER REQUIREMENTS CHECKLIST','',
 titleBlock()+
 p('Reviewer: _____________________  App build: ______________  Web version: ______________')+
 h('Purpose')+p('Use this checklist to demonstrate the user requirements documented in the AidLink manuscript during capstone checking. Requirements are grouped by user role following the supplied example. A manuscript label of “Implemented” does not preselect the result for the version being demonstrated.')+
 guide+
 h('How to complete the checklist')+
 p('Demonstrate the stated behavior using the appropriate test account. Select one verification status and record the actual result, build and evidence reference in Remarks. If only part of a requirement works, choose Needs Revision and describe the missing behavior.')+
 p('Use fictional applicant information and sample files. Test approval and rejection on separate requests. Use two applicant accounts when checking whether personal records are restricted to the correct account.')+
 h('Requirement references')+
 p('FR identifiers refer to Table 22 in the manuscript. OBJ-01–OBJ-04 refer to the four specific objectives on the preceding objectives sheet. Section numbers and PDF page references identify the source; they do not establish that a requirement has passed.')+
 h('Planned and conflicting scope')+
 p('Section G identifies the planned partner-verification requirements and the manuscript’s conflicting FR-12 status. Agree on their scope with the reviewer before marking Not Applicable. Other unimplemented requirements should be marked Needs Revision when they remain within the agreed scope.')+
 note('The source is AidLink_ Manuscript.pdf. The format follows the other group’s example; project content and statuses have not been copied from that group.')
));
finalPages.push(page('USER REQUIREMENTS CHECKLIST','A. Shared requirements for applicable users',
 guide+rowsTable(data.shared)+
 note('Sources: FR-1/FR-2 in Table 22; §4.2.2; connectivity boundary in §1.4.2. No test result is inferred from a source-code review or a previous manuscript score.')
));
finalPages.push(page('USER REQUIREMENTS CHECKLIST','B. Applicant / Resident — digital application channel',
 p('Applicants register, submit assistance requests, upload supporting documents and follow their application status and evaluator remarks. Use fictional records for the demonstration.')+
 rowsTable(data.applicant)+
 note('Sources: FR-1–FR-4 and FR-10, PDF pages 53–55; UC-03, PDF pages 59–60. Related objectives: OBJ-01 and OBJ-02.')+
 note('FR-4 includes “Needs Resubmission.” Record whether that workflow is available. “Under Review”/“Under Evaluation” and “Denied”/“Rejected” should be checked for equivalent meaning; do not assume a missing workflow is just a label difference.')
));
finalPages.push(page('USER REQUIREMENTS CHECKLIST','C. CSWDO / LINGAP social workers and case evaluators',
 p('Use an account authorized to make request decisions. Prepare separate sample requests for approval and rejection, and verify the applicant view after each saved change.')+
 rowsTable(data.evaluator)+
 note('Sources: stakeholder roles, PDF pages 52–53; FR-4–FR-7 and FR-9, PDF pages 54–55. Related objectives: OBJ-02 and OBJ-03.')+
 note('The manuscript describes multiple staff roles. Record which login/permissions demonstrate each role; a general administrator demonstration does not by itself verify separate role restrictions.')
));
finalPages.push(page('USER REQUIREMENTS CHECKLIST','D. Administrative encoders / intake officers',
 rowsTable(data.intake)+h('E. System administrators')+rowsTable(data.admin)+
 note('Sources: stakeholder descriptions in §4.1, PDF page 53; FR-5, FR-6 and FR-9; requirements overview in §3.2, PDF pages 26–27.')+
 note('Verify the actual workflow and permission boundaries for record digitization, role/settings maintenance and reporting. If the demonstrated build lacks a required workflow, mark Needs Revision and identify the missing behavior.')
));
finalPages.push(page('USER REQUIREMENTS CHECKLIST','F. Additional manuscript requirements requiring a direct demonstration',
 p('Table 22 labels the following requirements as implemented. Verify the exact behavior stated here; a related screen or partial feature is insufficient.')+
 rowsTable(data.advanced)+
 h('What counts as evidence')+
 p('UR-ADV-01: Show a controlled duplicate test and the automatic detection result. A searchable history alone does not demonstrate automatic duplicate detection.')+
 p('UR-ADV-02: Demonstrate creation of a new letter from application data. Uploading a previously prepared letter demonstrates document attachment, not automatic generation.')+
 p('UR-ADV-03: Show delivery to a test phone/email address after a known update. An in-app Alerts screen does not demonstrate an SMS/email gateway.')+
 p('UR-ADV-04: Show the staff calculation fields and saved result, or record the gap. Recording a calculation does not imply that the system disburses money.')+
 note('Source: FR-7, FR-8, FR-10 and FR-11, PDF page 55. Keep these results separate from the Week 1 in-app notification observation.')
));
finalPages.push(page('USER REQUIREMENTS CHECKLIST','G. Accredited service providers / partners — planned scope',
 p('Chapter I and the requirements traceability matrix identify dynamic QR voucher and partner verification as a planned extension. Table 22 calls FR-12 implemented. Confirm which scope applies to today’s checking before assigning a result.')+
 rowsTable(data.planned)+
 note('If the team and reviewer retain these items as future scope, select Not Applicable and write “Planned extension; excluded from current prototype checking.” If included in the current scope, demonstrate each behavior before selecting Verified.')+
 h('Scope references')+
 p('Planned module: §1.4.1–§1.4.2, PDF pages 13–14; §2.1.4, PDF page 20; traceability matrix, PDF page 58. Conflicting implementation label: Table 22, FR-12, PDF pages 55–56.')+
 h('Related deployment roadmap')+
 p('OBJ-04 identifies PostgreSQL integration and IPFS document storage as planned work. These belong in the roadmap review; a local prototype demonstration does not establish production deployment.')+
 h('Explicit exclusions')+
 p('The documented prototype excludes AI-based document verification/eligibility scoring, direct banking or e-wallet cash disbursement and offline operation. Manual document review and recovery after reconnecting remain applicable.')+
 note('A visible QR image or verification ID does not by itself demonstrate partner scanning, redemption tracking or single-use enforcement.')
));
finalPages.push(page('USER REQUIREMENTS CHECKLIST','H. Evaluation and deployment-roadmap requirements',
 rowsTable(data.evaluation)+
 h('Evidence for evaluation results')+
 p('For timing/load results, record the build, device/network or test environment, tool, workload and measured values. For user acceptance/usability, attach actual participant records and scoring. A normal demonstration does not verify load capacity or a SUS result.')+
 note('Sources: OBJ-04, PDF page 13; non-functional requirements in §4.2.2, PDF pages 56–57. Manuscript scores remain reported results and are not copied as current checklist passes.')+
 h('Items to clarify during checking')+
 p('The manuscript describes React/Vite, Node/Express and JSON prototype storage in §3.3.1 (PDF pages 27–28), but PHP/Laravel and MySQL in §5.1 (PDF page 73). Present the actual running build and align these descriptions in the manuscript.')+
 p('Confirm the planned/current status of FR-12 and demonstrate the automatic-letter, SMS/email, duplicate-detection and grant-calculation claims before marking them Verified.')+
 p('Reviewer: __________________________  Date: _________________________________')+
 p('Follow-up items / evidence references: __________________________________________')+
 note('Prepared from AidLink_ Manuscript.pdf and formatted using project-objectives-and-user-checklist.pdf as an example. PDF page references count the cover as page 1. No other group’s project facts or verification results are used.')
));
writeDoc('AidLink_Capstone_Checking_Objectives_and_User_Requirements.docx',finalPages,'MANUSCRIPT-BASED');
// Separate copies are useful when the instructor collects the two items individually.
writeDoc('AidLink_Project_Objectives.docx',finalPages.slice(0,1),'PROJECT OBJECTIVES');
writeDoc('AidLink_User_Requirements_Checklist.docx',finalPages.slice(1),'USER REQUIREMENTS');
`;
vm.runInNewContext(layout+content,{require,__dirname,console,Buffer,data},{filename:'manuscript_final_generator.cjs'});
