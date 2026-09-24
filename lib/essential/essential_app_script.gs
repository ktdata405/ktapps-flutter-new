/**
 * Google Apps Script for Distribution Essential Management & Cash Gift
 * Sheet Names: "Essential Items for Delivery" and "Cash Gift"
 */

function doGet(e) {
  try {
    const action = (e && e.parameter && e.parameter.action) ? e.parameter.action : 'list';
    const sheetName = (e && e.parameter && e.parameter.sheetName) ? e.parameter.sheetName : 'Essential Items for Delivery';

    if (sheetName === 'Cash Gift') {
      if (action === 'list') return getCashGiftList();
      if (action === 'add') return addCashGiftRow(e.parameter);
      if (action === 'update') return updateCashGiftRow(e.parameter);
      if (action === 'delete') return deleteCashGiftRow(e.parameter);
      return getCashGiftList();
    } else {
      if (action === 'list') return getEssentialList();
      if (action === 'add') return addEssentialRow(e.parameter);
      if (action === 'update') return updateEssentialRow(e.parameter);
      if (action === 'delete') return deleteEssentialRow(e.parameter);
      return getEssentialList();
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
    const action = contents.action || (e && e.parameter ? e.parameter.action : 'add');
    const sheetName = contents.sheetName || (e && e.parameter ? e.parameter.sheetName : 'Essential Items for Delivery');

    if (sheetName === 'Cash Gift') {
      if (action === 'list') return getCashGiftList();
      if (action === 'add') return addCashGiftRow(contents);
      if (action === 'update') return updateCashGiftRow(contents);
      if (action === 'delete') return deleteCashGiftRow(contents);
      return addCashGiftRow(contents);
    } else {
      if (action === 'list') return getEssentialList();
      if (action === 'add') return addEssentialRow(contents);
      if (action === 'update') return updateEssentialRow(contents);
      if (action === 'delete') return deleteEssentialRow(contents);
      return addEssentialRow(contents);
    }
  } catch (error) {
    return createJsonResponse({ success: false, error: error.toString() });
  }
}

// ── Essential Items Sheet Functions ────────────────────────────────────────

const ESSENTIAL_SHEET = 'Essential Items for Delivery';

function getOrCreateEssentialSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(ESSENTIAL_SHEET);
  if (!sheet) {
    sheet = ss.insertSheet(ESSENTIAL_SHEET);
    sheet.appendRow([
      'S.No', 'Date', 'Full Name',
      'Rice (KG)', 'Dal (KG)', 'Oil (KG)', 'Onions (KG)', 'Tamarind (KG)',
      'Col I', 'Col J', 'Total Amount', 'Timestamp'
    ]);
    sheet.getRange(1, 1, 1, 12).setFontWeight('bold').setBackground('#059669').setFontColor('#FFFFFF');
  }
  return sheet;
}

function getEssentialList() {
  const sheet = getOrCreateEssentialSheet();
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return createJsonResponse({ success: true, data: [] });

  const list = [];
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    if (!row || row[0] === '' || row[0] === null) continue;

    const totalAmtFromK = Number(row[10] !== undefined && row[10] !== '' ? row[10] : (row[9] || 0));

    list.push({
      sNo: String(row[0]),
      date: String(row[1] || ''),
      fullName: String(row[2] || ''),
      itemD: Number(row[3] || 0),
      itemE: Number(row[4] || 0),
      itemF: Number(row[5] || 0),
      itemG: Number(row[6] || 0),
      itemH: Number(row[7] || 0),
      totalAmount: totalAmtFromK,
      timestamp: String(row[11] || '')
    });
  }
  return createJsonResponse({ success: true, data: list });
}

function addEssentialRow(data) {
  const sheet = getOrCreateEssentialSheet();
  const sNo = data.sNo || String(Math.floor(Date.now() % 1000)).padStart(3, '0');
  const date = data.date || new Date().toISOString();
  const fullName = data.fullName || '';
  const itemD = Number(data.itemD || 0);
  const itemE = Number(data.itemE || 0);
  const itemF = Number(data.itemF || 0);
  const itemG = Number(data.itemG || 0);
  const itemH = Number(data.itemH || 0);
  const colI = data.colI || '';
  const colJ = data.colJ || '';
  const totalAmount = Number(data.totalAmount || 0);
  const timestamp = new Date().toISOString();

  sheet.appendRow([sNo, date, fullName, itemD, itemE, itemF, itemG, itemH, colI, colJ, totalAmount, timestamp]);
  return createJsonResponse({ success: true, message: 'Record added successfully', sNo: sNo });
}

