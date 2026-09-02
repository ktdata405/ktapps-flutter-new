import 'dart:convert';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'cashew_constants.dart';
import 'cashew_report_screen.dart';

class _ImportRow {
  _ImportRow({
    required this.entryId,
    required this.date,
    required this.tag,
    required this.remarks,
    required this.manualEntry,
    required this.amount,
    required this.isIncoming,
    this.category = '',
  });

  final String entryId;
  String date;
  String tag;
  String remarks;
  String manualEntry;
  double amount;
  bool isIncoming;
  String category;
}

class _DateFieldErrors {
  final Set<String> category = <String>{};
  final Set<String> amount = <String>{};
  final Set<String> remarks = <String>{};

  bool get hasAny => category.isNotEmpty || amount.isNotEmpty || remarks.isNotEmpty;
}

class CashewImportScreen extends StatefulWidget {
  const CashewImportScreen({super.key});

  @override
  State<CashewImportScreen> createState() => _CashewImportScreenState();
}

class _CashewImportScreenState extends State<CashewImportScreen> {
  Map<String, List<_ImportRow>> _entriesByDate = <String, List<_ImportRow>>{};
  final Set<String> _savedDates = <String>{};
  final Set<String> _failedDates = <String>{};
  final Set<String> _checkedDates = <String>{};
  final Map<String, _DateFieldErrors> _fieldErrorsByDate = <String, _DateFieldErrors>{};

  String _selectedDate = '';
  String _dateCategoryChoice = '';
  bool _isLoading = false;
  String _loadingText = 'Processing...';
  String _fileName = '-';
  final ScrollController _dateChipScrollController = ScrollController();

  List<String> get _sortedDates {
    final dates = _entriesByDate.keys.toList();
    dates.sort((a, b) {
      final da = _parseDDMMMYYYY(a) ?? DateTime.tryParse(a) ?? DateTime(1970);
      final db = _parseDDMMMYYYY(b) ?? DateTime.tryParse(b) ?? DateTime(1970);
      return da.compareTo(db);
    });
    return dates;
  }

  @override
  void dispose() {
    _dateChipScrollController.dispose();
    super.dispose();
  }

