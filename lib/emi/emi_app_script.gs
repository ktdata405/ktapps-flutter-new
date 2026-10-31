/**
 * Standalone consolidated CC + Loan EMI web app.
 * Deploy this ONE file in the spreadsheet's bound Apps Script project.
 * Remove previous EMI doGet/doPost handlers and the old loan helper file
 * from that project to avoid duplicate declarations.
 * Before replacing a live CC deployment, back up the spreadsheet and verify
 * EMI_CC_CONFIG sheet names and header mappings against its existing schema.
 * Existing schema mismatches fail without overwriting data.
 */
const LOAN_EMI_HEADERS = [
  'id', 'loanType', 'lender', 'accountNumber', 'startDate', 'firstEmiDate',
  'principal', 'annualRate', 'tenureMonths', 'processingFee',
  'propertyAddress', 'vehicle', 'securities', 'collateralValue', 'purpose',
  'goldWeight', 'goldPurity', 'remarks', 'createdAt', 'updatedAt'
];
const LOAN_EMI_PAYMENT_HEADERS = [
  'id', 'loanId', 'paymentDate', 'principalPaid', 'interestPaid', 'amountPaid',
  'paymentMode', 'remarks', 'createdAt'
];
const LOAN_EMI_TYPES = {
  home: ['propertyAddress'],
  car: ['vehicle'],
  securities: ['securities', 'collateralValue'],
  personal: ['purpose'],
  gold: ['goldWeight', 'goldPurity', 'collateralValue'],
  other: ['purpose']
};
const LOAN_EMI_ACTIONS = [
  'listLoanEmis', 'addLoanEmi', 'updateLoanEmi', 'deleteLoanEmi',
  'recordLoanEmiPayment'
];

function handleLoanEmiRequest(params) {
  if (LOAN_EMI_ACTIONS.indexOf(params.action) === -1) return null;
  let lock;
  try {
    lock = LockService.getScriptLock();
    lock.waitLock(30000);
    const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
    const loans = loanEmiSheet_(spreadsheet, 'EMI Loans', LOAN_EMI_HEADERS);
    const payments = loanEmiSheet_(spreadsheet, 'EMI Loan Payments', LOAN_EMI_PAYMENT_HEADERS);
    const loanRows = loanEmiRows_(loans, LOAN_EMI_HEADERS);
    const paymentRows = loanEmiRows_(payments, LOAN_EMI_PAYMENT_HEADERS);
    let result;
    switch (params.action) {
      case 'listLoanEmis':
        result = loanRows.map(loan => {
          const history = paymentRows.filter(payment => payment.loanId === loan.id);
          const principalPaid = history.reduce((sum, payment) => sum + Number(payment.principalPaid), 0);
          const rate = Number(loan.annualRate) / 1200;
          const factor = Math.pow(1 + rate, Number(loan.tenureMonths));
          const monthlyEmi = rate === 0 || factor === 1 ? loan.principal / loan.tenureMonths
            : loan.principal * rate * factor / (factor - 1);
          return Object.assign({}, loan, {
            payments: history,
            monthlyEmi: monthlyEmi,
            totalInterest: Math.max(0, monthlyEmi * loan.tenureMonths - loan.principal),
            outstanding: Math.max(0, loan.principal - principalPaid),
            status: loan.principal - principalPaid <= 0.005 ? 'Completed' : 'Active'
          });
        });
        break;
      case 'addLoanEmi':
      case 'updateLoanEmi':
        result = loanEmiSave_(loans, loanRows, paymentRows, params);
        break;
      case 'deleteLoanEmi': {
        const loan = loanEmiFind_(loanRows, params.id);
        if (paymentRows.some(payment => payment.loanId === loan.id)) {
          throw new Error('Loans with payments cannot be deleted');
        }
        loans.deleteRow(loanRows.indexOf(loan) + 2);
        result = { id: loan.id };
        break;
      }
      case 'recordLoanEmiPayment':
        result = loanEmiPay_(payments, loanRows, paymentRows, params);
        break;
      default:
        throw new Error('Unsupported loan EMI action');
    }
    return loanEmiJson_({ success: true, data: result });
  } catch (error) {
    console.error('Loan EMI request failed: ' + error.message);
    return loanEmiJson_({ success: false, error: error.message });
  } finally {
    if (lock && lock.hasLock()) lock.releaseLock();
  }
}

