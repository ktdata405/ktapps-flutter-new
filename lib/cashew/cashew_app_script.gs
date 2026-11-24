// Google Apps Script Code for Cashew
// Create a new Google Sheet, go to Extensions > Apps Script, and paste this code.
// Publish > Deploy as web app > Execute as: Me > Who has access: Anyone.
// IMPORTANT: After updating this code, you must create a NEW deployment (Manage Deployments > New Version) for changes to take effect.

var SCHEDULED_SHEET_NAME = 'Scheduled';
var STATUS_COLUMN_INDEX_REGULAR = 6; // Column F (E is reserved for available balance in monthly sheets)
var STATUS_COLUMN_INDEX_SCHEDULED = 6; // Column F

function findHeaderColumnIndex(sheet, headerName) {
  var target = String(headerName || '').trim().toLowerCase();
  if (!target) return 0;
  var lastCol = Math.max(sheet.getLastColumn(), STATUS_COLUMN_INDEX_SCHEDULED);
  var headers = sheet.getRange(1, 1, 1, lastCol).getValues()[0];
  for (var i = 0; i < headers.length; i++) {
    if (String(headers[i] || '').trim().toLowerCase() === target) {
      return i + 1;
    }
  }
  return 0;
}

function ensureHeaderColumn(sheet, preferredColIndex, headerName) {
  var existingIndex = findHeaderColumnIndex(sheet, headerName);
  if (existingIndex > 0) return existingIndex;

  var colIndex = preferredColIndex || sheet.getLastColumn() + 1;
  sheet.getRange(1, colIndex).setValue(headerName);
  sheet.getRange(1, colIndex).setFontWeight('bold').setBackground('#f3f4f6');
  return colIndex;
}

function getSheetColumnMap(sheet, isScheduledSheet) {
  var statusCol = ensureHeaderColumn(
    sheet,
    isScheduledSheet ? STATUS_COLUMN_INDEX_SCHEDULED : STATUS_COLUMN_INDEX_REGULAR,
    'Status'
  );

  var repeatCol = 0;
  if (isScheduledSheet) {
    repeatCol = ensureHeaderColumn(sheet, 5, 'Repeat');
  }

  return {
    statusCol: statusCol,
    repeatCol: repeatCol
  };
}

function ensureSheetWithHeaders(doc, sheetName, includeRepeatColumn) {
  var sheet = doc.getSheetByName(sheetName);
  if (!sheet) {
    sheet = doc.insertSheet(sheetName);
  }

  if (sheet.getLastRow() === 0) {
    if (includeRepeatColumn) {
      var scheduledHeaders = ['Category', 'Description', 'Total Amount', 'Oct 2026', 'Nov 2026', 'Dec 2026'];
      sheet.getRange(1, 1, 1, scheduledHeaders.length).setValues([scheduledHeaders]);
      sheet.getRange(1, 1, 1, scheduledHeaders.length).setFontWeight('bold').setBackground('#D97706').setFontColor('#FFFFFF');
    } else {
      var regularHeaders = ['Date', 'Category', 'Description', 'Amount'];
      sheet.getRange(1, 1, 1, regularHeaders.length).setValues([regularHeaders]);
      sheet.getRange(1, 6).setValue('Status');
      sheet.getRange(1, 1, 1, 4).setFontWeight('bold').setBackground('#f3f4f6');
      sheet.getRange(1, 6).setFontWeight('bold').setBackground('#f3f4f6');
    }
  } else if (includeRepeatColumn) {
    if (sheet.getLastColumn() < 3) {
      var scheduledHeaders = ['Category', 'Description', 'Total Amount', 'Oct 2026', 'Nov 2026', 'Dec 2026'];
      sheet.clear();
      sheet.getRange(1, 1, 1, scheduledHeaders.length).setValues([scheduledHeaders]);
      sheet.getRange(1, 1, 1, scheduledHeaders.length).setFontWeight('bold').setBackground('#D97706').setFontColor('#FFFFFF');
    }
  } else {
    ensureHeaderColumn(sheet, STATUS_COLUMN_INDEX_REGULAR, 'Status');
    if (!String(sheet.getRange(1, 1).getValue() || '').trim()) sheet.getRange(1, 1).setValue('Date');
    if (!String(sheet.getRange(1, 2).getValue() || '').trim()) sheet.getRange(1, 2).setValue('Category');
    if (!String(sheet.getRange(1, 3).getValue() || '').trim()) sheet.getRange(1, 3).setValue('Description');
    if (!String(sheet.getRange(1, 4).getValue() || '').trim()) sheet.getRange(1, 4).setValue('Amount');
  }

  return sheet;
}

function normalizeSheetName(sheetName) {
  var normalized = String(sheetName || '').trim();
  if (!normalized) return '';
  var key = normalized.toLowerCase();
  if (key === 'scheduled' || key === 'scheduled transactions') {
    return SCHEDULED_SHEET_NAME;
  }
  return normalized;
}

