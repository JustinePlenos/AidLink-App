const fs = require('fs');
const path = require('path');
const out = __dirname;
const esc = s => String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const W = 10066;
function p(text='', style='Normal', extra='') { return `<w:p><w:pPr><w:pStyle w:val="${style}"/>${extra}</w:pPr><w:r><w:t xml:space="preserve">${esc(text)}</w:t></w:r></w:p>`; }
function h(text) { return p(text,'Heading2'); }
function note(text) { return p(text,'Note'); }
function lines(label, count=2) { return p(label,'Label')+Array.from({length:count},()=>p('________________________________________________________________________________','Writing')).join(''); }
function table(headers, rows, widths, height=0) {
  const grid = widths || headers.map(()=>Math.floor(W/headers.length));
  const row = (cells,head=false) => `<w:tr><w:trPr><w:cantSplit/>${head?'<w:tblHeader/>':''}${height&&!head?`<w:trHeight w:val="${height}" w:hRule="atLeast"/>`:''}</w:trPr>`+cells.map((c,i)=>`<w:tc><w:tcPr><w:tcW w:w="${grid[i]}" w:type="dxa"/><w:vAlign w:val="top"/>${head?'<w:shd w:fill="173A50"/>':''}</w:tcPr>${String(c).split('\n').map(t=>p(t,head?'TableHead':'TableText')).join('')}</w:tc>`).join('')+'</w:tr>';
  return `<w:tbl><w:tblPr><w:tblW w:w="${W}" w:type="dxa"/><w:tblLayout w:type="fixed"/><w:tblBorders>${['top','left','bottom','right','insideH','insideV'].map(x=>`<w:${x} w:val="single" w:sz="4" w:color="CDD9E0"/>`).join('')}</w:tblBorders><w:tblCellMar><w:top w:w="85" w:type="dxa"/><w:left w:w="100" w:type="dxa"/><w:bottom w:w="85" w:type="dxa"/><w:right w:w="100" w:type="dxa"/></w:tblCellMar></w:tblPr><w:tblGrid>${grid.map(w=>`<w:gridCol w:w="${w}"/>`).join('')}</w:tblGrid>${row(headers,true)}${rows.map(r=>row(r)).join('')}</w:tbl>`+p('','Spacer');
}
function page(title, subtitle, content) { return p(title,'Heading1')+(subtitle?note(subtitle):'')+content; }
function fields() { return table(['Project details','Complete before testing'],[
  ['Capstone title','AidLink: LINGAP Applicant App and Web Administration System\nReplace with your approved capstone title if different.'],
  ['Name / Group; Section / Block','______________________________________________________'],
  ['Instructor; Date submitted','______________________________________________________'],
  ['Testing date(s); Facilitator / Observer','______________________________________________________'],
  ['App build; Website version / commit','______________________________________________________'],
  ['Phone / OS; Browser / version; Screen size','______________________________________________________'],
  ['Test server address; Network used','______________________________________________________']
],[2700,7366]); }
function evidenceSlot(id, kind='issue', height=1600) { return table([`${kind==='issue'?'Issue':'Participant'} ${id}: insert screenshot / photo`, 'Evidence details'],[[`[Paste actual ${kind==='issue'?'issue screenshot':'session screenshot or photo'} here]`, 'Evidence ID: __________________\nCaption / task: _________________\nDate / time: ___________________\nApp / web version: ______________\nRemove personal details before sharing.']],[6100,3966],height); }
const appTasks = [
  ['M1 — Start an applicant session', 'Using the supplied fictional identity, create an account and sign in. Show where you would begin asking for assistance.', 'Prepare a unique test email and an available server. Observe label understanding, validation, password entry, confirmation and the route to a new request. Success: participant reaches an authenticated Home screen without a hint.'],
  ['M2 — Submit an assistance request', 'The fictional patient needs Hospital Assistance. Enter the supplied patient information, attach the sample requirements, explain the need, review the information and submit. Tell us how you know it was sent.', 'Prepare all documents shown for this assistance type. Observe patient/relationship fields, file selection or replacement, review and consent. Success: one request is submitted and the participant can find its reference number and Pending status. Record the reference for web testing.'],
  ['M3 — Find a decision and approval documents', 'Find the supplied request and explain its current status. For the approved example, show the document and verification information you would present at the facility.', 'Prepare separate Pending, Under Review, Approved and Denied examples for this applicant. Observe search/filter use and status interpretation. Success: correct request found; approved guarantee letter and QR/verification ID located. Opening a document must be observed, not assumed.'],
  ['M4 — Find an update and assigned facility', 'Find the latest update about your request. Then show where you would go for the approved request and find the facility address and available contact information.', 'Prepare a notification and an approved request with an assigned active facility. Success: relevant update and matching facility details found. Directions may open a map; do not place a real call. Finish by asking the participant to sign out.']
];
const webTasks = [
  ['W1 — Locate and review an application', 'Sign in with the supplied staff account. Find the request with the supplied reference, inspect the applicant details and supporting documents, and explain what you would review.', 'Provide an Administrator or Super Admin test account and the reference from M2. Success: the matching record and its documents are found. Note use of Overview, Assistance requests and Requestors, and any confusion between applicant and patient details.'],
  ['W2 — Record review and approval', 'For the approved training case, record that review has started. Then record the approval using the supplied decision note, sample guarantee letter and designated training facility.', 'Use a Pending training request, a PDF/JPG/PNG letter no larger than 10 MB, and an eligible active facility. Observe required remarks and file feedback. Success: Under Review then Approved is saved with the letter; the chosen facility is shown. Facility assignment is currently optional; select one for this scenario.'],
  ['W3 — Record a denial', 'A separate fictional application did not satisfy the stated training requirements. Record the supplied denial explanation and check that the decision was saved.', 'Use a different Pending or Under Review request. Success: Denied and the decision note appear in the request/audit trail. Ask what the applicant would need to understand next; do not imply a resubmission feature exists.'],
  ['W4 — Maintain facility information', 'Find the designated training facility, correct its supplied contact details and verify the saved information. Then find the required-document list for the supplied assistance type.', 'Prepare a training facility and replacement contact details. Success: the intended record is updated and the correct requirements list is located. Optional developer follow-up: change one requirement and check a fresh app request for consistency; restore the test configuration afterward.']
];
function taskPage(title, tasks) { return page(title,'Read only the scenario aloud. The facilitator notes define preparation and completion checks.',tasks.map(([name,scenario,guide])=>h(name)+p(scenario)+note('Facilitator only: '+guide)).join('')+note('Record outcome, elapsed time, hints, quotes and evidence in the Week 2 Observation Record. Do not coach the route through the interface.')); }

