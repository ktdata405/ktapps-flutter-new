/**
 * Google Apps Script for House Construction Bills ("Splitwise") and HL-disbursement
 * Sheet Names: "Splitwise" and "HL-disbursement"
 */

function doGet(e) {
  try {
    const action = (e && e.parameter && e.parameter.action) ? e.parameter.action : 'list';
    const sheetName = (e && e.parameter && e.parameter.sheetName) ? e.parameter.sheetName : 'Splitwise';

    if (sheetName === 'HL-disbursement') {
      if (action === 'list') return getHlList();
      if (action === 'add') return addHlRow(e.parameter);
      if (action === 'update') return updateHlRow(e.parameter);
      if (action === 'delete') return deleteHlRow(e.parameter);
      return getHlList();
    } else {
      if (action === 'list') return getSplitwiseList();
      if (action === 'add') return addSplitwiseRow(e.parameter);
      if (action === 'update') return updateSplitwiseRow(e.parameter);
      if (action === 'delete') return deleteSplitwiseRow(e.parameter);
      return getSplitwiseList();
    }
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
    const action = contents.action || (e && e.parameter ? e.parameter.action : 'list');
    const sheetName = contents.sheetName || (e && e.parameter ? e.parameter.sheetName : 'Splitwise');

    if (sheetName === 'HL-disbursement') {
      if (action === 'list') return getHlList();
      if (action === 'add') return addHlRow(contents);
      if (action === 'update') return updateHlRow(contents);
      if (action === 'delete') return deleteHlRow(contents);
      return getHlList();
    } else {
      if (action === 'list') return getSplitwiseList();
      if (action === 'add') return addSplitwiseRow(contents);
      if (action === 'update') return updateSplitwiseRow(contents);
      if (action === 'delete') return deleteSplitwiseRow(contents);
      return addSplitwiseRow(contents);
    }
  } catch (error) {
    return createJsonResponse({ success: false, error: error.toString() });
  }
}

// ── Splitwise Sheet Functions (House Construction Bills) ───────────────────

const SPLITWISE_SHEET = 'Splitwise';

function getOrCreateSplitwiseSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(SPLITWISE_SHEET);
  if (!sheet) {
    sheet = ss.insertSheet(SPLITWISE_SHEET);
    sheet.appendRow([
      'S.No', 'Date', 'Group Name', 'Amount', 'Contract Amount', 'Balance Amount', 'Timestamp'
    ]);
    sheet.getRange(1, 1, 1, 7).setFontWeight('bold').setBackground('#2563EB').setFontColor('#FFFFFF');
  }
  return sheet;
}

