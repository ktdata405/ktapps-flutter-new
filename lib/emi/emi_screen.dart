import 'package:flutter/material.dart';

import '../cc_emi/cc_emi_models.dart';
import '../cc_emi/cc_emi_report_screen.dart';
import '../cc_emi/cc_emi_screen.dart';
import '../core_constants.dart';
import 'loan_emi_models.dart';
import 'loan_emi_report_screen.dart';
import 'loan_emi_screen.dart';

class EmiScreen extends StatefulWidget {
  const EmiScreen({
    super.key,
    this.report = false,
    this.initialTab = 0,
    this.ccRecord,
    this.loanRecord,
  });

  final bool report;
  final int initialTab;
  final CreditCardEmiRecord? ccRecord;
  final LoanEmiRecord? loanRecord;

  @override
  State<EmiScreen> createState() => _EmiScreenState();
}

class _EmiScreenState extends State<EmiScreen> {
  final _ccReportKey = GlobalKey<CcEmiReportScreenState>();
  final _loanReportKey = GlobalKey<LoanEmiReportScreenState>();

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    initialIndex: widget.loanRecord != null ? 1 : widget.initialTab,
    child: Builder(
      builder:
          (context) => Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(
                widget.report ? KtStrings.emiReportTitle : KtStrings.emiTitle,
              ),
              actions: [
                IconButton(
                  tooltip:
                      widget.report
                          ? KtStrings.expenseTracker
                          : KtStrings.emiReportTitle,
                  icon: Icon(
                    widget.report ? Icons.add_rounded : Icons.bar_chart_rounded,
                    color: ktCcEmiPrimary,
                  ),
                  onPressed: () async {
                    final tab = DefaultTabController.of(context).index;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EmiScreen(
                              report: !widget.report,
                              initialTab: tab,
                            ),
                      ),
                    );
                    if (!mounted || !widget.report) return;
                    if (tab == 0) {
                      await _ccReportKey.currentState?.refreshRecords();
                    } else {
                      await _loanReportKey.currentState?.refreshRecords();
                    }
                  },
                ),
                if (widget.report)
                  IconButton(
                    tooltip: KtStrings.refresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: ktCcEmiPrimary,
                    ),
                    onPressed: () {
                      if (DefaultTabController.of(context).index == 0) {
                        _ccReportKey.currentState?.refreshRecords();
                      } else {
                        _loanReportKey.currentState?.refreshRecords();
                      }
                    },
                  ),
                IconButton(
                  tooltip: KtStrings.home,
                  icon: const Icon(Icons.home_rounded, color: ktCcEmiPrimary),
                  onPressed: () => Navigator.pushNamed(context, '/'),
                ),
              ],
              bottom: const TabBar(
                indicatorColor: ktCcEmiPrimary,
                labelColor: ktCcEmiPrimary,
                tabs: [
                  Tab(text: KtStrings.ccTab),
                  Tab(text: KtStrings.loanTab),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                widget.report
                    ? CcEmiReportScreen(key: _ccReportKey, embedded: true)
                    : CcEmiScreen(editRecord: widget.ccRecord, embedded: true),
                widget.report
                    ? LoanEmiReportScreen(key: _loanReportKey, embedded: true)
                    : LoanEmiScreen(
                      editRecord: widget.loanRecord,
                      embedded: true,
                    ),
              ],
            ),
          ),
    ),
  );
}