const week1=[];
week1.push(page('INITIAL CAPSTONE UX AUDIT','Week 1 testing workbook | ITE 4 – Web Systems and Technologies 2',fields()+h('Purpose and use')+p('Audit both the applicant mobile app and the LINGAP web administration system before observing users. This workbook adapts the teacher’s three-part template and its proof-of-audit appendix. It contains planned checks, not completed testing results.')+p('Complete Part 1 while using the running system. Log confirmed issues in Part 2, plan user sessions in Part 3, and attach actual evidence in Appendix A. Leave signatures and results blank until the activity is completed.')+h('Prepare a repeatable test session')+p('Use a test server, fictional applicant/patient profiles and clearly marked sample documents. Prepare staff accounts, an active training facility and separate requests for approval and denial. Keep the phone and website connected to the same test backend.')+p('Have a valid document set, a sample guarantee letter, an unsupported file and an oversized file ready. Do not use real IDs, medical records, passwords or live applicant decisions in screenshots.')+note('Scope: Home, Requests, Facilities, Alerts and Account in the app; Overview, Assistance requests, Requestors, Facilities and administrator account screens on the web. Test setup and recovery checks are facilitator activities.')));

const checklistGroups=[
 ['PART 1: AUDIT CHECKLIST','Usability and core functionality',[
 ['Usability','U1 • App: A first-time applicant can find the new-request flow from Home.'],
 ['Usability','U2 • App: Patient identity and relationship fields can be completed without confusing the patient with the account holder.'],
 ['Usability','U3 • App: The applicant can choose the appropriate assistance type and understand which documents to attach.'],
 ['Usability','U4 • App: The review screen lets the applicant check information and understand consent before submission.'],
 ['Usability','U5 • Web: Staff can locate the intended application and distinguish review, approval and denial actions.'],
 ['Functionality','F1 • Both: Valid sign-in works; incorrect credentials give useful feedback; sign-out ends access to the session.'],
 ['Functionality','F2 • App: Required fields and invalid dates are identified; correcting an error allows progress.'],
 ['Functionality','F3 • App: Documents can be selected/replaced; unsupported or oversized files get understandable feedback.'],
 ['Functionality','F4 • App → web: Submission creates one matching request with a reference, assistance type and document links.'],
 ['Functionality','F5 • Web: Review/denial requires remarks; approval requires remarks and a valid guarantee-letter file.']
 ]],
 ['PART 1: AUDIT CHECKLIST (continued)','Accessibility and responsiveness',[
 ['Accessibility','A1 • Both: Labels, instructions and status text remain readable against their backgrounds.'],
 ['Accessibility','A2 • Both: Pending, Under Review, Approved and Denied can be understood without relying only on color.'],
 ['Accessibility','A3 • Web: Keyboard users can reach controls in logical order and identify the focused item.'],
 ['Accessibility','A4 • Web: Request dialogs can be used and closed with the keyboard, with focus returned sensibly.'],
 ['Accessibility','A5 • App: A screen reader announces navigation, form labels, important icons and validation feedback.'],
 ['Accessibility','A6 • Both: Buttons and links can be selected accurately; document/QR alternatives have meaningful labels.'],
 ['Responsiveness','R1 • App: On the smallest available phone, the keyboard does not hide required fields or the next/submit action.'],
 ['Responsiveness','R2 • App: Larger system text leaves request forms, review dialogs and navigation readable and usable.'],
 ['Responsiveness','R3 • Web: At phone, tablet and laptop widths, navigation and request actions remain reachable.'],
 ['Responsiveness','R4 • Web: At 200% browser zoom, dialogs, tables and file controls remain usable without clipped actions.']
 ]],
 ['PART 1: AUDIT CHECKLIST (continued)','Content quality, recovery and consistency',[
 ['Content Quality','C1 • Both: Assistance descriptions, field labels and required-document names use clear, consistent language.'],
 ['Content Quality','C2 • Both: Status messages distinguish submission, review and approval; instructions do not promise cash release.'],
 ['Content Quality','C3 • Both: Errors explain what happened and a useful next action, without unexplained technical terms.'],
 ['Functionality','F6 • Web → app: Review, approval and denial changes appear on the matching applicant request after refresh.'],
 ['Functionality','F7 • App: Approved requests show the correct guarantee letter and QR/verification ID; document links open.'],
 ['Functionality','F8 • Both: An assigned active facility matches across systems; missing assignment is clearly explained.'],
 ['Functionality','F9 • App: Opening an alert shows the correct request and updates its read state; another account’s alerts are not shown.'],
 ['Functionality','F10 • Both: Searches and filters return the expected request; no-match and empty states are understandable.'],
 ['Functionality','F11 • App: Losing connection shows useful feedback; reconnecting/refreshing recovers without a misleading success message.'],
 ['Functionality','F12 • Web → app: After a test requirement change, a fresh app request shows the configured requirements or a mismatch is logged.']
 ]]
];
for(const [title,subtitle,rows] of checklistGroups) week1.push(page(title,subtitle,note('Mark ✓ (met), ✗ (not met), or Partial after testing. Leave untested rows blank and write “Not tested” in Notes. Use N/A only with a reason. For ✗/Partial, include evidence and an issue ID; Notes are optional for ✓.')+table(['Dimension','AidLink / LINGAP checklist item','Check','Notes / evidence ID'],rows.map(([d,t])=>[d,t,'','']),[1570,4620,760,3116],730)+note('Evaluator: ____________________  Date / time: ____________________  Build: ____________________')));
week1.push(page('PART 2: LIST OF AT LEAST 5 ISSUES','Complete from observed problems. Do not invent issues to fill the table.',p('Use the checklist ID and app/web screen to locate each issue. Describe what the user did, what actually happened and the expected behavior. Explain the practical consequence for an applicant or staff member.')+table(['#','Issue description / steps','Dimension','Likely impact on real user','Suggested fix (optional)'],Array.from({length:5},(_,i)=>[`I0${i+1}`,'Screen / check ID:\n\nSteps / actual / expected:','','','']),[530,3260,1300,2750,2226],1500)+note('Add I06+ rows/pages as needed. Attach matching evidence in Appendix A. If fewer than five issues are confirmed, keep unused rows blank and ask the instructor how to report the shortfall.')+lines('Audit summary — strongest areas and areas needing follow-up',2)));
week1.push(page('PART 3: USER OBSERVATION / FEEDBACK PLAN','3a. Planned participants',table(['Participant role / target','Why appropriate','Planned tasks'],[
 ['P01–P03: 3 adult applicant-role users','Include different levels of smartphone confidence and a first-time user. They reflect the application, tracking and facility-information workflow.','M1–M4; shorten the set if needed.'],
 ['P04–P05: 2 staff-role users','Prefer LINGAP/CMO personnel who review requests. If unavailable, identify substitutes as role-playing testers and state the limitation.','W1–W4.'],
 ['P06–P10: optional additional users','Expand to 5–10 total as recommended in the teacher’s template. Include relevant accessibility needs when feasible and voluntary.','Repeat the same core tasks.']
],[2600,4500,2966])+h('3b. Neutral observation questions')+p('1. What do you think you can do on this screen?')+p('2. What would you do next, and what do you expect to happen?')+p('3. What tells you whether the request or decision was saved?')+p('4. Which part, if any, was unclear, and what did you expect instead?')+h('3c. Testing tool / method')+p('Use moderated, in-person think-aloud sessions with one facilitator and one note-taker. Plan about 25–35 minutes per participant, including consent and feedback. Pilot the task set once; use the same core tasks for comparable participants. Record time, independent completion, assistance, errors, successes and direct quotes.')+p('Use screen captures or photos only with consent. Record accessibility/resizing checks separately from user opinions. An optional browser audit report supports the manual audit but does not replace observation. Record the tool, version, date and tested screen if used.')+h('Read at the start')+p('“We are testing the system, not you. Please use the supplied fictional information and say what you are thinking. You may skip a task or stop at any time. I will usually let you try first, and I will record any help I give.”')+note('Task outcomes: Independent / Assisted / Incomplete / Not attempted. Begin timing after reading the task; stop when completed or the participant stops. Record hints instead of counting assisted work as independent.')));
week1.push(taskPage('PART 3: APP TASK CARDS',appTasks));
week1.push(taskPage('PART 3: WEB TASK CARDS',webTasks));
week1.push(page('PART 3: FACILITATOR TEST SETUP','Shared test data and app-to-web checks',table(['Preparation item','Record your testing value'],[
 ['Fictional applicant / patient','Account name: __________________  Patient name: __________________\nUnique test email: __________________  Relationship: ________________'],
 ['Assistance and sample files','Core task: Hospital Assistance\nPatient details sheet: __________  Requirement files: ________________'],
 ['Separate decision cases','Approval request reference: _____________________________________\nDenial request reference: _______________________________________'],
 ['Staff and facility','Staff role: __________________  Training facility: __________________\nSample guarantee letter: ________________________________________'],
 ['Additional state examples','Pending: __________________  Under Review: _____________________\nApproved: _________________  Denied: __________________________'],
 ['Test environment','Phone server URL: _________________  Web URL: _________________\nDo not record account passwords in this workbook.']
],[2900,7166])+h('H1 — Verify the complete handoff (facilitator only)')+p('1. Submit M2 in the app. Record the reference and submission time. Open that reference in the web system and compare patient/applicant details, assistance type and documents.')+p('2. In the web system, save Under Review, then approve using the sample letter and training facility. Record the decision time; refresh the app and record when each status becomes visible.')+p('3. Open the app’s guarantee letter and QR/verification display. Check the assigned facility and related alert. Confirm that refreshing does not change the approval’s verification ID.')+p('4. Deny a different training request and verify the matching app status. Sign out and use a second test applicant account to check that the first applicant’s requests and alerts are not shown.')+h('H2 — Recovery and configuration (optional follow-up)')+p('Briefly disconnect the phone during a safe read or sample submission, record the message, reconnect and retry. Check for duplicate submissions. Change a training document requirement on the web and compare a fresh app request. Record discrepancies as issues and restore the training configuration.')+note('Keep these controlled checks separate from participant task scores. This workbook does not assume automatic push updates or successful synchronization; record the actual refresh behavior and delay.')));
week1.push(page('APPENDIX A: PROOF OF AUDIT ACTIVITY','A1. Screenshot evidence — issues I01–I03',note('Attach actual captures for Part 2 issues. Match each image to its issue ID and include a short caption describing the visible problem.')+evidenceSlot('I01')+evidenceSlot('I02')+evidenceSlot('I03')));
week1.push(page('APPENDIX A: PROOF OF AUDIT ACTIVITY','A1. Screenshot evidence — issues I04–I05',evidenceSlot('I04', 'issue',1250)+evidenceSlot('I05','issue',1250)+h('A2. Automated tool report (optional)')+table(['Tool / version / date','Screenshot or attachment reference','Score / summary and limitations'],[['___________________','[Insert actual report or evidence filename]','____________________________\nScreen tested: ________________']],[2500,4000,3566],950)+h('A3. Certification of authenticity')+p('I certify that I personally conducted this audit on my own Capstone application on the date(s) indicated above.')+p('Printed name: __________________________________  Signature: _________________________')+p('Date signed: ____________________')+note('Sign only after completing the audit. Supporting basis: the teacher’s Week1_Initial_Capstone_UX_Audit.docx and the local AidLink app/web source files. Expected checks are not evidence of successful behavior.')));