function loanEmiJson_(data) {
  data.module = 'loanEmi';
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

function loanEmiSheet_(spreadsheet, name, headers) {
  let sheet = spreadsheet.getSheetByName(name);
  if (!sheet) sheet = spreadsheet.insertSheet(name);
  if (sheet.getLastRow() === 0) {
    sheet.appendRow(headers);
    sheet.getRange(1, 1, 1, headers.length)
      .setFontWeight('bold').setBackground('#8B5CF6').setFontColor('#FFFFFF');
    sheet.setFrozenRows(1);
  } else {
    if (sheet.getLastColumn() !== headers.length) {
      throw new Error('Unexpected column count in ' + name + '; no data was modified');
    }
    const existing = sheet.getRange(1, 1, 1, headers.length).getValues()[0];
    if (headers.some((header, index) => header !== existing[index])) {
      throw new Error('Unexpected headers in ' + name + '; no data was modified');
    }
  }
  return sheet;
}

function loanEmiRows_(sheet, headers) {
  if (sheet.getLastRow() <= 1) return [];
  return sheet.getRange(2, 1, sheet.getLastRow() - 1, headers.length).getValues()
    .map(row => {
      const result = {};
      headers.forEach((header, index) => {
        let value = row[index];
        if (value instanceof Date) {
          value = Utilities.formatDate(value, 'Asia/Kolkata', 'dd/MMM/yyyy (EEE)');
        }
        // IDs and accounts are always text, including manually entered cells.
        if (['id', 'loanId', 'accountNumber'].indexOf(header) !== -1) value = String(value);
        result[header] = value;
      });
      return result;
    });
}

function loanEmiText_(value, field, required) {
  const text = String(value === undefined || value === null ? '' : value).trim();
  if (required && !text) throw new Error(field + ' is required');
  if (text.length > 2000) throw new Error(field + ' is too long');
  return text;
}

function loanEmiNumber_(value, field, positive) {
  if (value === undefined || value === null || String(value).trim() === '') {
    throw new Error(field + ' is required');
  }
  const number = Number(value);
  if (!Number.isFinite(number) || number < 0 || (positive && number === 0)) {
    throw new Error('Invalid ' + field);
  }
  return number;
}

function loanEmiMoney_(value, field, positive) {
  const number = loanEmiNumber_(value, field, positive);
  const rounded = Math.round(number * 100) / 100;
  if (!Number.isFinite(rounded) || number > Number.MAX_SAFE_INTEGER / 100) {
    throw new Error(field + ' exceeds supported precision');
  }
  if (positive && rounded <= 0) throw new Error('Invalid ' + field);
  return rounded;
}

function loanEmiDate_(value, field) {
  const text = loanEmiText_(value, field, true);
  if (!/^\d{2}\/[A-Z][a-z]{2}\/\d{4} \([A-Z][a-z]{2}\)$/.test(text)) {
    throw new Error('Invalid ' + field + '; expected dd/MMM/yyyy (EEE)');
  }
  const base = text.slice(0, 11);
  const date = Utilities.parseDate(base, 'Asia/Kolkata', 'dd/MMM/yyyy');
  if (Utilities.formatDate(date, 'Asia/Kolkata', 'dd/MMM/yyyy (EEE)') !== text) {
    throw new Error('Invalid calendar date in ' + field);
  }
  return { text: text, date: date };
}

function loanEmiFind_(rows, id) {
  const key = loanEmiText_(id, 'id', true);
  const record = rows.find(row => row.id === key);
  if (!record) throw new Error('Loan not found');
  return record;
}

function loanEmiWrite_(sheet, row, headers, record) {
  const values = headers.map(header => {
    const value = record[header] === undefined ? '' : record[header];
    // Prevent user text from becoming a spreadsheet formula.
    return typeof value === 'string' && /^[=+@-]/.test(value) ? "'" + value : value;
  });
  const range = sheet.getRange(row, 1, 1, headers.length);
  range.setNumberFormat('@');
  range.setValues([values]);
  SpreadsheetApp.flush();
}

function loanEmiSave_(sheet, loans, payments, params) {
  const id = loanEmiText_(params.id, 'id', true);
  const loanType = loanEmiText_(params.loanType, 'loanType', true);
  if (!Object.prototype.hasOwnProperty.call(LOAN_EMI_TYPES, loanType)) {
    throw new Error('Invalid loan type');
  }
  const start = loanEmiDate_(params.startDate, 'startDate');
  const first = loanEmiDate_(params.firstEmiDate, 'firstEmiDate');
  if (first.date < start.date) throw new Error('First EMI precedes disbursement');
  const tenure = loanEmiNumber_(params.tenureMonths, 'tenureMonths', true);
  if (!Number.isInteger(tenure) || tenure > 600) throw new Error('Tenure must be 1 to 600 months');
  const rate = loanEmiNumber_(params.annualRate, 'annualRate', false);
  if (!Number.isFinite(Math.pow(1 + rate / 1200, tenure))) throw new Error('Interest rate is too large');
  const record = {
    id: id, loanType: loanType,
    lender: loanEmiText_(params.lender, 'lender', true),
    accountNumber: loanEmiText_(params.accountNumber, 'accountNumber', true),
    startDate: start.text, firstEmiDate: first.text,
    principal: loanEmiMoney_(params.principal, 'principal', true),
    annualRate: rate, tenureMonths: tenure,
    processingFee: loanEmiMoney_(params.processingFee, 'processingFee', false),
    remarks: loanEmiText_(params.remarks, 'remarks', false)
  };
  LOAN_EMI_TYPES[loanType].forEach(field => {
    if (['collateralValue', 'goldWeight', 'goldPurity'].indexOf(field) !== -1) {
      record[field] = loanEmiNumber_(params[field], field, true);
      if (field === 'goldPurity' && record[field] > 24) throw new Error('Gold purity exceeds 24');
    } else {
      record[field] = loanEmiText_(params[field], field, true);
    }
  });
  const existing = loans.find(loan => loan.id === id);
  if (params.action === 'addLoanEmi' && existing) {
    const identical = LOAN_EMI_HEADERS.filter(header =>
      ['createdAt', 'updatedAt'].indexOf(header) === -1)
      .every(header => String(existing[header] || '') === String(record[header] || ''));
    if (!identical) throw new Error('Loan id already exists with different data');
    return { id: id }; // A retry must not create a duplicate.
  }
  if (params.action === 'updateLoanEmi') {
    if (!existing) throw new Error('Loan not found');
    if (payments.some(payment => payment.loanId === id)) {
      const locked = LOAN_EMI_HEADERS.filter(header =>
        ['lender', 'accountNumber', 'remarks', 'createdAt', 'updatedAt'].indexOf(header) === -1);
      if (locked.some(header => String(existing[header] || '') !== String(record[header] || ''))) {
        throw new Error('Loan terms cannot change after a payment');
      }
    }
  }
  const now = new Date().toISOString();
  record.createdAt = existing ? existing.createdAt : now;
  record.updatedAt = now;
  loanEmiWrite_(sheet, existing ? loans.indexOf(existing) + 2 : sheet.getLastRow() + 1,
    LOAN_EMI_HEADERS, record);
  return { id: id };
}

function loanEmiPay_(sheet, loans, payments, params) {
  const loan = loanEmiFind_(loans, params.loanId);
  const date = loanEmiDate_(params.paymentDate, 'paymentDate');
  if (date.date < loanEmiDate_(loan.startDate, 'startDate').date) {
    throw new Error('Payment precedes disbursement');
  }
  const principal = loanEmiMoney_(params.principalPaid, 'principalPaid', true);
  const interest = loanEmiMoney_(params.interestPaid, 'interestPaid', false);
  const record = {
    id: loanEmiText_(params.id, 'id', true), loanId: loan.id,
    paymentDate: date.text, principalPaid: principal, interestPaid: interest,
    amountPaid: Math.round((principal + interest) * 100) / 100,
    paymentMode: loanEmiText_(params.paymentMode, 'paymentMode', true),
    remarks: loanEmiText_(params.remarks, 'remarks', false)
  };
  if (['Auto Debit', 'Bank Transfer', 'UPI', 'Cash', 'Other'].indexOf(record.paymentMode) === -1) {
    throw new Error('Invalid payment mode');
  }
  const existing = payments.find(payment => payment.id === record.id);
  if (existing) {
    if (LOAN_EMI_PAYMENT_HEADERS.filter(header => header !== 'createdAt')
        .some(header => String(existing[header]) !== String(record[header]))) {
      throw new Error('Payment id already exists with different data');
    }
    return { id: record.id };
  }

  const paid = payments.filter(payment => payment.loanId === loan.id)
    .reduce((sum, payment) => sum + Number(payment.principalPaid), 0);
  if (principal > Number(loan.principal) - paid + 0.005) {
    throw new Error('Principal payment exceeds outstanding balance');
  }
  record.createdAt = new Date().toISOString();
  loanEmiWrite_(sheet, sheet.getLastRow() + 1, LOAN_EMI_PAYMENT_HEADERS, record);
  return { id: record.id };
}

// Values are sheet column labels; keys are the Flutter API field names.
// Change values here if your existing CC sheet uses different labels.
const EMI_CC_CONFIG = {
  recordsSheet: 'CC EMI',
  paymentsSheet: 'CC EMI Payments',
  records: {
    id: 'id', cardName: 'cardName', merchantName: 'merchantName',
    purchaseDate: 'purchaseDate', totalAmount: 'totalAmount',
    interestRate: 'interestRate', tenureMonths: 'tenureMonths',
    monthlyEmi: 'monthlyEmi', processingFee: 'processingFee',
    totalInterest: 'totalInterest', totalPayable: 'totalPayable',
    emisPaid: 'emisPaid', dueDay: 'dueDay', firstEmiDate: 'firstEmiDate',
    status: 'status', category: 'category', remarks: 'remarks'
  },
  payments: {
    id: 'id', emiRecordId: 'emiRecordId', emiNumber: 'emiNumber',
    paymentDate: 'paymentDate', amountPaid: 'amountPaid',
    paymentMode: 'paymentMode', remarks: 'remarks'
  }
};

function doGet(e) {
  return emiDispatch_((e && e.parameter) || {});
}

function doPost(e) {
  try {
    const params = e && e.postData && e.postData.contents
      ? JSON.parse(e.postData.contents) : ((e && e.parameter) || {});
    return emiDispatch_(params);
  } catch (error) {
    console.error('EMI POST failed: ' + error.message);
    return emiJson_({ success: false, error: error.message });
  }
}

function emiDispatch_(params) {
  const loan = handleLoanEmiRequest(params);
  if (loan !== null) return loan;
  return handleCcEmiRequest_(params);
}

function emiJson_(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

function ccEmiSheet_(spreadsheet, name, mapping) {
  return loanEmiSheet_(spreadsheet, name, Object.keys(mapping).map(key => mapping[key]));
}

function ccEmiRows_(sheet, mapping) {
  const keys = Object.keys(mapping);
  return loanEmiRows_(sheet, keys.map(key => mapping[key])).map(row => {
    const record = {};
    keys.forEach(key => { record[key] = row[mapping[key]]; });
    ['id', 'emiRecordId'].forEach(key => {
      if (key in record) record[key] = String(record[key]);
    });
    return record;
  });
}

function ccEmiWrite_(sheet, row, mapping, record) {
  const mapped = {};
  Object.keys(mapping).forEach(key => { mapped[mapping[key]] = record[key]; });
  loanEmiWrite_(sheet, row, Object.keys(mapping).map(key => mapping[key]), mapped);
}

function handleCcEmiRequest_(params) {
  const action = params.action || 'list';
  const actions = ['list', 'addCcEmi', 'updateCcEmi', 'deleteCcEmi', 'recordPayment'];
  if (actions.indexOf(action) === -1) {
    return emiJson_({ success: false, error: 'Unsupported EMI action: ' + action });
  }
  let lock;
  try {
    lock = LockService.getScriptLock();
    lock.waitLock(30000);
    const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
    const config = EMI_CC_CONFIG;
    const recordsSheet = ccEmiSheet_(spreadsheet, config.recordsSheet, config.records);
    const paymentsSheet = ccEmiSheet_(spreadsheet, config.paymentsSheet, config.payments);
    const records = ccEmiRows_(recordsSheet, config.records);
    const payments = ccEmiRows_(paymentsSheet, config.payments);
    let result;
    if (action === 'list') {
      result = records.map(record => Object.assign({}, record, {
        repayments: payments.filter(payment => payment.emiRecordId === record.id)
      }));
    } else if (action === 'addCcEmi' || action === 'updateCcEmi') {
      result = ccEmiSave_(recordsSheet, records, params);
    } else if (action === 'deleteCcEmi') {
      const record = loanEmiFind_(records, params.id);
      // Preserve the existing CC delete flow, including removing its history.
      for (let index = payments.length - 1; index >= 0; index--) {
        if (payments[index].emiRecordId === record.id) paymentsSheet.deleteRow(index + 2);
      }
      recordsSheet.deleteRow(records.indexOf(record) + 2);
      result = { id: record.id };
    } else {
      result = ccEmiPay_(recordsSheet, paymentsSheet, records, payments, params);
    }
    return emiJson_({ success: true, data: result });
  } catch (error) {
    console.error('CC EMI request failed: ' + error.message);
    return emiJson_({ success: false, error: error.message });
  } finally {
    if (lock && lock.hasLock()) lock.releaseLock();
  }
}

function ccEmiInteger_(value, field, min, max) {
  const number = loanEmiNumber_(value, field, false);
  if (!Number.isInteger(number) || number < min || number > max) {
    throw new Error('Invalid ' + field);
  }
  return number;
}

function ccEmiSave_(sheet, records, params) {
  const record = {
    id: loanEmiText_(params.id, 'id', true),
    cardName: loanEmiText_(params.cardName, 'cardName', true),
    merchantName: loanEmiText_(params.merchantName, 'merchantName', true),
    purchaseDate: loanEmiDate_(params.purchaseDate, 'purchaseDate').text,
    firstEmiDate: loanEmiDate_(params.firstEmiDate, 'firstEmiDate').text,
    totalAmount: loanEmiMoney_(params.totalAmount, 'totalAmount', true),
    interestRate: loanEmiNumber_(params.interestRate, 'interestRate', false),
    tenureMonths: ccEmiInteger_(params.tenureMonths, 'tenureMonths', 1, 600),
    monthlyEmi: loanEmiNumber_(params.monthlyEmi, 'monthlyEmi', true),
    processingFee: loanEmiMoney_(params.processingFee, 'processingFee', false),
    totalInterest: loanEmiNumber_(params.totalInterest, 'totalInterest', false),
    totalPayable: loanEmiNumber_(params.totalPayable, 'totalPayable', true),
    dueDay: ccEmiInteger_(params.dueDay, 'dueDay', 1, 31),
    category: loanEmiText_(params.category, 'category', true),
    remarks: loanEmiText_(params.remarks, 'remarks', false)
  };
  const existing = records.find(item => item.id === record.id);
  record.emisPaid = existing ? Number(existing.emisPaid)
    : ccEmiInteger_(params.emisPaid, 'emisPaid', 0, record.tenureMonths);
  if (record.emisPaid > record.tenureMonths) throw new Error('Tenure is less than EMIs already paid');
  record.status = loanEmiText_(params.status, 'status', true);
  if (['Active', 'Completed', 'Closed'].indexOf(record.status) === -1) {
    throw new Error('Invalid CC EMI status');
  }
  if (record.emisPaid >= record.tenureMonths) record.status = 'Completed';
  else if (record.status === 'Completed') record.status = 'Active';
  if (params.action === 'addCcEmi' && existing) {
    if (Object.keys(EMI_CC_CONFIG.records).some(key =>
      String(existing[key]) !== String(record[key]))) {
      throw new Error('CC EMI id already exists with different data');
    }
    return { id: record.id };
  }
  if (params.action === 'updateCcEmi' && !existing) throw new Error('CC EMI not found');
  ccEmiWrite_(sheet, existing ? records.indexOf(existing) + 2 : sheet.getLastRow() + 1,
    EMI_CC_CONFIG.records, record);
  return { id: record.id };
}

function ccEmiPay_(recordsSheet, paymentsSheet, records, payments, params) {
  const record = loanEmiFind_(records, params.emiRecordId);
  const payment = {
    id: loanEmiText_(params.id, 'id', true), emiRecordId: record.id,
    emiNumber: ccEmiInteger_(params.emiNumber, 'emiNumber', 1, Number(record.tenureMonths)),
    paymentDate: loanEmiDate_(params.paymentDate, 'paymentDate').text,
    amountPaid: loanEmiMoney_(params.amountPaid, 'amountPaid', true),
    paymentMode: loanEmiText_(params.paymentMode, 'paymentMode', true),
    remarks: loanEmiText_(params.remarks, 'remarks', false)
  };
  const existing = payments.find(item => item.id === payment.id);
  if (existing) {
    if (Object.keys(EMI_CC_CONFIG.payments).some(key =>
      String(existing[key]) !== String(payment[key]))) {
      throw new Error('CC payment id already exists with different data');
    }
    // Repair a count update if an earlier request wrote its payment but failed
    // before updating the parent record.
  } else {
    if (record.status !== 'Active') throw new Error('CC EMI is not active');
    if (payment.emiNumber !== Number(record.emisPaid) + 1 ||
        payments.some(item => item.emiRecordId === record.id &&
          Number(item.emiNumber) === payment.emiNumber)) {
      throw new Error('CC EMI installment already paid or out of sequence');
    }
    ccEmiWrite_(paymentsSheet, paymentsSheet.getLastRow() + 1, EMI_CC_CONFIG.payments, payment);
  }
  record.emisPaid = Math.max(Number(record.emisPaid), payment.emiNumber);
  if (record.emisPaid >= Number(record.tenureMonths)) record.status = 'Completed';
  ccEmiWrite_(recordsSheet, records.indexOf(record) + 2, EMI_CC_CONFIG.records, record);
  return { id: payment.id };
}