  void _scrollDateChipsByPage(int direction) {
    if (!_dateChipScrollController.hasClients) return;
    final position = _dateChipScrollController.position;
    final step = position.viewportDimension * 0.9;
    final target = (position.pixels + (step * direction))
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    _dateChipScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollDateChipsWithPointer(PointerSignalEvent signal) {
    if (signal is! PointerScrollEvent || !_dateChipScrollController.hasClients) return;
    final position = _dateChipScrollController.position;
    final delta = signal.scrollDelta.dx == 0 ? signal.scrollDelta.dy : signal.scrollDelta.dx;
    final target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    _dateChipScrollController.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: cashewBgDark,
        colorScheme: const ColorScheme.dark(
          primary: cashewPrimary,
          secondary: cashewTextGray400,
          surface: Color(0xFF111827),
        ),
        fontFamily: 'Plus Jakarta Sans',
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF141B2E),
          elevation: 0,
          titleSpacing: 8,
          title: Row(
            children: const [
              CircleAvatar(
                radius: 20,
                backgroundColor: cashewPrimary,
                child: Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 18),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cashew', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cashewTextWhite)),
                  Text('Import Excel', style: TextStyle(fontSize: 11, color: cashewTextGray400, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          actions: [
            _topIcon(Icons.upload_file_rounded, _pickFileAndImport, active: true),
            _topIcon(
              Icons.pie_chart_outline_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CashewReportScreen()),
              ),
            ),
            _topIcon(Icons.account_balance_wallet_outlined, () => Navigator.pop(context)),
            _topIcon(Icons.home_rounded, () => Navigator.popUntil(context, (route) => route.isFirst)),
            _topIcon(Icons.description_outlined, _showSheetLinkDialog),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Pick file',
              onPressed: _pickFileAndImport,
              icon: const Icon(Icons.file_open_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            if (_entriesByDate.isEmpty) _buildUploadSection() else _buildPreviewSection(),
            if (_isLoading) _buildLoader(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    final currentRows = _entriesByDate[_selectedDate] ?? <_ImportRow>[];
    final currentTotal = currentRows.fold<double>(0, (s, r) => s + r.amount);
    final grandTotal = _entriesByDate.values
        .expand((e) => e)
        .fold<double>(0, (s, r) => s + r.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Column(
        children: [
          _buildToolbar(),
          const SizedBox(height: 12),
          SizedBox(height: 128, child: _buildDateList(grandTotal)),
          const SizedBox(height: 12),
          Expanded(child: _buildPreviewTable(currentRows, currentTotal)),
        ],
      ),
    );
  }

  Widget _buildPreviewTable(List<_ImportRow> currentRows, double currentTotal) {
    return Container(
      decoration: BoxDecoration(
        color: cashewCardBg.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          _buildDateTopBar(currentRows.length, currentTotal),
          _buildTableHeader(),
          Expanded(
            child: currentRows.isEmpty
                ? const Center(
                    child: Text('No data for selected date', style: TextStyle(color: cashewTextGray400)),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: currentRows.length,
                    itemBuilder: (context, index) => _buildRowCard(currentRows[index], index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 760),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cashewCardBg.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(colors: [cashewEmerald, cashewPrimary]),
                ),
                child: const Icon(Icons.file_upload_outlined, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('Import Transactions', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cashewTextWhite)),
              const SizedBox(height: 8),
              const Text(
                'Upload .xlsx / .xls file and review by date before saving.',
                style: TextStyle(color: cashewTextGray400),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _pickFileAndImport,
                style: FilledButton.styleFrom(
                  backgroundColor: cashewPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: const Text('Choose Excel File'),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cashewSlate800.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EXPECTED COLUMNS',
                        style: TextStyle(
                            fontSize: 11,
                            color: cashewTextGray400,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text('Date · Amount · Transaction Details · Remarks',
                        style: TextStyle(color: cashewTextWhite, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Target Sheet: Passbook Payment History',
                        style: TextStyle(color: cashewTextGray400, fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _topIcon(IconData icon, VoidCallback onTap, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: active ? cashewEmerald.withValues(alpha: 0.18) : Colors.transparent,
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          ),
          child: Icon(icon, size: 18, color: active ? cashewEmerald : cashewTextWhite),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cashewCardBg.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cashewSlate800.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.description_outlined, size: 14, color: cashewTextGray400),
              const SizedBox(width: 8),
              const Text('LOADED FILE', style: TextStyle(fontSize: 10, color: cashewTextGray400, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: cashewTextWhite),
                ),
              ),
            ]),
          ),
          _toolbarBtn(Icons.autorenew, 'New File', _resetImport),
          _toolbarBtn(Icons.layers, 'Club Category', _selectedDate.isEmpty ? null : () => _clubSameCategory(_selectedDate)),
          _toolbarBtn(Icons.filter_alt, 'Remove Incoming', _removeIncomingRows, tint: cashewRose),
          _toolbarBtn(Icons.add, 'Add Row', _selectedDate.isEmpty ? null : _addManualRow, tint: const Color(0xFF38BDF8)),
          _toolbarBtn(Icons.calendar_month, 'Save Date', _selectedDate.isEmpty ? null : _saveSelectedDate, tint: const Color(0xFFA78BFA)),
          _toolbarBtn(Icons.check_box, 'Save Checked', _checkedDates.isEmpty ? null : _saveCheckedDates,
              trailing: '${_checkedDates.length}', tint: const Color(0xFFA78BFA)),
          _toolbarBtn(Icons.save, 'Save All', _entriesByDate.isEmpty ? null : _saveAllDates, tint: cashewEmerald),
        ],
      ),
    );
  }

  Widget _toolbarBtn(IconData icon, String label, VoidCallback? onTap,
      {String trailing = '', Color tint = cashewTextGray400}) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: disabled ? Colors.white.withValues(alpha: 0.03) : tint.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: disabled ? Colors.white.withValues(alpha: 0.09) : tint.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: disabled ? cashewTextGray400 : tint),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: disabled ? cashewTextGray400 : cashewTextWhite)),
          if (trailing.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: cashewPrimary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: cashewPrimary.withValues(alpha: 0.5)),
              ),
              child: Text(trailing, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
            )
          ],
        ]),
      ),
    );
  }

  Widget _buildDateList(double grandTotal) {
    final dates = _sortedDates;
    const metaColor = Color(0xFFCBD5E1);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A2238).withValues(alpha: 0.9),
            cashewCardBg.withValues(alpha: 0.92),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x335A6E95)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0x223B82F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x553B82F6)),
                  ),
                  child: const Icon(Icons.date_range_rounded, size: 14, color: Color(0xFFBFDBFE)),
                ),
                const SizedBox(width: 8),
                const Text('DATES', style: TextStyle(fontSize: 11, color: cashewTextWhite, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x223B82F6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x553B82F6)),
                  ),
                  child: Text('${dates.length} dates', style: const TextStyle(fontSize: 10, color: Color(0xFFBFDBFE), fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x2210B981),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x5534D399)),
                  ),
                  child: Text('₹${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: Color(0xFF86EFAC), fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                _dateNavBtn(Icons.chevron_left_rounded, () => _scrollDateChipsByPage(-1)),
                const SizedBox(width: 4),
                _dateNavBtn(Icons.chevron_right_rounded, () => _scrollDateChipsByPage(1)),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.24),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Expanded(
            child: dates.isEmpty
                ? const Center(
                    child: Text('No dates parsed yet', style: TextStyle(color: cashewTextGray400)),
                  )
                : Listener(
                    onPointerSignal: _scrollDateChipsWithPointer,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                          PointerDeviceKind.stylus,
                          PointerDeviceKind.invertedStylus,
                          PointerDeviceKind.unknown,
                        },
                      ),
                      child: Scrollbar(
                        controller: _dateChipScrollController,
                        thumbVisibility: true,
                        interactive: true,
                        child: ListView.separated(
                          controller: _dateChipScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          itemCount: dates.length,
                          separatorBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                                const SizedBox(width: 2),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final date = dates[index];
                            final rows = _entriesByDate[date] ?? <_ImportRow>[];
                            final total = rows.fold<double>(0, (s, r) => s + r.amount);
                            final selected = date == _selectedDate;
                            final checked = _checkedDates.contains(date);
                            final parsed = _parseDDMMMYYYY(date);
                            final day = parsed == null
                                ? ''
                                : const ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'][parsed.weekday % 7];

                            final isSunday = parsed != null && parsed.weekday == DateTime.sunday;
                            final isSaved = _savedDates.contains(date);
                            final isFailed = _failedDates.contains(date);

                            Color border = const Color(0x33475A81);
                            Color bg = const Color(0x1A151D33);
                            Color titleColor = cashewTextWhite;
                            if (isFailed) {
                              border = const Color(0x66FB7185);
                              bg = const Color(0x22FB7185);
                              titleColor = const Color(0xFFFDA4AF);
                            } else if (isSaved) {
                              border = const Color(0x6634D399);
                              bg = const Color(0x2234D399);
                              titleColor = const Color(0xFF6EE7B7);
                            } else if (isSunday) {
                              border = const Color(0x66F87171);
                              bg = const Color(0x22F87171);
                              titleColor = const Color(0xFFFCA5A5);
                            }
                            if (selected) {
                              border = const Color(0xAA6366F1);
                              bg = const Color(0x446366F1);
                            }

                            return InkWell(
                              onTap: () => setState(() {
                                _selectedDate = date;
                                _dateCategoryChoice = '';
                              }),
                              borderRadius: BorderRadius.circular(999),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 168,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: selected
                                        ? [bg.withValues(alpha: 0.98), const Color(0x553B82F6)]
                                        : [bg.withValues(alpha: 0.98), const Color(0x18151D33)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: border, width: selected ? 1.6 : 1.1),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0x663B82F6),
                                            blurRadius: 14,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(color: titleColor, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  date,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: titleColor),
                                                ),
                                              ),
                                              if (isSaved || isFailed || isSunday)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isFailed
                                                        ? const Color(0x33FB7185)
                                                        : isSaved
                                                            ? const Color(0x3310B981)
                                                            : const Color(0x33EF4444),
                                                    borderRadius: BorderRadius.circular(999),
                                                    border: Border.all(color: border.withValues(alpha: 0.9)),
                                                  ),
                                                  child: Text(
                                                    isFailed ? 'FAILED' : isSaved ? 'SAVED' : 'SUN',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.w900,
                                                      letterSpacing: 0.2,
                                                      color: titleColor,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            '$day  ·  ${rows.length} row${rows.length == 1 ? '' : 's'}  ·  ₹${total.toStringAsFixed(0)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 10, color: metaColor, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      width: 1,
                                      height: 24,
                                      color: Colors.white.withValues(alpha: 0.18),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (checked) {
                                            _checkedDates.remove(date);
                                          } else {
                                            _checkedDates.add(date);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(999),
                                      child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Icon(
                                          checked ? Icons.check_circle : Icons.radio_button_unchecked,
                                          size: 15,
                                          color: checked ? cashewEmerald : cashewTextGray400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dateNavBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0x223B82F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x553B82F6)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFFBFDBFE)),
      ),
    );
  }

  Widget _buildDateTopBar(int rowCount, double currentTotal) {
    final d = _selectedDate.isEmpty ? null : _parseDDMMMYYYY(_selectedDate);
    final sunday = d != null && d.weekday == DateTime.sunday;
    final saved = _savedDates.contains(_selectedDate);
    final compact = MediaQuery.of(context).size.width < 1024;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cashewPrimary.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today, size: 15, color: cashewTextWhite),
            const SizedBox(width: 10),
            Text(
              _selectedDate.isEmpty ? 'No Date' : _selectedDate,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: compact ? 18 : 24),
            ),
          ]),
          if (sunday)
            _pill('Sunday', const Color(0xFFFCA5A5), const Color(0x33EF4444), const Color(0x88EF4444)),
          if (saved)
            _pill('Saved', const Color(0xFF6EE7B7), const Color(0x3310B981), const Color(0x8810B981)),
          if (_failedDates.contains(_selectedDate))
            _pill('Failed', const Color(0xFFFDA4AF), const Color(0x33FB7185), const Color(0x88FB7185)),
          const Text('APPLY CATEGORY', style: TextStyle(fontSize: 10, color: cashewTextWhite, fontWeight: FontWeight.w800)),
          SizedBox(
            width: compact ? 220 : 180,
            height: 36,
            child: DropdownButtonFormField<String>(
              value: _dateCategoryChoice.isEmpty ? null : _dateCategoryChoice,
              hint: const Text('Apply for date...', style: TextStyle(fontSize: 13, color: cashewTextGray400)),
              dropdownColor: cashewCardBg,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
              ),
              items: cashewCategories
                  .where((e) => e != 'Select Category')
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v == null || _selectedDate.isEmpty) return;
                setState(() {
                  _dateCategoryChoice = v;
                  final rows = _entriesByDate[_selectedDate] ?? <_ImportRow>[];
                  for (final row in rows) {
                    row.category = v;
                  }
                });
                _clubSameCategory(_selectedDate, showMessage: false);
              },
            ),
          ),
          Text(
            '$rowCount rows',
            style: TextStyle(fontSize: compact ? 15 : 18, color: cashewTextWhite, fontWeight: FontWeight.w700),
          ),
          Text(
            '₹${currentTotal.toStringAsFixed(2)}',
            style: TextStyle(fontSize: compact ? 20 : 24, color: cashewTextWhite, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x3323344F),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text('TRANSACTION DETAILS',
                style: TextStyle(fontSize: 15, color: cashewTextWhite, fontWeight: FontWeight.w800)),
          ),
          Text('ACTIONS', style: TextStyle(fontSize: 15, color: cashewTextWhite, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildRowCard(_ImportRow row, int index) {
    final dateErrors = _fieldErrorsByDate[_selectedDate];
    final hasCategoryErr = dateErrors?.category.contains(row.entryId) ?? false;
    final hasAmountErr = dateErrors?.amount.contains(row.entryId) ?? false;
    final hasRemarksErr = dateErrors?.remarks.contains(row.entryId) ?? false;

    final rowBg = index.isEven ? const Color(0x0C6366F1) : const Color(0x03151D33);
    final isCompact = MediaQuery.of(context).size.width < 980;

    return Container(
      key: ValueKey(row.entryId),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: isCompact
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildRowFields(row, hasCategoryErr, hasAmountErr, hasRemarksErr, compact: true),
              const SizedBox(height: 10),
              Row(children: [
                _actionIcon(Icons.copy, const Color(0xFFF59E0B), () => _duplicateRow(row.entryId)),
                const SizedBox(width: 8),
                _actionIcon(Icons.call_split, const Color(0xFF38BDF8), () => _splitRow(row.entryId)),
                const SizedBox(width: 8),
                _actionIcon(Icons.delete_outline, const Color(0xFFFB7185), () => _deleteRow(row.entryId)),
              ]),
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: _buildRowFields(row, hasCategoryErr, hasAmountErr, hasRemarksErr, compact: false),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 42,
                child: Column(children: [
                  _actionIcon(Icons.copy, const Color(0xFFF59E0B), () => _duplicateRow(row.entryId)),
                  const SizedBox(height: 8),
                  _actionIcon(Icons.call_split, const Color(0xFF38BDF8), () => _splitRow(row.entryId)),
                  const SizedBox(height: 8),
                  _actionIcon(Icons.delete_outline, const Color(0xFFFB7185), () => _deleteRow(row.entryId)),
                ]),
              ),
            ]),
    );
  }

  Widget _buildRowFields(
    _ImportRow row,
    bool hasCategoryErr,
    bool hasAmountErr,
    bool hasRemarksErr, {
    required bool compact,
  }) {
    final categoryField = _fieldLabel('CATEGORY', DropdownButtonFormField<String>(
      value: row.category.isEmpty ? 'Select Category' : row.category,
      dropdownColor: cashewCardBg,
      decoration: _fieldDecoration(hasCategoryErr, green: false),
      items: cashewCategories
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) {
        row.category = (v == null || v == 'Select Category') ? '' : v;
        _clearFieldError(_selectedDate, row.entryId, 'category');
        if (_selectedDate.isEmpty) {
          setState(() {});
          return;
        }
        _clubSameCategory(_selectedDate, showMessage: false);
      },
    ));

    final detailsField = _fieldLabel(
      'TRANSACTION DETAILS',
      TextFormField(
        key: ValueKey('tx-${row.entryId}-${row.manualEntry}'),
        initialValue: row.manualEntry,
        style: const TextStyle(color: Color(0xFF7DD3FC), fontWeight: FontWeight.w700),
        decoration: _fieldDecoration(false, sky: true),
        onChanged: (v) => row.manualEntry = v,
      ),
    );

    final amountField = _fieldLabel(
      'AMOUNT (₹)',
      TextFormField(
        key: ValueKey('amt-${row.entryId}-${row.amount.toStringAsFixed(2)}'),
        initialValue: row.amount.toStringAsFixed(2),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.w800, fontFamily: 'monospace'),
        decoration: _fieldDecoration(hasAmountErr, green: true),
        onChanged: (v) {
          row.amount = double.tryParse(v) ?? 0;
          _clearFieldError(_selectedDate, row.entryId, 'amount');
          setState(() {});
        },
      ),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (compact) ...[
        categoryField,
        const SizedBox(height: 10),
        detailsField,
        const SizedBox(height: 10),
        amountField,
      ] else
        Row(children: [
          Expanded(child: categoryField),
          const SizedBox(width: 10),
          Expanded(child: detailsField),
          const SizedBox(width: 10),
          SizedBox(width: 270, child: amountField),
        ]),
      const SizedBox(height: 10),
      _fieldLabel(
          'REMARK — AMOUNT',
          TextFormField(
            key: ValueKey('rmk-${row.entryId}'),
            initialValue: row.remarks,
            style: const TextStyle(color: Color(0xFFFDE68A), fontWeight: FontWeight.w700),
            decoration: _fieldDecoration(hasRemarksErr, amber: true),
            onChanged: (v) {
              row.remarks = v;
              final parsed = _parseAmountFromRemarkText(v);
              if (parsed != null && parsed >= 0) {
                row.amount = double.parse(parsed.toStringAsFixed(2));
              }
              _clearFieldError(_selectedDate, row.entryId, 'remarks');
              _clearFieldError(_selectedDate, row.entryId, 'amount');
              setState(() {});
            },
          )),
      if (_getSpecialTagNote(row).isNotEmpty) ...[
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0x33F59E0B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x66F59E0B)),
            ),
            child: Text(
              _getSpecialTagNote(row),
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFFCD34D),
                  fontWeight: FontWeight.w700),
            ),
          ),
        )
      ]
    ]);
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _fieldLabel(String text, Widget child) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(text,
          style: const TextStyle(
              fontSize: 10, color: cashewTextWhite, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      child,
    ]);
  }

  InputDecoration _fieldDecoration(bool isError,
      {bool green = false, bool amber = false, bool sky = false}) {
    Color border = Colors.white.withValues(alpha: 0.22);
    Color fill = Colors.black.withValues(alpha: 0.22);
    if (green) {
      border = const Color(0x6610B981);
      fill = const Color(0x33065F46);
    } else if (amber) {
      border = const Color(0x66FACC15);
      fill = const Color(0x33783F10);
    } else if (sky) {
      border = const Color(0x660EA5E9);
      fill = const Color(0x33075985);
    }
    if (isError) {
      border = const Color(0xCCFB7185);
      fill = const Color(0x407F1D1D);
    }
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      errorText: isError ? ' ' : null,
      errorStyle: const TextStyle(height: 0, fontSize: 0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
    );
  }

  Widget _buildLoader() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: cashewCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(strokeWidth: 3, color: cashewEmerald),
              ),
              const SizedBox(height: 12),
              Text(_loadingText, style: const TextStyle(fontWeight: FontWeight.w700, color: cashewTextWhite)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFileAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    setState(() {
      _isLoading = true;
      _loadingText = 'Importing Excel Data';
      _fileName = result.files.first.name;
    });

    await Future<void>.delayed(Duration.zero);

    try {
      final parsed = await compute(_parseCashewImportAnyFile, <String, dynamic>{
        'bytes': bytes,
        'fileName': result.files.first.name,
      });
      if (!mounted) return;
      final rows = (parsed['rows'] as List)
          .cast<Map<String, dynamic>>()
          .map(_fromMap)
          .toList();
      final skippedDate = (parsed['skippedDate'] as num? ?? 0).toInt();
      final skippedAmt = (parsed['skippedAmt'] as num? ?? 0).toInt();
      final skippedSelf = (parsed['skippedSelf'] as num? ?? 0).toInt();

      if ((parsed['noSheets'] as bool?) ?? false) {
        _showInfo('Import Error', 'No sheets found in uploaded workbook.');
        return;
      }

      if (rows.isEmpty) {
        _showInfo('Import Error',
            'No valid rows found. Date: $skippedDate, Amount: $skippedAmt, Self: $skippedSelf');
        return;
      }

      final grouped = <String, List<_ImportRow>>{};
      for (final row in rows) {
        grouped.putIfAbsent(row.date, () => <_ImportRow>[]).add(row);
      }

      setState(() {
        _entriesByDate = grouped;
        _selectedDate = _sortedDates.isNotEmpty ? _sortedDates.first : '';
        _dateCategoryChoice = '';
        _savedDates.clear();
        _failedDates.clear();
        _checkedDates.clear();
        _fieldErrorsByDate.clear();
      });
    } catch (e) {
      _showInfo('Import Error', 'Could not parse file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetImport() {
    setState(() {
      _entriesByDate = <String, List<_ImportRow>>{};
      _selectedDate = '';
      _dateCategoryChoice = '';
      _savedDates.clear();
      _failedDates.clear();
      _checkedDates.clear();
      _fieldErrorsByDate.clear();
      _fileName = '-';
    });
  }

  void _removeIncomingRows() {
    int removed = 0;
    final next = <String, List<_ImportRow>>{};
    _entriesByDate.forEach((date, rows) {
      final kept = rows.where((r) => !_isIncomingOrCtt(r)).toList();
      removed += (rows.length - kept.length);
      if (kept.isNotEmpty) next[date] = kept;
    });

    setState(() {
      _entriesByDate = next;
      _checkedDates.removeWhere((d) => !_entriesByDate.containsKey(d));
      if (!_entriesByDate.containsKey(_selectedDate)) {
        _selectedDate = _sortedDates.isEmpty ? '' : _sortedDates.first;
      }
    });

    _showInfo('Rows Removed', 'Removed $removed incoming/CTT rows');
  }

  void _addManualRow() {
    if (_selectedDate.isEmpty) return;
    setState(() {
      _entriesByDate[_selectedDate]!.add(_ImportRow(
        entryId: _newEntryId('manual'),
        date: _selectedDate,
        tag: 'Manual',
        remarks: '',
        manualEntry: '',
        amount: 0,
        isIncoming: false,
      ));
    });
  }

  void _duplicateRow(String entryId) {
    final rows = _entriesByDate[_selectedDate];
    if (rows == null) return;
    final idx = rows.indexWhere((r) => r.entryId == entryId);
    if (idx == -1) return;
    final src = rows[idx];
    setState(() {
      rows.insert(
        idx + 1,
        _ImportRow(
          entryId: _newEntryId('dup'),
          date: src.date,
          tag: src.tag,
          remarks: src.remarks,
          manualEntry: src.manualEntry,
          amount: src.amount,
          isIncoming: src.isIncoming,
          category: src.category,
        ),
      );
    });
  }

  void _splitRow(String entryId) {
    final rows = _entriesByDate[_selectedDate];
    if (rows == null) return;
    final idx = rows.indexWhere((r) => r.entryId == entryId);
    if (idx == -1) return;
    final src = rows[idx];
    if (src.amount <= 0) {
      _showInfo('Cannot Split', 'Amount should be greater than 0');
      return;
    }
    final first = double.parse((src.amount / 2).toStringAsFixed(2));
    final second = double.parse((src.amount - first).toStringAsFixed(2));
    setState(() {
      src.amount = first;
      rows.insert(
        idx + 1,
        _ImportRow(
          entryId: _newEntryId('split'),
          date: src.date,
          tag: src.tag,
          remarks: src.remarks,
          manualEntry: src.manualEntry,
          amount: second,
          isIncoming: src.isIncoming,
          category: src.category,
        ),
      );
    });
  }

  void _deleteRow(String entryId) {
    final rows = _entriesByDate[_selectedDate];
    if (rows == null) return;
    setState(() {
      rows.removeWhere((r) => r.entryId == entryId);
      if (rows.isEmpty) {
        _entriesByDate.remove(_selectedDate);
        _checkedDates.remove(_selectedDate);
        _selectedDate = _sortedDates.isEmpty ? '' : _sortedDates.first;
      }
    });
  }

  void _clubSameCategory(String date, {bool showMessage = true}) {
    final rows = _entriesByDate[date];
    if (rows == null) return;

    final grouped = <String, List<_ImportRow>>{};
    for (final row in rows) {
      final key = row.category.trim().toLowerCase();
      if (key.isEmpty || key == 'select') continue;
      grouped.putIfAbsent(key, () => <_ImportRow>[]).add(row);
    }

    int removed = 0;
    final mergedByKey = <String, _ImportRow>{};
    grouped.forEach((key, list) {
      if (list.length == 1) {
        mergedByKey[key] = list.first;
        return;
      }
      removed += (list.length - 1);
      final base = list.first;
      final amount = list.fold<double>(0, (s, r) => s + r.amount);
      final remarks = list
          .map((r) => r.remarks.trim())
          .where((e) => e.isNotEmpty)
          .join(', ');
      final txDetails = list
          .map((r) => r.manualEntry.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .join(', ');
      final tags = list
          .map((r) => r.tag.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .join(', ');
      base.amount = double.parse(amount.toStringAsFixed(2));
      base.remarks = remarks;
      if (txDetails.isNotEmpty) {
        base.manualEntry = txDetails;
      }
      base.tag = tags;
      mergedByKey[key] = base;
    });

    final seen = <String>{};
    final rebuilt = <_ImportRow>[];
    for (final row in rows) {
      final key = row.category.trim().toLowerCase();
      if (key.isEmpty || key == 'select') {
        rebuilt.add(row);
        continue;
      }
      if (seen.contains(key)) continue;
      seen.add(key);
      rebuilt.add(mergedByKey[key] ?? row);
    }

    setState(() {
      _entriesByDate[date] = rebuilt;
      _fieldErrorsByDate.remove(date);
    });
    if (showMessage) {
      _showInfo('Club Category', removed > 0 ? 'Merged $removed duplicate rows' : 'No duplicates found');
    }
  }

  Future<void> _saveSelectedDate() async {
    if (_selectedDate.isEmpty) return;
    final ok = _validateDate(_selectedDate);
    if (!ok) {
      _showInfo('Validation Error', _validationSummaryMessage(<String>[_selectedDate]));
      return;
    }
    await _saveDates(<String>[_selectedDate]);
  }

  Future<void> _saveCheckedDates() async {
    final dates = _sortedDates.where(_checkedDates.contains).toList();
    if (dates.isEmpty) {
      _showInfo('No Dates Selected', 'Check one or more dates and try again');
      return;
    }
    if (!_validateDates(dates)) {
      _showInfo('Validation Error', _validationSummaryMessage(dates));
      return;
    }
    await _saveDates(dates);
  }

  Future<void> _saveAllDates() async {
    final dates = _sortedDates;
    if (dates.isEmpty) return;
    if (!_validateDates(dates)) {
      _showInfo('Validation Error', _validationSummaryMessage(dates));
      return;
    }
    await _saveDates(dates);
  }

  Future<void> _saveDates(List<String> dates) async {
    setState(() {
      _isLoading = true;
      _loadingText = 'Saving data...';
    });

    int savedDates = 0;
    int savedRows = 0;
    String inProgressDate = '';

    try {
      for (int i = 0; i < dates.length; i++) {
        final date = dates[i];
        inProgressDate = date;
        final payload = _buildPayloadForDate(date);
        if ((payload['expenses'] as List).isEmpty) continue;

        setState(() => _loadingText = 'Saving $date (${i + 1}/${dates.length})');

        final res = await http.post(
          Uri.parse(cashewSheetUrl),
          body: jsonEncode(payload),
        );
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw Exception('Save failed for $date (HTTP ${res.statusCode})');
        }

        _failedDates.remove(date);
        _savedDates.add(date);
        savedDates++;
        savedRows += (payload['expenses'] as List).length;
      }

      _showInfo('Saved', 'Saved $savedRows rows across $savedDates date(s)');
    } catch (e) {
      if (inProgressDate.isNotEmpty) _failedDates.add(inProgressDate);
      _showInfo('Save Error', '$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _validationSummaryMessage(List<String> dates) {
    int cat = 0;
    int amt = 0;
    int rem = 0;
    for (final d in dates) {
      final errs = _fieldErrorsByDate[d];
      if (errs == null) continue;
      cat += errs.category.length;
      amt += errs.amount.length;
      rem += errs.remarks.length;
    }
    final parts = <String>[];
    if (cat > 0) parts.add('Category missing: $cat');
    if (amt > 0) parts.add('Invalid amount: $amt');
    if (rem > 0) parts.add('Remark missing: $rem');
    return parts.isEmpty ? 'Fix highlighted rows before saving.' : parts.join(', ');
  }

  bool _validateDates(List<String> dates) {
    bool ok = true;
    for (final date in dates) {
      ok = _validateDate(date) && ok;
    }
    if (!ok && _selectedDate.isEmpty && dates.isNotEmpty) {
      _selectedDate = dates.first;
    }
    setState(() {});
    return ok;
  }

  bool _validateDate(String date) {
    final rows = _entriesByDate[date] ?? <_ImportRow>[];
    final errs = _DateFieldErrors();

    for (final row in rows) {
      final category = row.category.trim().toLowerCase();
      if (category.isEmpty || category == 'select') errs.category.add(row.entryId);
      if (row.amount <= 0) errs.amount.add(row.entryId);
      if (row.remarks.trim().isEmpty) errs.remarks.add(row.entryId);
    }

    if (errs.hasAny) {
      _fieldErrorsByDate[date] = errs;
      return false;
    }

    _fieldErrorsByDate.remove(date);
    return true;
  }

  void _clearFieldError(String date, String entryId, String key) {
    final errs = _fieldErrorsByDate[date];
    if (errs == null) return;
    switch (key) {
      case 'category':
        errs.category.remove(entryId);
      case 'amount':
        errs.amount.remove(entryId);
      case 'remarks':
        errs.remarks.remove(entryId);
    }
    if (!errs.hasAny) _fieldErrorsByDate.remove(date);
  }

  Map<String, dynamic> _buildPayloadForDate(String date) {
    final rows = _entriesByDate[date] ?? <_ImportRow>[];
    final validRows = rows
        .where((r) => r.amount > 0 && r.category.trim().isNotEmpty && r.category.toLowerCase() != 'select')
        .map((r) => {
              'date': date,
              'category': r.category.trim(),
              'description': r.remarks.trim().isEmpty ? r.manualEntry.trim() : r.remarks.trim(),
              'amount': r.amount,
            })
        .toList();

    final byCategory = <String, Map<String, dynamic>>{};
    for (final row in validRows) {
      final key = (row['category'] as String).toLowerCase();
      final bucket = byCategory.putIfAbsent(key, () {
        return {
          'date': row['date'],
          'category': row['category'],
          'amount': 0.0,
          'descriptions': <String>[],
        };
      });
      bucket['amount'] = (bucket['amount'] as double) + (row['amount'] as double);
      (bucket['descriptions'] as List<String>).add(row['description'] as String);
    }

    final expenses = byCategory.values.map((item) {
      final descs = (item['descriptions'] as List<String>).toSet().toList();
      return {
        'date': item['date'],
        'category': item['category'],
        'description': descs.join(', '),
        'amount': double.parse((item['amount'] as double).toStringAsFixed(2)),
      };
    }).toList();

    final total = expenses.fold<double>(0, (s, e) => s + (e['amount'] as double));

    return {
      'type': 'cashew',
      'expenses': expenses,
      'total': total,
      'isEdit': true,
      'action': 'update',
      'originalDate': date,
    };
  }

  bool _isIncomingOrCtt(_ImportRow row) {
    if (row.isIncoming) return true;
    final text = '${row.tag} ${row.remarks}'.toLowerCase();
    const incomingTokens = ['received', 'credit', 'cr', 'incoming', 'refund', 'reversal', 'deposit'];
    if (incomingTokens.any(text.contains)) return true;
    return RegExp(r'\bctt\b', caseSensitive: false).hasMatch(text);
  }

  DateTime? _parseDDMMMYYYY(String value) {
    final m = RegExp(r'^(\d{2})/(\w{3})/(\d{4})$').firstMatch(value.trim());
    if (m == null) return null;
    const mm = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return DateTime(
      int.parse(m.group(3)!),
      mm[m.group(2)!.toLowerCase()] ?? 1,
      int.parse(m.group(1)!),
    );
  }

  String _newEntryId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${UniqueKey().hashCode}';

  _ImportRow _fromMap(Map<String, dynamic> m) {
    return _ImportRow(
      entryId: (m['entryId'] ?? '').toString(),
      date: (m['date'] ?? '').toString(),
      tag: (m['tag'] ?? '').toString(),
      remarks: (m['remarks'] ?? '').toString(),
      manualEntry: (m['manualEntry'] ?? '').toString(),
      amount: ((m['amount'] as num?) ?? 0).toDouble(),
      isIncoming: (m['isIncoming'] as bool?) ?? false,
      category: (m['category'] ?? '').toString(),
    );
  }

  void _showInfo(String title, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$title: $msg')));
  }

  String _getSpecialTagNote(_ImportRow row) {
    final text = '${row.tag} ${row.remarks}'.trim();
    if (RegExp(r'self\s*transfer', caseSensitive: false).hasMatch(text)) {
      return 'self transfer';
    }
    if (RegExp(r'\bctt\b', caseSensitive: false).hasMatch(text)) {
      return 'ctt';
    }
    return '';
  }

  double? _parseAmountFromRemarkText(String value) {
    final m = RegExp(r'-\s*([0-9]+(?:\.[0-9]+)?)\s*$').firstMatch(value.trim());
    if (m != null) return double.tryParse(m.group(1)!);

    final legacy = RegExp(r'-Amount\(\s*([0-9]+(?:\.[0-9]+)?)\s*\)\s*$', caseSensitive: false)
        .firstMatch(value.trim());
    if (legacy != null) return double.tryParse(legacy.group(1)!);
    return null;
  }

  void _showSheetLinkDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cashewCardBg,
        title: const Text('Google Sheet Link', style: TextStyle(color: cashewTextWhite)),
        content: const SelectableText(cashewSheetUrl, style: TextStyle(color: cashewTextGray400)),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: cashewSheetUrl));
              if (mounted) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                _showInfo('Copied', 'Sheet URL copied');
              }
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _parseCashewImportAnyFile(Map<String, dynamic> input) {
  final bytes = input['bytes'] as Uint8List;
  final fileName = (input['fileName'] ?? '').toString().toLowerCase();
  if (fileName.endsWith('.csv')) {
    return _parseCashewImportCsv(bytes);
  }
  return _parseCashewImportFile(bytes);
}

Map<String, dynamic> _parseCashewImportCsv(Uint8List bytes) {
  final content = utf8.decode(bytes, allowMalformed: true);
  final lineList = const LineSplitter().convert(content);
  final matrix = <List<String>>[];
  for (final line in lineList) {
    if (line.trim().isEmpty) continue;
    matrix.add(_parseCsvLine(line));
  }

  final rowMaps = _csvToSmartRows(matrix);

  final allRows = <Map<String, dynamic>>[];
  int skippedSelf = 0;
  int skippedDate = 0;
  int skippedAmt = 0;
  int counter = 0;

  for (final row in rowMaps) {
    final rawTag = _getCellByAliases(row, const ['tags', 'tag', 'category label']);
    final normTag = rawTag.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (normTag == 'self' || normTag == 'self transfer') {
      skippedSelf++;
      continue;
    }

    final dateRaw = _getCellByAliases(
      row,
      const ['date', 'transaction date', 'txn date', 'entry date', 'value date', 'posting date'],
    );
    final date = _parseDateFromUnknown(dateRaw) ?? _fallbackDateFromRow(row);
    if (date == null) {
      skippedDate++;
      continue;
    }

    final amountInfo = _resolveAmount(row);
    if (amountInfo == null || amountInfo.$1 <= 0) {
      skippedAmt++;
      continue;
    }

    final details = _getCellByAliases(row, const [
      'transaction details', 'transaction detail', 'transaction description', 'txn details', 'txn detail', 'details', 'description', 'narration',
    ]);
    final remarkOnly = _getCellByAliases(row, const ['remarks', 'remark']);
    final tag = rawTag.trim();
    final tx = details.trim().isNotEmpty
        ? details.trim()
        : (remarkOnly.trim().isNotEmpty ? remarkOnly.trim() : (tag.isNotEmpty ? tag : 'Imported'));
    final remarkBase = remarkOnly.trim().isNotEmpty
        ? remarkOnly.trim()
        : (details.trim().isNotEmpty ? details.trim() : (tag.isNotEmpty ? tag : 'Imported'));

    allRows.add({
      'entryId': 'csv-${counter++}',
      'date': _fmtDDMMMYYYY(date),
      'tag': tag,
      'remarks': '${remarkBase.trim()}-${_fmtAmount(amountInfo.$1)}',
      'manualEntry': tx,
      'amount': amountInfo.$1,
      'isIncoming': amountInfo.$2,
      'category': '',
    });
  }

  return {
    'rows': allRows,
    'skippedSelf': skippedSelf,
    'skippedDate': skippedDate,
    'skippedAmt': skippedAmt,
    'noSheets': false,
  };
}

List<String> _parseCsvLine(String line) {
  final out = <String>[];
  final buf = StringBuffer();
  bool inQuotes = false;

  for (int i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        buf.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch == ',' && !inQuotes) {
      out.add(buf.toString().trim());
      buf.clear();
    } else {
      buf.write(ch);
    }
  }
  out.add(buf.toString().trim());
  return out;
}

List<Map<String, dynamic>> _csvToSmartRows(List<List<String>> rows) {
  if (rows.isEmpty) return <Map<String, dynamic>>[];

  const dateAliases = ['date', 'transaction date', 'txn date', 'entry date', 'value date', 'posting date'];
  const amountAliases = [
    'debit', 'debit amount', 'debit amt', 'withdrawal', 'withdrawals', 'dr', 'paid out',
    'amount', 'txn amount', 'transaction amount', 'amt', 'value',
    'credit', 'credit amount', 'deposit', 'deposits', 'cr', 'paid in', 'received', 'incoming'
  ];

  int bestHeader = 0;
  int bestScore = -1;
  final scan = rows.length < 12 ? rows.length : 12;

  for (int r = 0; r < scan; r++) {
    final map = <String, int>{};
    for (int c = 0; c < rows[r].length; c++) {
      final n = _norm(rows[r][c]);
      if (n.isNotEmpty) map[n] = c;
    }

    bool hasAlias(List<String> aliases) {
      for (final a in aliases) {
        final na = _norm(a);
        for (final k in map.keys) {
          if (k == na || k.contains(na) || na.contains(k)) return true;
        }
      }
      return false;
    }

    final score = (hasAlias(dateAliases) ? 1 : 0) + (hasAlias(amountAliases) ? 1 : 0);
    final nonEmpty = rows[r].where((c) => c.trim().isNotEmpty).length;
    final weighted = score * 100 + nonEmpty;

    if (weighted > bestScore) {
      bestScore = weighted;
      bestHeader = r;
    }
    if (score == 2) break;
  }

  final headers = <String>[];
  final seen = <String, int>{};
  for (int c = 0; c < rows[bestHeader].length; c++) {
    final base = rows[bestHeader][c].trim();
    final clean = base.isEmpty ? 'Column${c + 1}' : base;
    final n = seen[clean] ?? 0;
    seen[clean] = n + 1;
    headers.add(n == 0 ? clean : '${clean}_${n + 1}');
  }

  final out = <Map<String, dynamic>>[];
  for (int r = bestHeader + 1; r < rows.length; r++) {
    final row = rows[r];
    final hasData = row.any((c) => c.trim().isNotEmpty);
    if (!hasData) continue;

    final width = headers.length > row.length ? headers.length : row.length;
    final map = <String, dynamic>{};
    for (int c = 0; c < width; c++) {
      final key = c < headers.length ? headers[c] : 'Column${c + 1}';
      final value = c < row.length ? row[c] : '';
      map[key] = value;
    }
    out.add(map);
  }
  return out;
}

Map<String, dynamic> _parseCashewImportFile(Uint8List bytes) {
  final excel = Excel.decodeBytes(bytes);
  final allRows = <Map<String, dynamic>>[];
  int skippedSelf = 0;
  int skippedDate = 0;
  int skippedAmt = 0;
  int counter = 0;

  if (excel.tables.isEmpty) {
    return {
      'rows': allRows,
      'skippedSelf': skippedSelf,
      'skippedDate': skippedDate,
      'skippedAmt': skippedAmt,
      'noSheets': true,
    };
  }

  const targetSheetName = "Passbook Payment History";
  final sheetNames = excel.tables.keys.toList();
  bool foundTarget = false;
  for (final name in sheetNames) {
    if (name.trim() == targetSheetName) {
      foundTarget = true;
      break;
    }
  }

  final sheetsToProcess = foundTarget ? [targetSheetName] : sheetNames;

  for (final sheetName in sheetsToProcess) {
    final sheet = excel.tables[sheetName]!;
    final rowMaps = _sheetToSmartRows(sheet.rows);

    for (final row in rowMaps) {
      final rawTag = _getCellByAliases(row, const ['tags', 'tag', 'category label']);
      final normTag = _norm(rawTag);
      if (normTag == 'self' || normTag == 'selftransfer') {
        skippedSelf++;
        continue;
      }

      final dateRaw = _getCellByAliases(
        row,
        const ['date', 'transaction date', 'txn date', 'entry date', 'value date', 'posting date'],
      );
      final date = _parseDateFromUnknown(dateRaw) ?? _fallbackDateFromRow(row);
      if (date == null) {
        skippedDate++;
        continue;
      }

      final amountInfo = _resolveAmount(row);
      if (amountInfo == null || amountInfo.$1 <= 0) {
        skippedAmt++;
        continue;
      }

      final details = _getCellByAliases(row, const [
        'transaction details', 'transaction detail', 'transaction description', 'txn details', 'txn detail', 'details', 'description', 'narration',
      ]);
      final remarkOnly = _getCellByAliases(row, const ['remarks', 'remark']);

      final tag = rawTag.trim();
      final tx = details.trim().isNotEmpty
          ? details.trim()
          : (remarkOnly.trim().isNotEmpty ? remarkOnly.trim() : (tag.isNotEmpty ? tag : 'Imported'));
      final remarkBase = remarkOnly.trim().isNotEmpty
          ? remarkOnly.trim()
          : (details.trim().isNotEmpty ? details.trim() : (tag.isNotEmpty ? tag : 'Imported'));

      allRows.add({
        'entryId': '$sheetName-${counter++}',
        'date': _fmtDDMMMYYYY(date),
        'tag': tag,
        'remarks': '${remarkBase.trim()}-${_fmtAmount(amountInfo.$1)}',
        'manualEntry': tx,
        'amount': amountInfo.$1,
        'isIncoming': amountInfo.$2,
        'category': '',
      });
    }
  }

  return {
    'rows': allRows,
    'skippedSelf': skippedSelf,
    'skippedDate': skippedDate,
    'skippedAmt': skippedAmt,
    'noSheets': false,
  };
}

List<Map<String, dynamic>> _sheetToSmartRows(List<List<Data?>> rows) {
  if (rows.isEmpty) return <Map<String, dynamic>>[];

  const dateAliases = ['date', 'transaction date', 'txn date', 'entry date', 'value date', 'posting date'];
  const amountAliases = [
    'amount', 'debit', 'debit amount', 'withdrawal', 'dr', 'paid out',
    'txn amount', 'transaction amount', 'amt', 'value',
    'credit', 'credit amount', 'deposit', 'deposits', 'cr', 'paid in', 'received', 'incoming'
  ];
  const detailsAliases = ['transaction details', 'transaction detail', 'details', 'description', 'narration'];
  const remarksAliases = ['remarks', 'remark'];

  int bestHeader = 0;
  int bestScore = -1;
  final scan = rows.length < 20 ? rows.length : 20;

  for (int r = 0; r < scan; r++) {
    final rowStrings = <String>[];
    for (int c = 0; c < rows[r].length; c++) {
      rowStrings.add(_norm(_cellRaw(rows[r][c]?.value)?.toString() ?? ''));
    }

    bool hasMatch(List<String> aliases) {
      for (final a in aliases) {
        if (rowStrings.contains(_norm(a))) return true;
      }
      return false;
    }

    int score = 0;
    if (hasMatch(dateAliases)) score += 2;
    if (hasMatch(amountAliases)) score += 2;
    if (hasMatch(detailsAliases)) score += 1;
    if (hasMatch(remarksAliases)) score += 1;

    final nonEmpty = rows[r].where((c) => (_cellRaw(c?.value)?.toString().trim().isNotEmpty ?? false)).length;
    final weighted = score * 100 + nonEmpty;

    if (weighted > bestScore) {
      bestScore = weighted;
      bestHeader = r;
    }
    if (score >= 4) break;
  }

  final headers = <String>[];
  final seen = <String, int>{};
  for (int c = 0; c < rows[bestHeader].length; c++) {
    final base = (_cellRaw(rows[bestHeader][c]?.value)?.toString().trim() ?? '');
    final clean = base.isEmpty ? 'Column${c + 1}' : base;
    final n = seen[clean] ?? 0;
    seen[clean] = n + 1;
    headers.add(n == 0 ? clean : '${clean}_${n + 1}');
  }

  final out = <Map<String, dynamic>>[];
  for (int r = bestHeader + 1; r < rows.length; r++) {
    final row = rows[r];
    final hasData = row.any((c) => (_cellRaw(c?.value)?.toString().trim().isNotEmpty ?? false));
    if (!hasData) continue;

    final width = headers.length > row.length ? headers.length : row.length;
    final map = <String, dynamic>{};
    for (int c = 0; c < width; c++) {
      final key = c < headers.length ? headers[c] : 'Column${c + 1}';
      final value = c < row.length ? _cellRaw(row[c]?.value) : null;
      map[key] = value ?? '';
    }
    out.add(map);
  }
  return out;
}

dynamic _cellRaw(CellValue? cv) {
  if (cv == null) return null;
  if (cv is TextCellValue) return cv.value;
  if (cv is IntCellValue) return cv.value;
  if (cv is DoubleCellValue) return cv.value;
  if (cv is DateCellValue) return cv.asDateTimeLocal();
  if (cv is DateTimeCellValue) return cv.asDateTimeLocal();
  if (cv is BoolCellValue) return cv.value;
  return cv.toString();
}

String _norm(String s) {
  if (s.isEmpty) return '';
  final sb = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final c = s[i].toLowerCase();
    final code = c.codeUnitAt(0);
    if ((code >= 97 && code <= 122) || (code >= 48 && code <= 57)) {
      sb.write(c);
    }
  }
  return sb.toString();
}