const week2=[];
week2.push(page('USER EXPERIENCE DISCOVERY & IMPROVEMENT REPORT','Week 2 testing workbook | ITE 4 – Web Systems and Technologies 2',fields()+h('Purpose and use')+p('Use this workbook during real sessions, then document patterns, priorities, implemented fixes and a second user check. It preserves the teacher’s six report parts and three appendices. Five blank participant records are included; duplicate them for additional participants.')+p('Use M1–M4 for applicant users and W1–W4 for staff users from the companion Week 1 workbook. Select a realistic task set before the session and record any changes. Collect successes as well as difficulties. Do not treat expected outcomes as observed results.')+h('Recording rules')+p('Use participant codes P01–P10 throughout. Obtain consent first using Appendix A. Record the exact task IDs, build, device and evidence references. Use quotation marks only for the participant’s actual words; identify paraphrases. Leave results blank until observed.')+p('Outcome: I = independent; A = completed with help; F = incomplete; N = not attempted. Start timing after the scenario is read. Log hints and elapsed time; exclude N from completion calculations. Do not turn this small study into a claim about all LINGAP users.')+note('Before/after screenshots, priorities and reflections are intentionally unfilled. Add only actual findings and changes. Participant evidence should use fictional application data and omit faces/personal information unless specifically permitted.')));
for(let i=1;i<=5;i++) {
  const id=`P0${i}`;
  week2.push(page(`PART 1: OBSERVATION RECORD #${i}`,`${id} | Suggested role: ${i<=3?'Applicant':'Staff reviewer'} — record actual role below`,
    table(['Session details','Complete during the session'],[
      ['Participant (role/type)','Code: '+id+'   Actual role: _________________________________\nRelevant app/computer experience: ____________________________'],
      ['Session / consent','Date: __________  Start: ________  End: ________\nFacilitator: __________  Consent/evidence preference: __________'],
      ['System / device / version','App / Web: ________  Device / browser: _______________________\nBuild: ______________  Network: _____________________________']
    ],[2650,7416])+h('Task given and outcome log')+note('Use Week 1 scenarios. Enter the task ID and any wording change. I / A / F / N: independent / assisted / incomplete / not attempted. Ease is optional: 1 = very difficult, 5 = very easy.')+
    table(['Task ID / wording change','Outcome','Time (sec)','Hints / errors','Ease 1–5'],Array.from({length:4},()=>['','','','','']),[4160,1100,1300,2300,1206],480)+
    lines('Observed actions / behavior — include successful actions and sequence',3)+
    lines('Difficulties noted — where, what happened, and effect on the task (or “none observed”)',2)+
    lines('Direct quotes / comments — exact words, or label as a paraphrase',2)+
    lines('Suggestions given by participant — keep separate from the team’s proposed fix',2)+
    p('Evidence IDs / filenames: _______________________  Related issue IDs: ____________________','Note')
  ));
}
week2.push(page('PART 2: FINDINGS (PATTERNS ACROSS USERS)','Summarize both successful patterns and repeated difficulties.',p('Group observations by task and user role. For each pattern, count only people who attempted the relevant task. Report n/N (for example, 2/3), participant codes and evidence references; do not combine unrelated app and staff tasks into one denominator.')+
  table(['Observation insights','Users who experienced it (n/N)','Notes / participant and evidence IDs'],Array.from({length:6},()=>['Pattern / task / app or web:\n\nSuccess or difficulty:','','']),[4490,1900,3676],1000)+
  h('Task outcome summary')+table(['Task / role','Attempted (I+A+F)','Independent (I)','Assisted (A)','Incomplete (F)'],Array.from({length:3},()=>['','','','','']),[2600,2000,1800,1800,1866],410)+
  note('Independent completion rate = I ÷ (I+A+F) × 100. Report the counts with any percentage. Summarize time only when tasks and completion conditions are comparable; flag interrupted or assisted runs.')+
  lines('What worked well and should be retained?',2)));