function getSplitwiseList() {
  const sheet = getOrCreateSplitwiseSheet();
  const rows = sheet.getDataRange().getValues();
  if (rows.length <= 1) return createJsonResponse({ success: true, data: [] });

  const headers = rows[0].map(h => String(h).trim().toLowerCase());
  const getColIdx = (names) => {
    for (let name of names) {
      const idx = headers.indexOf(name);
      if (idx !== -1) return idx;
    }
    return -1;
  };

  const sNoIdx = getColIdx(['s.no', 'sno', 'sl.no', 'id']);
  const dateIdx = getColIdx(['date', 'timestamp']);
  const groupIdx = getColIdx(['group name', 'group', 'name', 'contractor']);
  const amountIdx = getColIdx(['amount', 'bill amount', 'val']);
  const contractIdx = getColIdx(['contract amount', 'contract']);
  const balanceIdx = getColIdx(['balance amount', 'balance', 'bal']);

  const list = [];
  for (let i = 1; i < rows.length; i++) {
    const row = rows[i];
    if (!row || row.length === 0) continue;

    const isRowEmpty = row.every(cell => cell === '' || cell === null);
    if (isRowEmpty) continue;

    const sNo = sNoIdx !== -1 && row[sNoIdx] !== '' ? String(row[sNoIdx]) : String(Math.floor(Date.now() % 1000 + i));

    let date = dateIdx !== -1 ? String(row[dateIdx] || '') : '';
    let groupName = groupIdx !== -1 ? String(row[groupIdx] || '') : '';
    let amount = amountIdx !== -1 ? Number(row[amountIdx] || 0) : 0;
    let contractAmount = contractIdx !== -1 ? Number(row[contractIdx] || 0) : 0;
    let balanceAmount = balanceIdx !== -1 ? Number(row[balanceIdx] || 0) : 0;

    // Intelligent type/position inspection if headers aren't exact
    for (let c = 0; c < row.length; c++) {
      const val = row[c];
      if (val === '' || val === null) continue;
      const strVal = String(val).trim();
      const numVal = Number(val);

      if (!isNaN(numVal) && numVal !== 0 && c > 0) {
        if (amount === 0 && (c === 3 || c === 1 || amountIdx === -1)) {
          amount = numVal;
        } else if (contractAmount === 0 && (c === 4 || c === 2 || contractIdx === -1)) {
          contractAmount = numVal;
        } else if (balanceAmount === 0 && (c === 5 || c === 3 || balanceIdx === -1)) {
          balanceAmount = numVal;
        }
      } else {
        if (strVal.includes('/') || strVal.includes('-') || strVal.includes('202') || strVal.includes('203')) {
          if (!date) date = strVal;
        } else {
          if (!groupName && c <= 2) groupName = strVal;
        }
      }
    }

    if (groupName === '' && amount === 0) continue;

    list.push({
      sNo: sNo,
      date: date || String(row[1] || new Date().toLocaleDateString()),
      groupName: groupName || String(row[0] || 'General Group'),
      amount: amount,
      contractAmount: contractAmount,
      balanceAmount: balanceAmount,
      timestamp: String(row[6] || new Date().toISOString())
    });
  }
  return createJsonResponse({ success: true, data: list });
}

function addSplitwiseRow(data) {
  const sheet = getOrCreateSplitwiseSheet();
  const sNo = data.sNo || String(Math.floor(Date.now() % 1000)).padStart(3, '0');
  const date = data.date || new Date().toISOString();
  const groupName = data.groupName || '';
  const amount = Number(data.amount || 0);
  const contractAmount = Number(data.contractAmount || 0);
  const balanceAmount = Number(data.balanceAmount || 0);
  const timestamp = new Date().toISOString();

  sheet.appendRow([sNo, date, groupName, amount, contractAmount, balanceAmount, timestamp]);
  return createJsonResponse({ success: true, message: 'House bill added successfully', sNo: sNo });
}

function updateSplitwiseRow(data) {
  const sheet = getOrCreateSplitwiseSheet();
  const rows = sheet.getDataRange().getValues();
  const targetSNo = String(data.sNo);

  for (let i = 1; i < rows.length; i++) {
    if (String(rows[i][0]) === targetSNo) {
      const rowIndex = i + 1;
      const date = data.date !== undefined ? data.date : rows[i][1];
      const groupName = data.groupName !== undefined ? data.groupName : rows[i][2];
      const amount = data.amount !== undefined ? Number(data.amount) : Number(rows[i][3]);
      const contractAmount = data.contractAmount !== undefined ? Number(data.contractAmount) : Number(rows[i][4]);
      const balanceAmount = data.balanceAmount !== undefined ? Number(data.balanceAmount) : Number(rows[i][5]);
      const timestamp = new Date().toISOString();

      sheet.getRange(rowIndex, 1, 1, 7).setValues([[
        targetSNo, date, groupName, amount, contractAmount, balanceAmount, timestamp
      ]]);
      return createJsonResponse({ success: true, message: 'House bill updated successfully' });
    }
  }
  return createJsonResponse({ success: false, message: 'Record not found' });
}

function deleteSplitwiseRow(data) {
  const sheet = getOrCreateSplitwiseSheet();
  const rows = sheet.getDataRange().getValues();
  const targetSNo = String(data.sNo);

  for (let i = 1; i < rows.length; i++) {
    if (String(rows[i][0]) === targetSNo) {
      sheet.deleteRow(i + 1);
      return createJsonResponse({ success: true, message: 'Record deleted successfully' });
    }
  }
  return createJsonResponse({ success: false, message: 'Record not found' });
}

// ── HL-disbursement Sheet Functions ───────────────────────────────────────