String _getCellByAliases(Map<String, dynamic> row, List<String> aliases) {
  final keys = row.keys.toList();
  final normAliases = aliases.map(_norm).toList();

  for (final key in keys) {
    final nk = _norm(key);
    if (normAliases.contains(nk)) {
      final v = row[key];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
  }

  for (final key in keys) {
    final nk = _norm(key);
    for (final alias in normAliases) {
      if (nk.contains(alias) || alias.contains(nk)) {
        final v = row[key];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
    }
  }

  return '';
}

DateTime? _parseDateFromUnknown(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return DateTime(v.year, v.month, v.day);
  if (v is num) {
    return DateTime(1899, 12, 30).add(Duration(days: v.floor()));
  }

  final raw = v.toString().trim();
  if (raw.isEmpty) return null;

  final ddMmm = RegExp(r'^(\d{2})/(\w{3})/(\d{4})$').firstMatch(raw);
  if (ddMmm != null) {
    const mm = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return DateTime(
      int.parse(ddMmm.group(3)!),
      mm[ddMmm.group(2)!.toLowerCase()] ?? 1,
      int.parse(ddMmm.group(1)!),
    );
  }

  final dmY = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})$').firstMatch(raw);
  if (dmY != null) {
    final d = int.tryParse(dmY.group(1)!);
    final m = int.tryParse(dmY.group(2)!);
    var y = int.tryParse(dmY.group(3)!);
    if (d != null && m != null && y != null) {
      if (y < 100) y += 2000;
      return DateTime(y, m, d);
    }
  }

  final iso = DateTime.tryParse(raw);
  if (iso != null) return DateTime(iso.year, iso.month, iso.day);
  return null;
}