week2.push(page('PART 3: PRIORITIZED ISSUES','Use the teacher’s Impact × Frequency framework.',p('Impact: High = blocks a core task, causes an incorrect request/decision, or prevents access to needed information. Low = recoverable friction with limited effect. Frequency: record n/N for relevant task attempts, then apply your class definition of High or Low.')+
  note('If the lecture notes do not specify a frequency threshold, use this proposed study convention and label it: High = at least half of relevant participants; Low = fewer than half. Confirm this convention against the lecture notes before submission.')+
  p('Order high-impact/high-frequency issues first, then high-impact/low-frequency, low-impact/high-frequency, and low-impact/low-frequency. Use evidence and implementation dependencies to explain ties. Keep a serious isolated issue visible even when frequency is low.')+
  table(['Issue / evidence IDs','Impact H/L','Frequency H/L; n/N','Priority rank','Planned fix'],Array.from({length:5},()=>['','','','','']),[3000,1150,1700,1100,3116],1140)+
  lines('Rationale for top priority / ties',2)+
  p('Fix owner: ____________________  Target build / date: ____________________')+
  lines('Deferred issues and reason',2)));
for(let i=1;i<=2;i++) week2.push(page(`PART 4: BEFORE / AFTER EVIDENCE — FIX ${i}`,'Duplicate this page for each additional implemented improvement.',
  table(['Change details','Complete after implementation'],[
    ['Issue fixed / priority','Issue ID: __________  Task / screen: _________________________\nPattern / participant evidence: ______________________________'],
    ['Change and intended benefit','________________________________________________________\n________________________________________________________'],
    ['Implementation reference','Owner: ___________________  Date: ________________________\nBefore build: ______________  After build / commit: ___________']
  ],[2800,7266])+
  table(['Before screenshot','After screenshot'],[['[Paste actual screenshot before the fix]','[Paste actual screenshot after the fix]']],[5033,5033],3500)+
  table(['Before caption / date / evidence ID','After caption / date / evidence ID'],[['______________________________________\n______________________________________','______________________________________\n______________________________________']],[5033,5033],620)+
  note('Use the same task and comparable screen state/viewport. Mask personal data. If a change is behavioral, attach the relevant sequence or recording reference instead of relying on a static image.')+
  lines('How the change addresses the observed user impact',3)));