function isScheduledPayload(data, expenses) {
  if (data && data.isScheduled === true) return true;
  if (!expenses || !expenses.length) return false;

  for (var i = 0; i < expenses.length; i++) {
    var row = expenses[i] || {};
    var category = String(row.category || '').toLowerCase();
    var description = String(row.description || '').toLowerCase();
    if (category.indexOf('schedule') !== -1 || description.indexOf('repeat:') !== -1) {
      return true;
    }
  }

  return false;
}

function stripScheduledMeta(description) {
  return String(description || '').split('||')[0].trim();
}

function doPost(e) {
  var lock = LockService.getScriptLock();
  lock.tryLock(10000);

  try {
    var doc = SpreadsheetApp.getActiveSpreadsheet();
    var timezone = doc.getSpreadsheetTimeZone();

    var data = JSON.parse(e.postData.contents);

    if (data.type === 'cashew') {
      var requestedSheetName = normalizeSheetName(data.targetSheetName || data.sheetName);
      var isScheduledSheet = requestedSheetName === SCHEDULED_SHEET_NAME;

      // Handle updateMonthStatus action for Scheduled sheet
      if (isScheduledSheet && data.action === 'updateMonthStatus') {
        var sheet = ensureSheetWithHeaders(doc, SCHEDULED_SHEET_NAME, true);
        var rows = sheet.getDataRange().getValues();
        var headers = rows[0];

        var targetCategory = String(data.category || '').trim().toLowerCase();
        var targetDescription = String(data.description || '').trim().toLowerCase();
        var targetMonth = String(data.month || '').trim(); // e.g. "Oct 2026"
        var newStatus = String(data.status || 'Completed').trim();

        var monthColIndex = -1;
        for (var j = 3; j < headers.length; j++) {
          if (String(headers[j]).trim().toLowerCase() === targetMonth.toLowerCase()) {
            monthColIndex = j + 1; // 1-based index
            break;
          }
        }

        if (monthColIndex === -1) {
          var lastCol = sheet.getLastColumn();
          monthColIndex = lastCol + 1;
          sheet.getRange(1, monthColIndex).setValue(targetMonth).setFontWeight('bold').setBackground('#D97706').setFontColor('#FFFFFF');
        }

        for (var i = 1; i < rows.length; i++) {
          var rowCat = String(rows[i][0] || '').trim().toLowerCase();
          var rowDesc = stripScheduledMeta(rows[i][1]).trim().toLowerCase();

          if (rowCat === targetCategory && rowDesc === stripScheduledMeta(data.description).trim().toLowerCase()) {
            sheet.getRange(i + 1, monthColIndex).setValue(newStatus);
            return ContentService.createTextOutput(JSON.stringify({ 'result': 'success', 'message': 'Month status updated' }))
              .setMimeType(ContentService.MimeType.JSON);
          }
        }

        return ContentService.createTextOutput(JSON.stringify({ 'result': 'error', 'message': 'Scheduled item not found' }))
          .setMimeType(ContentService.MimeType.JSON);
      }

      // Handle add action for Scheduled sheet
      if (isScheduledSheet && (data.action === 'add' || data.isScheduled)) {
        var sheet = ensureSheetWithHeaders(doc, SCHEDULED_SHEET_NAME, true);
        var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];

        var category = data.category || (data.expenses && data.expenses[0] ? data.expenses[0].category : '');
        var description = data.description || (data.expenses && data.expenses[0] ? data.expenses[0].description : '');
        var totalAmount = Number(data.totalAmount || (data.expenses && data.expenses[0] ? data.expenses[0].amount : 0));

        var rows = sheet.getDataRange().getValues();
        for (var i = 1; i < rows.length; i++) {
          if (String(rows[i][0]).toLowerCase() === String(category).toLowerCase() &&
              String(rows[i][1]).toLowerCase() === String(description).toLowerCase()) {
            sheet.getRange(i + 1, 3).setValue(totalAmount);
            sheet.getRange(i + 1, 3).setNumberFormat('#,##0.00');
            return ContentService.createTextOutput(JSON.stringify({ 'result': 'success', 'message': 'Scheduled item updated' }))
              .setMimeType(ContentService.MimeType.JSON);
          }
        }

        var newRow = [category, description, totalAmount];
        for (var j = 3; j < headers.length; j++) {
          newRow.push('');
        }
        sheet.appendRow(newRow);
        sheet.getRange(sheet.getLastRow(), 3).setNumberFormat('#,##0.00');
        return ContentService.createTextOutput(JSON.stringify({ 'result': 'success', 'message': 'Scheduled item added' }))
          .setMimeType(ContentService.MimeType.JSON);
      }

      // Regular Cashew / Monthly sheet actions below...
      if (data.action === 'setIncome') {
        var targetSheetName = normalizeSheetName(data.sheetName);
        var sheet = ensureSheetWithHeaders(doc, targetSheetName, false);

        var incomeValue = Number(data.income || 0);
        sheet.getRange("G1").setValue(incomeValue);

        var sheetData = sheet.getDataRange().getValues();
        var totalExpenses = 0;
        for (var i = 1; i < sheetData.length; i++) {
          if (!sheetData[i][1] && !sheetData[i][2] && !sheetData[i][3]) continue;
          var amt = parseFloat(sheetData[i][3]);
          if (!isNaN(amt)) totalExpenses += amt;
        }
        sheet.getRange("G2").setValue(incomeValue - totalExpenses);

        return ContentService.createTextOutput(JSON.stringify({ 'result': 'success', 'message': 'Income updated successfully' }))
          .setMimeType(ContentService.MimeType.JSON);
      }

      var expenses = data.expenses;
      var sheetName = requestedSheetName || 'Cashew';
      if (!requestedSheetName && expenses && expenses.length > 0 && expenses[0].date) {
        var parts = expenses[0].date.split('/');
        if (parts.length === 3) {
          sheetName = parts[1] + ' ' + parts[2];
        }
      }

      var sheet = ensureSheetWithHeaders(doc, sheetName, false);
      var columnMap = getSheetColumnMap(sheet, false);

      var rows = [];
      var lastDate = '';
      for (var i = 0; i < expenses.length; i++) {
        var expense = expenses[i];
        var displayDate = expense.date;
        if (displayDate === lastDate) {
          displayDate = '';
        } else {
          lastDate = displayDate;
        }
        rows.push([
          displayDate,
          expense.category,
          expense.description,
          expense.amount,
          String(expense.status || 'completed').toLowerCase()
        ]);
      }

      if (rows.length > 0) {
        var lastRow = sheet.getLastRow();
        var startRow = lastRow + 1;
        if (lastRow > 1) {
          startRow += 2;
        }

        var baseValues = rows.map(function (r) {
          return [r[0], r[1], r[2], r[3]];
        });
        var statusValues = rows.map(function (r) {
          return [r[4]];
        });

        sheet.getRange(startRow, 1, rows.length, 4).setValues(baseValues);
        sheet.getRange(startRow, columnMap.statusCol, rows.length, 1).setValues(statusValues);
        sheet.getRange(startRow, 4, rows.length, 1).setNumberFormat('#,##0.00');
      }

      var updatedSheetData = sheet.getDataRange().getValues();
      var totalExpensesCount = 0;
      for (var j = 1; j < updatedSheetData.length; j++) {
        if (!updatedSheetData[j][1] && !updatedSheetData[j][2] && !updatedSheetData[j][3]) continue;
        var expenseAmt = parseFloat(updatedSheetData[j][3]);
        if (!isNaN(expenseAmt)) totalExpensesCount += expenseAmt;
      }
      var currentIncomeValue = sheet.getRange("G1").getValue();
      if (typeof currentIncomeValue !== 'number' || isNaN(currentIncomeValue)) {
        currentIncomeValue = parseFloat(currentIncomeValue) || 0;
      }
      sheet.getRange("G2").setValue(currentIncomeValue - totalExpensesCount);

      return ContentService.createTextOutput(JSON.stringify({ 'result': 'success', 'count': rows.length }))
        .setMimeType(ContentService.MimeType.JSON);
    }

    return ContentService.createTextOutput(JSON.stringify({ 'result': 'error', 'message': 'Unknown data type' }))
      .setMimeType(ContentService.MimeType.JSON);

  } catch (e) {
    return ContentService.createTextOutput(JSON.stringify({ 'result': 'error', 'error': e.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  } finally {
    lock.releaseLock();
  }
}

function doGet(e) {
  var lock = LockService.getScriptLock();
  lock.tryLock(10000);

  try {
    var doc = SpreadsheetApp.getActiveSpreadsheet();
    var timezone = doc.getSpreadsheetTimeZone();

    // Check if we need to fetch all data
    if (e.parameter.fetchAll === 'true') {
        var allExpenses = [];
        var totalAvailableBalance = 0;
        var totalIncomeSum = 0;
        var monthlyBalances = {};
        var sheets = doc.getSheets();

        for (var s = 0; s < sheets.length; s++) {
            var sheet = sheets[s];
            var sheetName = sheet.getName();
            var monthlyColumnMap = getSheetColumnMap(sheet, false);

            if (!sheetName.match(/^[A-Z][a-z]{2} \d{4}$/)) {
                continue;
            }

            var data = sheet.getDataRange().getValues();
            var sheetExpenses = 0;
            var lastDate = '';

            for (var i = 1; i < data.length; i++) {
                var row = data[i];
                if (!row[1] && !row[2] && !row[3]) continue;

                var date = row[0];
                if (date) {
                    if (date instanceof Date) {
                        date = Utilities.formatDate(date, timezone, "dd/MMM/yyyy");
                    }
                    lastDate = date;
                } else {
                    date = lastDate;
                }

                var amount = parseFloat(row[3]);
                if (isNaN(amount)) amount = 0;
                sheetExpenses += amount;

                allExpenses.push({
                    date: date,
                    category: row[1],
                    description: row[2],
                    amount: amount,
                    status: String(row[monthlyColumnMap.statusCol - 1] || '').trim().toLowerCase() || 'completed'
                });
            }

            var sheetIncome = sheet.getRange("G1").getValue();
            if (typeof sheetIncome !== 'number' || isNaN(sheetIncome) || sheetIncome === '') {
                sheetIncome = parseFloat(sheetIncome) || 0;
            }

            var sheetBalance = sheetIncome - sheetExpenses;
            sheet.getRange("G2").setValue(sheetBalance);

            totalAvailableBalance += sheetBalance;
            totalIncomeSum += sheetIncome;
            monthlyBalances[sheetName] = sheetBalance;
        }

        return ContentService.createTextOutput(JSON.stringify({
            data: allExpenses,
            availableBalance: totalAvailableBalance,
            monthlyBalances: monthlyBalances,
            totalIncome: totalIncomeSum
        })).setMimeType(ContentService.MimeType.JSON);
    }

    var sheetName = normalizeSheetName(e.parameter.sheetName);

    if (!sheetName) {
      return ContentService.createTextOutput(JSON.stringify({ 'result': 'error', 'message': 'Sheet name is required' }))
        .setMimeType(ContentService.MimeType.JSON);
    }

    var sheet = doc.getSheetByName(sheetName);
    if (!sheet && sheetName === SCHEDULED_SHEET_NAME) {
      sheet = ensureSheetWithHeaders(doc, SCHEDULED_SHEET_NAME, true);
    }
    if (!sheet) {
      return ContentService.createTextOutput(JSON.stringify({ data: [], availableBalance: 0, totalIncome: 0 }))
        .setMimeType(ContentService.MimeType.JSON);
    }

    var isScheduledSheet = sheetName === SCHEDULED_SHEET_NAME;

    if (isScheduledSheet) {
      var rows = sheet.getDataRange().getValues();
      if (rows.length <= 1) return ContentService.createTextOutput(JSON.stringify({ data: [] })).setMimeType(ContentService.MimeType.JSON);

      var headers = rows[0];
      var scheduledList = [];

      for (var i = 1; i < rows.length; i++) {
        var row = rows[i];
        if (!row || row[0] === '' || row[0] === null) continue;

        var item = {
          category: String(row[0] || ''),
          description: String(row[1] || ''),
          totalAmount: Number(row[2] || 0)
        };

        for (var j = 3; j < headers.length; j++) {
          var monthHeader = String(headers[j] || '').trim();
          if (monthHeader) {
            item[monthHeader] = String(row[j] || '');
          }
        }

        scheduledList.push(item);
      }

      return ContentService.createTextOutput(JSON.stringify({ data: scheduledList }))
        .setMimeType(ContentService.MimeType.JSON);
    }

    var data = sheet.getDataRange().getValues();
    var expenses = [];
    var lastDate = '';
    var totalExpenses = 0;
    var monthlyColumnMap = getSheetColumnMap(sheet, false);

    for (var i = 1; i < data.length; i++) {
      var row = data[i];
      if (!row[1] && !row[2] && !row[3]) continue;

      var date = row[0];
      if (date) {
        if (date instanceof Date) {
            date = Utilities.formatDate(date, timezone, "dd/MMM/yyyy");
        }
        lastDate = date;
      } else {
        date = lastDate;
      }

      var amount = parseFloat(row[3]);
      if (isNaN(amount)) amount = 0;
      totalExpenses += amount;

      expenses.push({
        date: date,
        category: row[1],
        description: row[2],
        amount: amount,
        status: String(row[monthlyColumnMap.statusCol - 1] || '').trim().toLowerCase() || 'completed'
      });
    }

    var totalIncome = sheet.getRange("G1").getValue();
    if (typeof totalIncome !== 'number' || isNaN(totalIncome) || totalIncome === '') {
        totalIncome = parseFloat(totalIncome) || 0;
    }

    var availableBalance = totalIncome - totalExpenses;
    sheet.getRange("G2").setValue(availableBalance);

    return ContentService.createTextOutput(JSON.stringify({
        data: expenses,
        availableBalance: availableBalance,
        totalIncome: totalIncome
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (e) {
    return ContentService.createTextOutput(JSON.stringify({ 'result': 'error', 'error': e.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  } finally {
    lock.releaseLock();
  }
}