DateTime? _fallbackDateFromRow(Map<String, dynamic> row) {
  for (final entry in row.entries) {
    final nk = _norm(entry.key);
    if (RegExp(r'(amount|amt|debit|credit|withdraw|deposit|balance|remark|narration|description|tag|category)')
        .hasMatch(nk)) {
      continue;
    }
    final d = _parseDateFromUnknown(entry.value);
    if (d != null) return d;
  }
  return null;
}

(double, bool)? _resolveAmount(Map<String, dynamic> row) {
  const debitAliases = ['debit', 'debit amount', 'withdrawal', 'withdrawals', 'dr', 'paid out'];
  const genericAliases = ['amount', 'txn amount', 'transaction amount', 'amt', 'value'];
  const creditAliases = ['credit', 'credit amount', 'deposit', 'deposits', 'cr', 'paid in', 'received', 'incoming'];

  final debit = _parseAmount(_getCellByAliases(row, debitAliases));
  if (debit != null && debit != 0) return (debit.abs(), false);

  final generic = _parseAmount(_getCellByAliases(row, genericAliases));
  if (generic != null && generic != 0) return (generic.abs(), generic > 0);

  final credit = _parseAmount(_getCellByAliases(row, creditAliases));
  if (credit != null && credit != 0) return (credit.abs(), true);

  for (final entry in row.entries) {
    final nk = _norm(entry.key);
    if (nk.isEmpty || nk.contains('balance')) continue;
    if (RegExp(r'(amount|amt|debit|credit|withdraw|deposit|dr|cr|value|received|incoming)').hasMatch(nk)) {
      final parsed = _parseAmount(entry.value);
      if (parsed != null && parsed != 0) {
        final incomingHeader = RegExp(r'(credit|deposit|cr|received|incoming)').hasMatch(nk);
        final outgoingHeader = RegExp(r'(debit|withdraw|dr|paidout)').hasMatch(nk);
        final incoming = incomingHeader ? true : (outgoingHeader ? false : parsed > 0);
        return (parsed.abs(), incoming);
      }
    }
  }

  return null;
}

double? _parseAmount(dynamic v) {
  if (v is num) return v.toDouble();
  final text = v?.toString() ?? '';
  if (text.trim().isEmpty) return null;
  final clean = text.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.-]'), '');
  return double.tryParse(clean);
}

String _fmtDDMMMYYYY(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day.toString().padLeft(2, '0')}/${m[d.month - 1]}/${d.year}';
}

String _fmtAmount(double n) {
  final fixed = n.toStringAsFixed(2);
  return fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
}