week2.push(page('PART 5: SECOND USER CHECK (VERIFICATION)','Repeat the affected task after the fix; do not assume a visual change resolved the problem.',[1,2].map(i=>
  h(`Verification record ${i}`)+table(['Verification item','Observed result'],[
    ['Participant (same or different)','Code / role: __________  Same / different: __________\nNew consent/attendance entry, if needed: _______________________'],
    ['Issue / task / test conditions','Issue: __________  Task: __________  Date: __________________\nBuild / device: ___________________________________________'],
    ['Outcome and comparison','Before I/A/F: _____  After I/A/F: _____  Hints before/after: ______\nTime before/after: __________  Conditions changed: ____________'],
    ['Was the fix effective?','Yes / No / Partially: __________\nNotes / evidence: _________________________________________'],
    ['Remaining difficulty / next action','________________________________________________________']
  ],[3000,7066])
).join('')+note('Check the original failure and nearby behavior. A different participant or prior familiarity can affect the comparison; record that limitation. If the issue persists, revise its status and plan another check.')));
week2.push(page('PART 6: REFLECTION','Complete after observation, improvements and verification.',
  h('1. What did you realize about your assumptions as a developer after the user observation?')+
  note('Connect an assumption about applicants or staff to a specific task, participant code and observed result.')+lines('Response',6)+
  h('2. What was the biggest surprise you learned from the real users?')+
  note('Include a success or difficulty and explain why it changed your understanding of the LINGAP workflow.')+lines('Response',6)+
  h('3. What will you do differently in your next project/capstone iteration?')+
  note('State a concrete change to design, testing or implementation and how you will check its effect.')+lines('Response',5)));
