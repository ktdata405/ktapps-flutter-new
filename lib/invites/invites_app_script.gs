/**
 * Google Apps Script for Invites(Fun) Management
 *
 * Instructions:
 * 1. Open Google Sheets.
 * 2. Go to Extensions > Apps Script.
 * 3. Replace all existing code with this script.
 * 4. Click 'Deploy' > 'New deployment'.
 * 5. Select type 'Web app'.
 * 6. Execute as: 'Me'.
 * 7. Who has access: 'Anyone'.
 * 8. Click 'Deploy' and copy the Web App URL into InvitesService in Flutter app.
 */

const SHEET_NAME = 'invites';

function doGet(e) {
  try {
    const action = (e && e.parameter && e.parameter.action) ? e.parameter.action : 'list';

    if (action === 'list') {
      return getInvitesList();
    } else if (action === 'addInvite') {
      return addInviteRow(e.parameter);
    } else if (action === 'updateInvite') {
      return updateInviteRow(e.parameter);
    } else if (action === 'deleteInvite') {
      return deleteInviteRow(e.parameter);
    }

    return getInvitesList();
  } catch (error) {
    return createJsonResponse({ success: false, error: error.toString() });
  }
}

function doPost(e) {
  try {
    let contents = {};
    if (e && e.postData && e.postData.contents) {
      contents = JSON.parse(e.postData.contents);
    } else if (e && e.parameter) {
      contents = e.parameter;
    }

    const action = contents.action || (e && e.parameter ? e.parameter.action : 'addInvite');

    if (action === 'list') {
      return getInvitesList();
    } else if (action === 'addInvite') {
      return addInviteRow(contents);
    } else if (action === 'updateInvite') {
      return updateInviteRow(contents);
    } else if (action === 'deleteInvite') {
      return deleteInviteRow(contents);
    }

    return addInviteRow(contents);
  } catch (error) {
    return createJsonResponse({ success: false, error: error.toString() });
  }
}

function getOrCreateSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(SHEET_NAME);
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_NAME);
    // Set headers
    sheet.appendRow(['S.No', 'Name', 'Phone', 'Status', 'Place', 'isActive', 'Remarks', 'Timestamp']);
    sheet.getRange(1, 1, 1, 8).setFontWeight('bold').setBackground('#E024B3').setFontColor('#FFFFFF');
  }
  return sheet;
}

function getInvitesList() {
  const sheet = getOrCreateSheet();
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) {
    return createJsonResponse({ success: true, data: [] });
  }

  const headers = data[0];
  const list = [];

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    if (row.length === 0 || row[0] === '' || row[0] === null) continue;

    const isActiveVal = (row[5] === true || row[5] === 'TRUE' || row[5] === 'true' || row[5] === 'Yes' || row[5] === 1);

    list.push({
      sNo: String(row[0]),
      name: String(row[1] || ''),
      phone: String(row[2] || ''),
      status: String(row[3] || 'Invited'),
      place: String(row[4] || ''),
      isActive: isActiveVal,
      remarks: String(row[6] || ''),
      date: String(row[7] || '')
    });
  }

  return createJsonResponse({ success: true, data: list });
}

function addInviteRow(data) {
  const sheet = getOrCreateSheet();
  const sNo = data.sNo || String(Math.floor(Date.now() % 1000)).padStart(3, '0');
  const name = data.name || '';
  const phone = data.phone || '';
  const status = data.status || 'Invited';
  const place = data.place || '';
  const isActive = (data.isActive === true || data.isActive === 'true' || data.isActive === 'Yes');
  const remarks = data.remarks || '';
  const timestamp = data.date || new Date().toISOString();

  sheet.appendRow([sNo, name, phone, status, place, isActive, remarks, timestamp]);
  return createJsonResponse({ success: true, message: 'Invite added successfully', sNo: sNo });
}

function updateInviteRow(data) {
  const sheet = getOrCreateSheet();
  const rows = sheet.getDataRange().getValues();
  const targetSNo = String(data.sNo);

  for (let i = 1; i < rows.length; i++) {
    if (String(rows[i][0]) === targetSNo) {
      const rowIndex = i + 1; // 1-based index

      const name = data.name !== undefined ? data.name : rows[i][1];
      const phone = data.phone !== undefined ? data.phone : rows[i][2];
      const status = data.status !== undefined ? data.status : rows[i][3];
      const place = data.place !== undefined ? data.place : rows[i][4];
      const isActive = (data.isActive === true || data.isActive === 'true' || data.isActive === 'Yes');
      const remarks = data.remarks !== undefined ? data.remarks : rows[i][6];
      const timestamp = new Date().toISOString();

      sheet.getRange(rowIndex, 1, 1, 8).setValues([[targetSNo, name, phone, status, place, isActive, remarks, timestamp]]);
      return createJsonResponse({ success: true, message: 'Invite updated successfully' });
    }
  }

  return createJsonResponse({ success: false, message: 'Record with S.No ' + targetSNo + ' not found' });
}

function deleteInviteRow(data) {
  const sheet = getOrCreateSheet();
  const rows = sheet.getDataRange().getValues();
  const targetSNo = String(data.sNo);

  for (let i = 1; i < rows.length; i++) {
    if (String(rows[i][0]) === targetSNo) {
      sheet.deleteRow(i + 1);
      return createJsonResponse({ success: true, message: 'Invite deleted successfully' });
    }
  }

  return createJsonResponse({ success: false, message: 'Record with S.No ' + targetSNo + ' not found' });
}

function createJsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
