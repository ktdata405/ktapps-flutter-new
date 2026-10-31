# ktppsflutter

Restored Flutter app shell for the rent reports UI.

## Quick start

```zsh
cd "/Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new"
flutter pub get
flutter run -d chrome
```

## Run tests

```zsh
cd "/Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new"
flutter test
```

## EMI: credit cards and installment loans

EMI Entry and EMI Report have **CC** (default) and **Loan** tabs. The CC tab
retains the existing entry, reports, payments and statements. The separate
Loans Given/Taken feature is unchanged. Existing `/credit_card_emi` and
`/report/credit_card_emi` links remain supported; `/emi` and `/report/emi`
are also available.

Both tabs share one title bar without a back arrow or duplicate tab headers.
Entry provides Report and Home actions; Report provides Entry, Refresh and Home
actions. Navigation and refresh target the selected tab. Loan Entry uses the
CC input styling, a live calculation detail card above the single-select,
horizontally scrolling loan-type chips, and no duplicate summary below the form.
Loan labels, validations and repayment calculations are unchanged.
Loan Report uses the same KPI card styling as CC Report, with outstanding
principal, monthly commitment, interest paid and active/total counts at the top.
These totals cover all loans regardless of list filters. Loan tiles display
principal repayment progress and retain their existing detail/payment actions.
Individual loan records follow the CC card layout: a tinted lender/status header,
loan type and account alongside monthly EMI, principal-repaid progress, a
three-column amount/date/outstanding row, and Pay EMI/Details footer actions.
Edit and eligible delete actions are available from Details.

Loan types are Home Loan, Car Loan, Loan Against Securities, Personal Loan,
Gold Loan and Others. Common fields are lender, account number, disbursement
date, first EMI date, principal, annual interest rate, tenure in months,
processing fee and remarks. Additional required fields depend on type:

| Type | Additional fields |
|---|---|
| Home | Property address |
| Car | Vehicle model / registration |
| Securities | Pledged securities, collateral value |
| Personal / Others | Loan purpose |
| Gold | Weight in grams, purity in karat (up to 24), collateral value |

EMIs use a reducing-balance estimate with a zero-interest option. Loan interest
does **not** inherit CC interest GST. Processing fees are entered as the actual
charged amount. Estimates exclude other lender charges, rate changes, and
revolving/interest-only repayment arrangements. Record each payment's actual
principal and interest split from the lender statement; the prefilled split is
only an estimate. Reports derive principal outstanding and completion from
actual principal payments, not the number of payments. Terms are locked after
the first payment; lender/account/remarks remain editable. Loans with payments
cannot be deleted.

### Google Sheets / Apps Script setup (required before using the Loan tab)

1. Back up the **existing CC EMI spreadsheet and Apps Script source**.
2. Use **`lib/emi/emi_app_script.gs`**, the single consolidated file containing
   CC and Loan handlers, including `doGet` and JSON `doPost`. Replace the previous
   EMI source/routers and remove any previously pasted `loan_emi_app_script.gs`
   helpers from the Apps Script project to avoid duplicate declarations. Leave
   unrelated scripts and all spreadsheet data in place.
3. **Before deployment**, compare `EMI_CC_CONFIG` with the existing CC sheet
   names and headers. Defaults are `CC EMI` and `CC EMI Payments`, with the
   columns below. The old deployed CC source was not present in this repository;
   these are new handlers matching the Flutter API, not a copy of that source.
   If your existing sheets have different names or header labels, change the
   configuration values. The mapped header order must match exactly. Extra or
   differently ordered columns require adapting the script before replacement;
   do not rename/delete existing data to force a match. Incorrect sheet names
   would create empty new tabs rather than show your existing records.
4. Update the **existing web app deployment** to a new version, preserving its
   URL and current access settings. Both modules use `CcEmiService.endpoint`;
   do not deploy the loan code to the separate Loans Given/Taken endpoint.
5. Open the Loan report to create the two new sheet tabs automatically. Dates
   use the project format `dd/MMM/yyyy (EEE)` (Dart `dd/MMM/yyyy (E)`), with
   India time. IDs/accounts/dates are stored as text, preserving leading zeros.
   Loan handlers never modify CC sheets. CC handlers write only their configured
   sheets, and CC deletion removes the record and its payment history.

**CC EMI** (default record headers, in order):

```text
id, cardName, merchantName, purchaseDate, totalAmount, interestRate,
tenureMonths, monthlyEmi, processingFee, totalInterest, totalPayable,
emisPaid, dueDay, firstEmiDate, status, category, remarks
```

**CC EMI Payments** (default payment headers, in order):

```text
id, emiRecordId, emiNumber, paymentDate, amountPaid, paymentMode, remarks
```

CC list responses include `repayments`. CC payments update `emisPaid` and mark
the record `Completed` at the final installment. The script retains the CC
EMI/interest/GST totals calculated by the Flutter client, including no-cost EMIs.
Loan responses include `module: "loanEmi"` and preserve the existing loan schema
and calculations. Unsupported actions return errors instead of a default list.

New sheet fields, **in order**, are:

**EMI Loans**

```text
id, loanType, lender, accountNumber, startDate, firstEmiDate,
principal, annualRate, tenureMonths, processingFee,
propertyAddress, vehicle, securities, collateralValue, purpose,
goldWeight, goldPurity, remarks, createdAt, updatedAt
```

`loanType` is one of `home`, `car`, `securities`, `personal`, `gold`, `other`.
Only fields for the selected type are populated. EMI/interest/outstanding/status
are derived rather than manually maintained columns.

**EMI Loan Payments**

```text
id, loanId, paymentDate, principalPaid, interestPaid, amountPaid,
paymentMode, remarks, createdAt
```

`loanId` references `EMI Loans.id`; `amountPaid` is principal plus interest.
Payment modes are Auto Debit, Bank Transfer, UPI, Cash and Other. Timestamps are
ISO strings. Keep headers unchanged: unexpected schemas fail explicitly rather
than overwriting data. Writes are locked and IDs make unchanged retries
idempotent. The script inherits the existing web app's authentication/access
policy; it does not add authentication. Loan data will not be available until
the updated Apps Script version is deployed.

## Deploy to GitHub Pages

This repository includes a workflow at `.github/workflows/deploy-pages.yml` that builds and deploys Flutter web to GitHub Pages.

1. Push your code to the `main` branch.
2. In GitHub, open **Settings -> Pages**.
3. Set **Source** to **GitHub Actions**.
4. Wait for the **Deploy Flutter web to GitHub Pages** workflow to finish.

### Notes

- For a project site (`https://<user>.github.io/<repo>/`), the workflow automatically builds with `--base-href "/<repo>/"`.
- For a user/organization site (`https://<user>.github.io/`), the workflow automatically builds with `--base-href "/"`.
- A `404.html` fallback is generated from `index.html` so deep links work better on GitHub Pages.