week2.push(page('APPENDIX A: PARTICIPANT CONSENT & ATTENDANCE','Obtain consent before each session; duplicate for additional participants or retests.',
  p('Purpose: evaluate how easily people can use the AidLink applicant app and LINGAP web system for a capstone class. The session uses fictional records and takes approximately 25–35 minutes. Participation is voluntary; a participant may skip questions, pause or stop without penalty.')+
  p('The team will take task notes using a participant code. Screenshots/photos are optional and may be used as class evidence only with permission. Avoid recording faces or personal details. Agree to any additional recording separately.')+
  p('Team contact: _________________________  Who may view the evidence: ____________________')+
  p('Storage location / access: _____________________  Planned deletion date: __________________')+
  note('Complete and explain the information above before requesting a signature. If a participant declines images, take notes only and mark “not captured—consent declined” in Appendix B.')+
  p('Participant statement: I understand the activity and voluntarily agree to take part. My screenshot/photo preference is recorded below. I understand I may stop at any time.')+
  table(['Code','Name / initials','Signature','Date','Start','End'],Array.from({length:5},(_,i)=>[`P0${i+1}`,'','','','','']),[700,2300,2600,1700,1380,1386],650)+
  table(['Code','Screenshot/photo consent (Yes / No)','Notes / retest session date'],Array.from({length:5},(_,i)=>[`P0${i+1}`,'','']),[900,4300,4866],420)+
  note('Use codes in the report body. Keep this attendance page separate from public copies. For additional/retest participants, duplicate a row and link it to the corresponding observation record.')));
