/**
 * Google Apps Script for Distribution Essential Management
 * Sheet Name: "Essential Items for Delivery"
 * Total Amount is read & written directly from Column K (Row 2 onwards).
 */

const SHEET_NAME = 'Essential Items for Delivery';

function doGet(e) {
  try {
    const action = (e && e.parameter && e.parameter.action) ? e.parameter.action : 'list';
    if (action === 'list') return getEssentialList();
    if (action === 'add') return addEssentialRow(e.parameter);
    if (action === 'update') return updateEssentialRow(e.parameter);
    if (action === 'delete') return deleteEssentialRow(e.parameter);
    return getEssentialList();
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
    if (action === 'list') return getEssentialList();
    if (action === 'add') return addEssentialRow(contents);
    if (action === 'update') return updateEssentialRow(contents);
    if (action === 'delete') return deleteEssentialRow(contents);
    return addEssentialRow(contents);
  } catch (error) {
    return createJsonResponse({ success: false, error: error.toString() });
  }
}

function getOrCreateSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(SHEET_NAME);
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_NAME);
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
  const sheet = getOrCreateSheet();
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return createJsonResponse({ success: true, data: [] });

  const list = [];
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    if (!row || row[0] === '' || row[0] === null) continue;

    // Column K is row[10] (0-indexed: 0=A, 1=B, 2=C, 3=D, 4=E, 5=F, 6=G, 7=H, 8=I, 9=J, 10=K)
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
  const sheet = getOrCreateSheet();
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
  const totalAmount = Number(data.totalAmount || 0); // Directly Column K
  const timestamp = new Date().toISOString();

  sheet.appendRow([sNo, date, fullName, itemD, itemE, itemF, itemG, itemH, colI, colJ, totalAmount, timestamp]);
  return createJsonResponse({ success: true, message: 'Record added successfully', sNo: sNo });
}

function updateEssentialRow(data) {
  const sheet = getOrCreateSheet();
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
  const sheet = getOrCreateSheet();
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