function updateEssentialRow(data) {
  const sheet = getOrCreateEssentialSheet();
  const rows = sheet.getDataRange().getValues();
  const targetSNo = String(data.sNo);

  for (let i = 1; i < rows.length; i++) {
    if (String(rows[i][0]) === targetSNo) {
      const rowIndex = i + 1;
      const date = data.date !== undefined ? data.date : rows[i][1];
      const fullName = data.fullName !== undefined ? data.fullName : rows[i][2];
      const itemD = data.itemD !== undefined ? Number(data.itemD) : Number(rows[i][3]);
      const itemE = data.itemE !== undefined ? Number(data.itemE) : Number(rows[i][4]);
      const itemF = data.itemF !== undefined ? Number(data.itemF) : Number(rows[i][5]);
      const itemG = data.itemG !== undefined ? Number(data.itemG) : Number(rows[i][6]);
      const itemH = data.itemH !== undefined ? Number(data.itemH) : Number(rows[i][7]);
      const colI = rows[i][8] || '';
      const colJ = rows[i][9] || '';
      const totalAmount = data.totalAmount !== undefined ? Number(data.totalAmount) : Number(rows[i][10] || 0);
      const timestamp = new Date().toISOString();

      sheet.getRange(rowIndex, 1, 1, 12).setValues([[
        targetSNo, date, fullName, itemD, itemE, itemF, itemG, itemH, colI, colJ, totalAmount, timestamp
      ]]);
      return createJsonResponse({ success: true, message: 'Record updated successfully' });
    }
  }
  return createJsonResponse({ success: false, message: 'Record not found' });
}

function deleteEssentialRow(data) {
  const sheet = getOrCreateEssentialSheet();
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

// ── Cash Gift Sheet Functions ──────────────────────────────────────────────

const CASH_GIFT_SHEET = 'Cash Gift';

function getOrCreateCashGiftSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(CASH_GIFT_SHEET);
  if (!sheet) {
    sheet = ss.insertSheet(CASH_GIFT_SHEET);
    sheet.appendRow([
      'S.No', 'Date', 'Name', 'Amount', 'Mode of Payment', 'Status', 'Remarks', 'Timestamp'
    ]);
    sheet.getRange(1, 1, 1, 8).setFontWeight('bold').setBackground('#059669').setFontColor('#FFFFFF');
  }
  return sheet;
}

function getCashGiftList() {
  const sheet = getOrCreateCashGiftSheet();
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return createJsonResponse({ success: true, data: [] });

  const list = [];
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    if (!row || row[0] === '' || row[0] === null) continue;

    list.push({
      sNo: String(row[0]),
      date: String(row[1] || ''),
      name: String(row[2] || ''),
      amount: Number(row[3] || 0),
      modeOfPayment: String(row[4] || 'Cash'),
      status: String(row[5] || 'Completed'),
      remarks: String(row[6] || ''),
      timestamp: String(row[7] || '')
    });
  }
  return createJsonResponse({ success: true, data: list });
}

function addCashGiftRow(data) {
  const sheet = getOrCreateCashGiftSheet();
  const sNo = data.sNo || String(Math.floor(Date.now() % 1000)).padStart(3, '0');
  const date = data.date || new Date().toISOString();
  const name = data.name || '';
  const amount = Number(data.amount || 0);
  const modeOfPayment = data.modeOfPayment || 'Cash';
  const status = data.status || 'Completed';
  const remarks = data.remarks || '';
  const timestamp = new Date().toISOString();

  sheet.appendRow([sNo, date, name, amount, modeOfPayment, status, remarks, timestamp]);
  return createJsonResponse({ success: true, message: 'Record added successfully', sNo: sNo });
}

function updateCashGiftRow(data) {
  const sheet = getOrCreateCashGiftSheet();
  const rows = sheet.getDataRange().getValues();
  const targetSNo = String(data.sNo);

  for (let i = 1; i < rows.length; i++) {
    if (String(rows[i][0]) === targetSNo) {
      const rowIndex = i + 1;
      const date = data.date !== undefined ? data.date : rows[i][1];
      const name = data.name !== undefined ? data.name : rows[i][2];
      const amount = data.amount !== undefined ? Number(data.amount) : Number(rows[i][3]);
      const modeOfPayment = data.modeOfPayment !== undefined ? data.modeOfPayment : rows[i][4];
      const status = data.status !== undefined ? data.status : rows[i][5];
      const remarks = data.remarks !== undefined ? data.remarks : rows[i][6];
      const timestamp = new Date().toISOString();

      sheet.getRange(rowIndex, 1, 1, 8).setValues([[
        targetSNo, date, name, amount, modeOfPayment, status, remarks, timestamp
      ]]);
      return createJsonResponse({ success: true, message: 'Record updated successfully' });
    }
  }
  return createJsonResponse({ success: false, message: 'Record not found' });
}

function deleteCashGiftRow(data) {
  const sheet = getOrCreateCashGiftSheet();
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

function createJsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