week2.push(page('APPENDIX B: SESSION EVIDENCE','P01–P03 | Attach consented session evidence; duplicate pages if needed.',evidenceSlot('P01','participant',1800)+evidenceSlot('P02','participant',1800)+evidenceSlot('P03','participant',1800)+note('Show the task being performed, not just a posed photo. Reference the matching observation record. When no image is permitted, document the reason and link the written session notes.')));
week2.push(page('APPENDIX B: SESSION EVIDENCE (continued)','P04–P05',evidenceSlot('P04','participant',1500)+evidenceSlot('P05','participant',1500)+
  h('APPENDIX C: CERTIFICATION OF AUTHENTICITY')+
  p('We certify that the observation sessions described in this report were personally conducted with the participants listed in Appendix A, and that the before/after evidence reflects actual changes made to our Capstone application.')+
  p('Printed name: __________________________________  Signature: _________________________')+
  p('Printed name: __________________________________  Signature: _________________________')+
  p('Date signed: ____________________')+
  note('Sign only after completing the reported activities. Add signature lines for other group members as needed.')+
  h('Before submitting')+p('Check that observation records, issue IDs, participant counts, screenshot captions and retest results agree. Remove unused placeholders or mark them clearly. Include unresolved issues and actual study limitations.')+
  note('Adapted from Week2_UX_Discovery_Improvement_Report.docx. Task details are based on the local AidLink app and web source. No participant results, test passes or completed fixes were supplied or invented.')));