const HL_SHEET = 'HL-disbursement';

function getOrCreateHlSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(HL_SHEET);
  if (!sheet) {
    sheet = ss.insertSheet(HL_SHEET);
    sheet.appendRow([
      'S.No', 'Date', 'Amount', 'Timestamp'
    ]);
    sheet.getRange(1, 1, 1, 4).setFontWeight('bold').setBackground('#7C3AED').setFontColor('#FFFFFF');
  }
  return sheet;
}

function getHlList() {
  const sheet = getOrCreateHlSheet();
  const rows = sheet.getDataRange().getValues();
  if (rows.length <= 1) return createJsonResponse({ success: true, data: [] });

  const headers = rows[0].map(h => String(h).trim().toLowerCase());
  const getColIdx = (names) => {
    for (let name of names) {
      const idx = headers.indexOf(name);
      if (idx !== -1) return idx;
    }
    return -1;
  };

  const sNoIdx = getColIdx(['s.no', 'sno', 'sl.no', 'id']);
  const dateIdx = getColIdx(['date', 'timestamp']);
  const amountIdx = getColIdx(['amount', 'disbursement amount', 'val']);

  const list = [];
  for (let i = 1; i < rows.length; i++) {
    const row = rows[i];
    if (!row || row.length === 0) continue;

    const isRowEmpty = row.every(cell => cell === '' || cell === null);
    if (isRowEmpty) continue;

    const sNo = sNoIdx !== -1 && row[sNoIdx] !== '' ? String(row[sNoIdx]) : String(Math.floor(Date.now() % 1000 + i));
    let date = dateIdx !== -1 ? String(row[dateIdx] || '') : '';
    let amount = amountIdx !== -1 ? Number(row[amountIdx] || 0) : 0;

    for (let c = 0; c < row.length; c++) {
      const val = row[c];
      if (val === '' || val === null) continue;
      const numVal = Number(val);
      if (!isNaN(numVal) && numVal !== 0) {
        if (amount === 0) amount = numVal;
      } else {
        if (!date) date = String(val);
      }
    }

    if (amount === 0 && date === '') continue;

    list.push({
      sNo: sNo,
      date: date || String(row[1] || new Date().toLocaleDateString()),
      amount: amount,
      timestamp: String(row[3] || new Date().toISOString())
    });
  }
  return createJsonResponse({ success: true, data: list });
}

function addHlRow(data) {
  const sheet = getOrCreateHlSheet();
  const sNo = data.sNo || String(Math.floor(Date.now() % 1000)).padStart(3, '0');
  const date = data.date || new Date().toISOString();
  const amount = Number(data.amount || 0);
  const timestamp = new Date().toISOString();

  sheet.appendRow([sNo, date, amount, timestamp]);
  return createJsonResponse({ success: true, message: 'HL disbursement added successfully', sNo: sNo });
}

function updateHlRow(data) {
  const sheet = getOrCreateHlSheet();
  const rows = sheet.getDataRange().getValues();
  const targetSNo = String(data.sNo);

  for (let i = 1; i < rows.length; i++) {
    if (String(rows[i][0]) === targetSNo) {
      const rowIndex = i + 1;
      const date = data.date !== undefined ? data.date : rows[i][1];
      const amount = data.amount !== undefined ? Number(data.amount) : Number(rows[i][2]);
      const timestamp = new Date().toISOString();

      sheet.getRange(rowIndex, 1, 1, 4).setValues([[
        targetSNo, date, amount, timestamp
      ]]);
      return createJsonResponse({ success: true, message: 'HL disbursement updated successfully' });
    }
  }
  return createJsonResponse({ success: false, message: 'Record not found' });
}

function deleteHlRow(data) {
  const sheet = getOrCreateHlSheet();
  const rows = sheet.getDataRange().getValues();
  const targetSNo = String(data.sNo);

  for (let i = 1; i < rows.length; i++) {
    if (String(rows[i][0]) === targetSNo) {
      sheet.deleteRow(i + 1);
      return createJsonResponse({ success: true, message: 'HL disbursement deleted successfully' });
    }
  }
  return createJsonResponse({ success: false, message: 'Record not found' });
}

function createJsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