const styles=`<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/><w:color w:val="263746"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="100" w:line="260" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>${[
 ['Normal','',''],
 ['Heading1','<w:keepNext/><w:spacing w:before="0" w:after="170"/><w:outlineLvl w:val="0"/>','<w:b/><w:sz w:val="32"/><w:color w:val="173A50"/>'],
 ['Heading2','<w:keepNext/><w:spacing w:before="180" w:after="90"/><w:outlineLvl w:val="1"/>','<w:b/><w:sz w:val="24"/><w:color w:val="126A71"/>'],
 ['Note','<w:spacing w:after="110" w:line="230" w:lineRule="auto"/>','<w:sz w:val="19"/><w:color w:val="536775"/>'],
 ['Label','<w:keepNext/><w:spacing w:before="100" w:after="60"/>','<w:b/><w:sz w:val="21"/>'],
 ['Writing','<w:spacing w:after="45" w:line="265" w:lineRule="auto"/>','<w:sz w:val="19"/><w:color w:val="ABB7BF"/>'],
 ['TableText','<w:spacing w:after="55" w:line="230" w:lineRule="auto"/>','<w:sz w:val="20"/>'],
 ['TableHead','<w:spacing w:after="30" w:line="220" w:lineRule="auto"/>','<w:b/><w:sz w:val="20"/><w:color w:val="FFFFFF"/>'],
 ['Spacer','<w:spacing w:after="0" w:line="50" w:lineRule="exact"/>','<w:sz w:val="2"/>']
].map(([id,pp,rp])=>`<w:style w:type="paragraph" w:styleId="${id}"><w:name w:val="${id}"/>${id!=='Normal'?'<w:basedOn w:val="Normal"/>':''}<w:pPr>${pp}</w:pPr><w:rPr>${rp}</w:rPr></w:style>`).join('')}</w:styles>`;
function crc32(buf) { let crc=0xffffffff; for(const b of buf) {crc^=b; for(let k=0;k<8;k++) crc=(crc>>>1)^((crc&1)?0xedb88320:0);} return (crc^0xffffffff)>>>0; }
function zip(entries) { let offset=0; const local=[], central=[]; for(const [name,raw] of Object.entries(entries)) {const n=Buffer.from(name),b=Buffer.from(raw),crc=crc32(b);const l=Buffer.alloc(30);l.writeUInt32LE(0x04034b50,0);l.writeUInt16LE(20,4);l.writeUInt32LE(crc,14);l.writeUInt32LE(b.length,18);l.writeUInt32LE(b.length,22);l.writeUInt16LE(n.length,26);local.push(l,n,b);const c=Buffer.alloc(46);c.writeUInt32LE(0x02014b50,0);c.writeUInt16LE(20,4);c.writeUInt16LE(20,6);c.writeUInt32LE(crc,16);c.writeUInt32LE(b.length,20);c.writeUInt32LE(b.length,24);c.writeUInt16LE(n.length,28);c.writeUInt32LE(offset,42);central.push(c,n);offset+=l.length+n.length+b.length;} const cd=Buffer.concat(central),end=Buffer.alloc(22);end.writeUInt32LE(0x06054b50,0);end.writeUInt16LE(Object.keys(entries).length,8);end.writeUInt16LE(Object.keys(entries).length,10);end.writeUInt32LE(cd.length,12);end.writeUInt32LE(offset,16);return Buffer.concat([...local,cd,end]); }
function writeDoc(name,pages,week) {
 const relns='http://schemas.openxmlformats.org/package/2006/relationships';
 const docns='http://schemas.openxmlformats.org/wordprocessingml/2006/main';
 const entries={
 '[Content_Types].xml':`<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/>${[['/word/document.xml','document.main'],['/word/styles.xml','styles'],['/word/header1.xml','header'],['/word/footer1.xml','footer'],['/word/settings.xml','settings']].map(([n,t])=>`<Override PartName="${n}" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.${t}+xml"/>`).join('')}</Types>`,
 '_rels/.rels':`<Relationships xmlns="${relns}"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>`,
 'word/_rels/document.xml.rels':`<Relationships xmlns="${relns}">${[['rId1','styles','styles.xml'],['rId2','header','header1.xml'],['rId3','footer','footer1.xml'],['rId4','settings','settings.xml']].map(([id,type,target])=>`<Relationship Id="${id}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/${type}" Target="${target}"/>`).join('')}</Relationships>`,
 'word/document.xml':`<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="${docns}" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><w:body>${pages.join('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')}<w:sectPr><w:headerReference w:type="default" r:id="rId2"/><w:footerReference w:type="default" r:id="rId3"/><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="850" w:right="920" w:bottom="850" w:left="920" w:header="340" w:footer="340"/></w:sectPr></w:body></w:document>`,
 'word/styles.xml':styles,
 'word/settings.xml':`<w:settings xmlns:w="${docns}"><w:updateFields w:val="true"/><w:compat><w:compatSetting w:name="compatibilityMode" w:uri="http://schemas.microsoft.com/office/word" w:val="15"/></w:compat></w:settings>`,
 'word/header1.xml':`<w:hdr xmlns:w="${docns}">${p('AidLink / LINGAP     •     APP + WEB UX TESTING     •     '+week,'Note','<w:pBdr><w:bottom w:val="single" w:sz="8" w:color="126A71"/></w:pBdr>')}</w:hdr>`,
 'word/footer1.xml':`<w:ftr xmlns:w="${docns}"><w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="18"/><w:color w:val="536775"/></w:rPr><w:t>Testing workbook • Record actual evidence     |     Page </w:t></w:r><w:fldSimple w:instr="PAGE"><w:r><w:t>1</w:t></w:r></w:fldSimple></w:p></w:ftr>`
 };
 fs.writeFileSync(path.join(out,name),zip(entries));
 fs.writeFileSync(path.join(out,name.replace('.docx','.txt')),pages.map(x=>x.replace(/<\/w:p>/g,'\n').replace(/<[^>]+>/g,'').replace(/&amp;/g,'&')).join('\n\n[PAGE BREAK]\n\n'));
 console.log(`${name}: ${pages.length} planned pages; ${fs.statSync(path.join(out,name)).size} bytes`);
}
writeDoc('AidLink_LINGAP_Week1_UX_Audit_Testing_Workbook.docx',week1,'WEEK 1');
writeDoc('AidLink_LINGAP_Week2_UX_Discovery_Improvement_Workbook.docx',week2,'WEEK 2');
