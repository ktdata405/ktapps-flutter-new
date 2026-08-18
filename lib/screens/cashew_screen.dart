import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cashew_record.dart';
import '../services/api_service.dart';
import 'cashew_import_screen.dart';

class CashewScreen extends StatefulWidget {
  const CashewScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<CashewScreen> createState() => _CashewScreenState();
}

class _CashewScreenState extends State<CashewScreen> {
  static const _categories = <String>[
	'Home',
	'My Personal',
	'My Family',
	'For Latha',
	'Baby',
	'Credit Card',
	'Mutual Funds/Investments',
	'Lap EMI',
  ];

  final _rows = <_ExpenseRow>[];
  final _allRecordDates = <String>{};
  DateTime _date = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  int _daysWithData = 0;

  @override
  void initState() {
	super.initState();
	_date = widget.initialDate ?? DateTime.now();
	_loadForDate();
  }

  @override
  void dispose() {
	for (final row in _rows) {
	  row.dispose();
	}
	super.dispose();
  }

  String get _dateText => DateFormat('dd/MMM/yyyy').format(_date);
  String get _inputDateText => DateFormat('dd/MM/yyyy').format(_date);

  Future<void> _loadForDate() async {
	setState(() => _loading = true);
	final data = await ApiService.fetchCashewRecordsByDate(_dateText);
	final all = await ApiService.fetchCashewRecords();
	final summary = await ApiService.fetchCashewSummary();

	for (final row in _rows) {
	  row.dispose();
	}
	_rows.clear();

	if (data.isEmpty) {
	  _rows.addAll([
		_ExpenseRow(category: 'Home'),
		_ExpenseRow(category: 'My Family'),
		_ExpenseRow(category: 'My Personal'),
	  ]);
	} else {
	  _rows.addAll(data.map(
		(r) => _ExpenseRow(
		  category: r.category,
		  amount: r.amount,
		  description: r.description,
		  status: r.status,
		),
	  ));
	}

	_allRecordDates
	  ..clear()
	  ..addAll(all.map((e) => e.date));
	_daysWithData = (summary['days'] ?? 0).round();

	if (mounted) {
	  setState(() => _loading = false);
	}
  }

  Future<void> _pickDate() async {
	final picked = await showDatePicker(
	  context: context,
	  initialDate: _date,
	  firstDate: DateTime(2020),
	  lastDate: DateTime(2100),
	);
	if (picked == null) return;
	setState(() => _date = picked);
	await _loadForDate();
  }

  void _shiftDay(int delta) {
	setState(() => _date = _date.add(Duration(days: delta)));
	_loadForDate();
  }

  void _setDateFromCalendar(int day) {
	setState(() => _date = DateTime(_date.year, _date.month, day));
	_loadForDate();
  }

  double get _total {
	return _rows.fold<double>(
	  0,
	  (sum, row) => sum + (double.tryParse(row.amount.text.trim()) ?? 0),
	);
  }

  bool get _hasAnyDataForDate => _rows.any((r) => (double.tryParse(r.amount.text.trim()) ?? 0) > 0);

  Set<int> get _monthDaysWithData {
	final key = DateFormat('MMMyyyy').format(_date).toLowerCase();
	final out = <int>{};
	for (final raw in _allRecordDates) {
	  DateTime? parsed;
	  try {
		parsed = DateFormat('dd/MMM/yyyy').parseLoose(raw);
	  } catch (_) {
		parsed = null;
	  }
	  if (parsed == null) continue;
	  final pKey = DateFormat('MMMyyyy').format(parsed).toLowerCase();
	  if (pKey == key) out.add(parsed.day);
	}
	return out;
  }

  void _addRow() {
	setState(() => _rows.add(_ExpenseRow(category: 'Home')));
  }

  void _removeRow(int index) {
	if (_rows.length == 1) {
	  _rows.first
		..amount.clear()
		..description.clear()
		..category = 'Home';
	  setState(() {});
	  return;
	}
	final row = _rows.removeAt(index);
	row.dispose();
	setState(() {});
  }

  void _clearAll() {
	for (final r in _rows) {
	  r.amount.clear();
	  r.description.clear();
	}
	setState(() {});
  }

  Future<void> _save(String status) async {
	final payload = <CashewRecord>[];
	for (final r in _rows) {
	  final amount = double.tryParse(r.amount.text.trim()) ?? 0;
	  if (amount <= 0) continue;
	  payload.add(CashewRecord(
		date: _dateText,
		category: r.category,
		description: r.description.text.trim(),
		amount: amount,
		status: status,
	  ));
	}
	if (payload.isEmpty) {
	  if (!mounted) return;
	  ScaffoldMessenger.of(context).showSnackBar(
		const SnackBar(content: Text('Add at least one valid expense')),
	  );
	  return;
	}

	setState(() => _saving = true);
	await ApiService.saveCashewRecordsForDate(date: _dateText, records: payload, status: status);
	if (!mounted) return;
	setState(() => _saving = false);
	ScaffoldMessenger.of(context).showSnackBar(
	  SnackBar(content: Text(status == 'draft' ? 'Draft saved' : 'Expenses saved')),
	);
	_loadForDate();
  }

  @override
  Widget build(BuildContext context) {
	return Scaffold(
	  backgroundColor: const Color(0xFF0B0F19),
	  body: Column(
		children: [
		  _buildHeader(),
		  Expanded(
			child: _loading
				? const Center(child: CircularProgressIndicator())
				: Container(
					decoration: const BoxDecoration(
					  gradient: LinearGradient(
						begin: Alignment.topLeft,
						end: Alignment.bottomRight,
						colors: [Color(0xFF121635), Color(0xFF10182D), Color(0xFF26142D)],
					  ),
					),
					child: Center(
					  child: ConstrainedBox(
						constraints: const BoxConstraints(maxWidth: 1460),
						child: LayoutBuilder(
						  builder: (context, c) {
							if (c.maxWidth < 1100) {
							  return ListView(
								padding: const EdgeInsets.fromLTRB(14, 14, 14, 170),
								children: [
								  _buildDateCard(),
								  const SizedBox(height: 14),
								  _buildCalendarCard(),
								  const SizedBox(height: 14),
								  ...List.generate(_rows.length, _buildExpenseCard),
								],
							  );
							}

							return Row(
							  crossAxisAlignment: CrossAxisAlignment.start,
							  children: [
								SizedBox(
								  width: 420,
								  child: Padding(
									padding: const EdgeInsets.fromLTRB(18, 18, 10, 170),
									child: Column(
									  children: [
										_buildDateCard(),
										const SizedBox(height: 14),
										_buildCalendarCard(),
									  ],
									),
								  ),
								),
								Expanded(
								  child: ListView(
									padding: const EdgeInsets.fromLTRB(10, 18, 18, 170),
									children: [
									  ...List.generate(_rows.length, _buildExpenseCard),
									],
								  ),
								),
							  ],
							);
						  },
						),
					  ),
					),
				  ),
		  ),
		],
	  ),
	  bottomNavigationBar: _buildBottomBar(),
	);
  }

  Widget _buildHeader() {
	return Container(
	  height: 60,
	  padding: const EdgeInsets.symmetric(horizontal: 16),
	  decoration: const BoxDecoration(
		color: Color(0xFF141A2B),
		border: Border(bottom: BorderSide(color: Color(0xFF2B3347))),
	  ),
	  child: Row(
		children: [
		  // Logo icon
		  Container(
			width: 38,
			height: 38,
			decoration: BoxDecoration(
			  borderRadius: BorderRadius.circular(11),
			  gradient: const LinearGradient(
				colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
				begin: Alignment.topLeft,
				end: Alignment.bottomRight,
			  ),
			),
			child: const Icon(Icons.wallet, color: Colors.white, size: 20),
		  ),
		  const SizedBox(width: 10),
		  const Column(
			mainAxisAlignment: MainAxisAlignment.center,
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
			  Text('Cashew',
				  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.2)),
			  Text('Expense Tracker',
				  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w400)),
			],
		  ),
		  const Spacer(),
		  Row(
			spacing: 8,
			children: [
			  _topBtn(Icons.calculate_outlined, _showCalculator),     // Calculator
			  _topBtn(Icons.upload_file_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashewImportScreen()))),  // Import
			  _topBtn(Icons.bar_chart_rounded, () {}),                                                 // Reports
			  _topBtn(Icons.home_rounded, () => Navigator.popUntil(context, ModalRoute.withName('/'))), // Home
			  _topBtn(Icons.settings_rounded, () => Navigator.pushNamed(context, '/settings')),        // Settings
			  _topBtn(Icons.table_chart_outlined, () {}),                                              // Excel Sheet
			],
		  ),
		],
	  ),
	);
  }

  Widget _topBtn(IconData icon, VoidCallback onTap) {
	return SizedBox(
	  width: 36,
	  height: 36,
	  child: IconButton(
		padding: EdgeInsets.zero,
		style: IconButton.styleFrom(
		  backgroundColor: const Color(0xFF1E2535),
		  foregroundColor: const Color(0xFF9CA3AF),
		  side: const BorderSide(color: Color(0xFF2B3347), width: 1),
		  shape: const CircleBorder(),
		),
		onPressed: _loading ? null : onTap,
		icon: Icon(icon, size: 16),
	  ),
	);
  }

  Widget _buildDateCard() {
	return _glassCard(
	  padding: const EdgeInsets.all(16),
	  child: Column(
		crossAxisAlignment: CrossAxisAlignment.start,
		children: [
		  const Text('DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE5E7EB))),
		  const SizedBox(height: 10),
		  Row(
			children: [
			  _dayBtn(Icons.chevron_left_rounded, () => _shiftDay(-1)),
			  const SizedBox(width: 10),
			  Expanded(
				child: InkWell(
				  onTap: _pickDate,
				  child: Container(
					height: 52,
					padding: const EdgeInsets.symmetric(horizontal: 14),
					decoration: BoxDecoration(
					  color: const Color(0x66000000),
					  borderRadius: BorderRadius.circular(16),
					  border: Border.all(color: const Color(0x14FFFFFF)),
					),
					child: Row(
					  children: [
						Text(_inputDateText,
							style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
						const Spacer(),
						const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF9CA3AF)),
					  ],
					),
				  ),
				),
			  ),
			  const SizedBox(width: 10),
			  _dayBtn(Icons.chevron_right_rounded, () => _shiftDay(1)),
			],
		  ),
		  const SizedBox(height: 12),
		  Center(
			child: Container(
			  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
			  decoration: BoxDecoration(
				borderRadius: BorderRadius.circular(999),
				color: _hasAnyDataForDate ? const Color(0x1A10B981) : const Color(0x1AF43F5E),
				border: Border.all(
				  color: _hasAnyDataForDate ? const Color(0x6610B981) : const Color(0x66F43F5E),
				),
			  ),
			  child: Text(
				_hasAnyDataForDate ? '● DATA' : '● NO DATA',
				style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
			  ),
			),
		  ),
		],
	  ),
	);
  }

  Widget _dayBtn(IconData icon, VoidCallback onTap) {
	return SizedBox(
	  width: 48,
	  height: 48,
	  child: FilledButton(
		style: FilledButton.styleFrom(
		  backgroundColor: const Color(0x66000000),
		  side: const BorderSide(color: Color(0x14FFFFFF)),
		  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
		),
		onPressed: onTap,
		child: Icon(icon, color: Colors.white),
	  ),
	);
  }

  Widget _buildCalendarCard() {
	final first = DateTime(_date.year, _date.month, 1);
	final daysInMonth = DateTime(_date.year, _date.month + 1, 0).day;
	final leading = first.weekday % 7;
	final marked = _monthDaysWithData;
	const week = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

	return Container(
	  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
	  decoration: BoxDecoration(
		color: const Color(0xFF253043),
		borderRadius: BorderRadius.circular(16),
		border: Border.all(color: const Color(0x22334155)),
	  ),
	  child: Column(
		children: [
		  Row(
			children: week
				.map((d) => Expanded(
					  child: Center(
						child: Text(d,
							style: const TextStyle(
								color: Color(0xFFE5E7EB), fontSize: 12, fontWeight: FontWeight.w700)),
					  ),
					))
				.toList(),
		  ),
		  const SizedBox(height: 10),
		  Wrap(
			spacing: 5,
			runSpacing: 5,
			children: List.generate(42, (idx) {
			  final day = idx - leading + 1;
			  if (day < 1 || day > daysInMonth) {
				return const SizedBox(width: 38, height: 38);
			  }
			  final selected = _date.day == day;
			  final hasData = marked.contains(day);
			  return InkWell(
				onTap: () => _setDateFromCalendar(day),
				child: Container(
				  width: 38,
				  height: 38,
				  alignment: Alignment.center,
				  decoration: BoxDecoration(
					color: selected
						? const Color(0xFF6366F1)
						: hasData
							? const Color(0x1A10B981)
							: const Color(0x0DFFFFFF),
					borderRadius: BorderRadius.circular(9),
					border: Border.all(
					  color: selected
						  ? const Color(0xFF6366F1)
						  : hasData
							  ? const Color(0x6610B981)
							  : Colors.transparent,
					),
				  ),
				  child: Text(
					'$day',
					style: TextStyle(
						color: selected ? Colors.white : const Color(0xFFE2E8F0),
						fontWeight: FontWeight.w700),
				  ),
				),
			  );
			}),
		  ),
		  const SizedBox(height: 10),
		  const Row(
			mainAxisAlignment: MainAxisAlignment.center,
			children: [
			  Icon(Icons.square_rounded, size: 10, color: Color(0xFF10B981)),
			  SizedBox(width: 6),
			  Text('DATA', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w700)),
			  SizedBox(width: 14),
			  Icon(Icons.square_rounded, size: 10, color: Color(0xFF4B5563)),
			  SizedBox(width: 6),
			  Text('EMPTY', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w700)),
			],
		  ),
		],
	  ),
	);
  }

  Widget _buildExpenseCard(int index) {
	final row = _rows[index];
	return _ExpenseCardWidget(
	  key: ObjectKey(row),
	  row: row,
	  showRemove: _rows.length > 1,
	  onRemove: () => _removeRow(index),
	  categories: _categories,
	  onAmountChanged: () => setState(() {}),
	);
  }

  Widget _buildBottomBar() {
	return Container(
	  decoration: const BoxDecoration(
		color: Color(0xFF141A2B),
		border: Border(top: BorderSide(color: Color(0x22334155))),
	  ),
	  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
	  child: SafeArea(
		top: false,
		child: Column(
		  mainAxisSize: MainAxisSize.min,
		  children: [
			Row(
			  mainAxisAlignment: MainAxisAlignment.center,
			  children: [
				// Total Expense
				Column(
				  crossAxisAlignment: CrossAxisAlignment.center,
				  children: [
					const Text(
					  'TOTAL EXPENSE',
					  style: TextStyle(color: Color(0xFFE5E7EB), fontSize: 12, fontWeight: FontWeight.w700),
					),
					const SizedBox(height: 2),
					Text(
					  NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2).format(_total),
					  style: const TextStyle(
						color: Colors.white,
						fontWeight: FontWeight.w900,
						fontSize: 18,
					  ),
					),
				  ],
				),
				const SizedBox(width: 32),
				// Divider
				Container(width: 1, height: 48, color: Color(0x33FFFFFF)),
				const SizedBox(width: 32),
				// Days With Data
				Column(
				  crossAxisAlignment: CrossAxisAlignment.center,
				  children: [
					const Text(
					  'DAYS WITH DATA',
					  style: TextStyle(color: Color(0xFFE5E7EB), fontSize: 12, fontWeight: FontWeight.w700),
					),
					const SizedBox(height: 2),
					Text(
					  '$_daysWithData',
					  style: const TextStyle(
						color: Colors.white,
						fontWeight: FontWeight.w800,
						fontSize: 18,
					  ),
					),
				  ],
				),
			  ],
			),
			const SizedBox(height: 10),
			SingleChildScrollView(
			  scrollDirection: Axis.horizontal,
			  child: Row(
				children: [
			  SizedBox(
				  width: 98,
				  height: 40,
				  child: OutlinedButton.icon(
				    style: OutlinedButton.styleFrom(
					  backgroundColor: const Color(0x0DFFFFFF),
					  foregroundColor: const Color(0xFFD1D5DB),
					  side: const BorderSide(color: Color(0x14FFFFFF)),
					  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
					  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
				    ),
				    onPressed: _saving ? null : _addRow,
				    icon: const Icon(Icons.add_rounded, size: 15),
				    label: const Text('Add'),
				  ),
				),
				const SizedBox(width: 10),
				IconButton.filledTonal(
				  style: IconButton.styleFrom(
				    backgroundColor: const Color(0x0DFFFFFF),
				    foregroundColor: const Color(0xFFD1D5DB),
				    side: const BorderSide(color: Color(0x14FFFFFF)),
				    fixedSize: const Size(54, 32),
				    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
				  ),
				  onPressed: _saving ? null : _clearAll,
				  icon: const Icon(Icons.delete_outline_rounded, size: 16),
				),
				const SizedBox(width: 10),
				SizedBox(
				  width: 98,
				  height: 40,
				  child: FilledButton.icon(
				    style: FilledButton.styleFrom(
					  backgroundColor: const Color(0x803D465A),
					  foregroundColor: Colors.white,
					  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
					  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
					  elevation: 0.5,
				    ),
				    onPressed: _saving ? null : () => _save('draft'),
				    icon: _saving
					    ? const SizedBox(
						    width: 14,
						    height: 14,
						    child: CircularProgressIndicator(strokeWidth: 2),
						  )
					    : const Icon(Icons.edit_note_rounded, size: 15),
				    label: const Text('Draft'),
				  ),
				),
				const SizedBox(width: 10),
				SizedBox(
				  width: 98,
				  height: 40,
				  child: Container(
				    decoration: BoxDecoration(
					  borderRadius: BorderRadius.circular(15),
					  gradient: const LinearGradient(
					    colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
					  ),
				    ),
				    child: FilledButton.icon(
					  style: FilledButton.styleFrom(
					    backgroundColor: Colors.transparent,
					    foregroundColor: Colors.white,
					    shadowColor: Colors.transparent,
					    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
					    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
					  ),
					  onPressed: _saving ? null : () => _save('completed'),
					  icon: const Icon(Icons.check_rounded, size: 15),
					  label: const Text('Save'),
				    ),
				  ),
				),
				],
			  ),
			),
		  ],
		),
	  ),
	);
  }

  Widget _glassCard({
	required Widget child,
	EdgeInsetsGeometry? padding,
	EdgeInsetsGeometry? margin,
  }) {
	return Container(
	  margin: margin,
	  padding: padding,
	  decoration: BoxDecoration(
		color: const Color(0x99151A25),
		borderRadius: BorderRadius.circular(24),
		border: Border.all(color: const Color(0x14FFFFFF)),
	  ),
	  child: child,
	);
  }

  // ignore: unused_element
  InputDecoration _fieldDecoration({
	String? hintText,
	String? prefixText,
	IconData? prefixIcon,
	bool showPrefixIcon = true,
  }) {
	return InputDecoration(
	  hintText: hintText,
	  hintStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
	  prefixText: prefixText,
	  prefixStyle: const TextStyle(color: Color(0xFF34D399), fontSize: 24, fontWeight: FontWeight.w700),
	  prefixIcon: (!showPrefixIcon || prefixIcon == null)
		  ? null
		  : Icon(prefixIcon, size: 15, color: const Color(0xFF6B7280)),
	  prefixIconConstraints: const BoxConstraints(minWidth: 34),
	  filled: true,
	  fillColor: const Color(0x66000000),
	  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
	  border: OutlineInputBorder(
		borderRadius: BorderRadius.circular(16),
		borderSide: const BorderSide(color: Color(0x263C4963)),
	  ),
	  enabledBorder: OutlineInputBorder(
		borderRadius: BorderRadius.circular(16),
		borderSide: const BorderSide(color: Color(0x263C4963)),
	  ),
	  focusedBorder: OutlineInputBorder(
		borderRadius: BorderRadius.circular(16),
		borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.2),
	  ),
	);
  }

  void _showCalculator() {
	showDialog(
	  context: context,
	  builder: (_) => const _CalculatorDialog(),
	);
  }
}

// ─── Expense Card Widget ──────────────────────────────────────────────────────

class _ExpenseCardWidget extends StatefulWidget {
  const _ExpenseCardWidget({
	super.key,
	required this.row,
	required this.showRemove,
	required this.onRemove,
	required this.categories,
	required this.onAmountChanged,
  });

  final _ExpenseRow row;
  final bool showRemove;
  final VoidCallback onRemove;
  final List<String> categories;
  final VoidCallback onAmountChanged;

  @override
  State<_ExpenseCardWidget> createState() => _ExpenseCardWidgetState();
}

class _ExpenseCardWidgetState extends State<_ExpenseCardWidget> {
  bool _showClose = false;

  Widget _card({required Widget child, EdgeInsetsGeometry? margin, EdgeInsetsGeometry? padding}) {
	return Container(
	  margin: margin,
	  padding: padding,
	  decoration: BoxDecoration(
		color: const Color(0x99151A25),
		borderRadius: BorderRadius.circular(24),
		border: Border.all(color: const Color(0x14FFFFFF)),
	  ),
	  child: child,
	);
  }

  InputDecoration _decoration({
	String? hintText,
	String? prefixText,
	IconData? prefixIcon,
	bool showPrefixIcon = true,
  }) {
	return InputDecoration(
	  hintText: hintText,
	  hintStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
	  prefixText: prefixText,
	  prefixStyle: const TextStyle(color: Color(0xFF34D399), fontSize: 24, fontWeight: FontWeight.w700),
	  prefixIcon: (!showPrefixIcon || prefixIcon == null)
		  ? null
		  : Icon(prefixIcon, size: 15, color: const Color(0xFF6B7280)),
	  prefixIconConstraints: const BoxConstraints(minWidth: 34),
	  filled: true,
	  fillColor: const Color(0x66000000),
	  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
	  border: OutlineInputBorder(
		borderRadius: BorderRadius.circular(16),
		borderSide: const BorderSide(color: Color(0x263C4963)),
	  ),
	  enabledBorder: OutlineInputBorder(
		borderRadius: BorderRadius.circular(16),
		borderSide: const BorderSide(color: Color(0x263C4963)),
	  ),
	  focusedBorder: OutlineInputBorder(
		borderRadius: BorderRadius.circular(16),
		borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.2),
	  ),
	);
  }

  @override
  Widget build(BuildContext context) {
	return MouseRegion(
	  onEnter: (_) => setState(() => _showClose = true),
	  onExit: (_) => setState(() => _showClose = false),
	  child: GestureDetector(
		behavior: HitTestBehavior.translucent,
		onTapDown: (_) => setState(() => _showClose = true),
		child: Stack(
		  clipBehavior: Clip.none,
		  children: [
			_card(
			  margin: const EdgeInsets.only(bottom: 16),
			  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
			  child: Column(
				children: [
				  const Row(
					children: [
					  Expanded(
						child: Text('CATEGORY',
							style: TextStyle(color: Color(0xFFE5E7EB), fontSize: 12, fontWeight: FontWeight.w700)),
					  ),
					  Text('AMOUNT',
						  style: TextStyle(color: Color(0xFFE5E7EB), fontSize: 12, fontWeight: FontWeight.w700)),
					],
				  ),
				  const SizedBox(height: 8),
				  Row(
					children: [
					  Expanded(
						child: DropdownButtonFormField<String>(
						  value: widget.categories.contains(widget.row.category) ? widget.row.category : widget.categories.first,
						  decoration: _decoration(prefixIcon: Icons.layers_rounded),
						  dropdownColor: const Color(0xFF151A25),
						  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
						  iconEnabledColor: const Color(0xFF6B7280),
						  items: widget.categories
							  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
							  .toList(),
						  onChanged: (v) => widget.row.category = v ?? widget.categories.first,
						),
					  ),
					  const SizedBox(width: 12),
					  SizedBox(
						width: 142,
						child: TextField(
						  controller: widget.row.amount,
						  keyboardType: const TextInputType.numberWithOptions(decimal: true),
						  textAlign: TextAlign.right,
						  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
						  decoration: _decoration(prefixText: '₹ ', hintText: '0', showPrefixIcon: false),
						  onChanged: (_) => widget.onAmountChanged(),
						),
					  ),
					],
				  ),
				  const SizedBox(height: 12),
				  const Align(
					alignment: Alignment.centerLeft,
					child: Text('DESCRIPTION',
						style: TextStyle(color: Color(0xFFE5E7EB), fontSize: 12, fontWeight: FontWeight.w700)),
				  ),
				  const SizedBox(height: 8),
				  TextField(
					controller: widget.row.description,
					keyboardType: TextInputType.multiline,
					textInputAction: TextInputAction.newline,
					minLines: 3,
					maxLines: 6,
					style: const TextStyle(color: Colors.white),
					decoration: _decoration(
					  hintText: 'What is this for? (e.g. Groceries 500, Milk 30)',
					  prefixIcon: Icons.notes_rounded,
					),
				  ),
				],
			  ),
			),
			if (widget.showRemove)
			  Positioned(
				right: -10,
				top: -10,
				child: AnimatedScale(
				  scale: _showClose ? 1.0 : 0.0,
				  duration: const Duration(milliseconds: 180),
				  curve: Curves.easeOutBack,
				  child: AnimatedOpacity(
					opacity: _showClose ? 1.0 : 0.0,
					duration: const Duration(milliseconds: 150),
					child: GestureDetector(
					  onTap: widget.onRemove,
					  child: Container(
						width: 34,
						height: 34,
						decoration: const BoxDecoration(
						  color: Color(0xFFEF4444),
						  shape: BoxShape.circle,
						),
						child: const Icon(Icons.close_rounded, color: Colors.white, size: 19),
					  ),
					),
				  ),
				),
			  ),
		  ],
		),
	  ),
	);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseRow {
  _ExpenseRow({
	required this.category,
	double? amount,
	String? description,
	this.status = 'completed',
  })  : amount = TextEditingController(
		  text: amount == null || amount == 0 ? '' : amount.toStringAsFixed(2),
		),
		description = TextEditingController(text: description ?? '');

  String category;
  String status;
  final TextEditingController amount;
  final TextEditingController description;

  void dispose() {
	amount.dispose();
	description.dispose();
  }
}

// ─── Calculator Dialog ────────────────────────────────────────────────────────

class _CalculatorDialog extends StatefulWidget {
  const _CalculatorDialog();

  @override
  State<_CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<_CalculatorDialog> {
  String _display = '0';
  String _expression = '';
  double _operand1 = 0;
  String _operator = '';
  bool _shouldReplace = false;

  static const _btnColor = Color(0xFF1E2535);
  static const _opColor = Color(0xFF6366F1);
  static const _acColor = Color(0xFF2B3347);

  void _onDigit(String digit) {
    setState(() {
      if (_shouldReplace || _display == '0') {
        _display = digit;
        _shouldReplace = false;
      } else {
        if (_display.length < 14) _display += digit;
      }
    });
  }

  void _onDecimal() {
    setState(() {
      if (_shouldReplace) {
        _display = '0.';
        _shouldReplace = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onOperator(String op) {
    setState(() {
      _operand1 = double.tryParse(_display) ?? 0;
      _operator = op;
      _expression = '${_display} $op';
      _shouldReplace = true;
    });
  }

  void _onEquals() {
    if (_operator.isEmpty) return;
    final operand2 = double.tryParse(_display) ?? 0;
    double result;
    switch (_operator) {
      case '+': result = _operand1 + operand2; break;
      case '−': result = _operand1 - operand2; break;
      case '×': result = _operand1 * operand2; break;
      case '÷': result = operand2 != 0 ? _operand1 / operand2 : double.nan; break;
      default: result = operand2;
    }
    setState(() {
      _expression = '${_expression} $operand2 =';
      _display = result.isNaN
          ? 'Error'
          : (result % 1 == 0 ? result.toInt().toString() : result.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), ''));
      _operator = '';
      _shouldReplace = true;
    });
  }

  void _onClear() => setState(() { _display = '0'; _expression = ''; _operator = ''; _operand1 = 0; _shouldReplace = false; });

  void _onBackspace() {
    setState(() {
      if (_display.length <= 1 || _display == 'Error') {
        _display = '0';
      } else {
        _display = _display.substring(0, _display.length - 1);
      }
    });
  }

  void _onToggleSign() {
    setState(() {
      final val = double.tryParse(_display);
      if (val != null && val != 0) {
        _display = (val * -1 % 1 == 0) ? (val * -1).toInt().toString() : (val * -1).toString();
      }
    });
  }

  void _onPercent() {
    setState(() {
      final val = double.tryParse(_display) ?? 0;
      final result = val / 100;
      _display = result % 1 == 0 ? result.toInt().toString() : result.toString();
    });
  }

  Widget _btn(String label, {Color bg = _btnColor, Color fg = Colors.white, double fontSize = 20, VoidCallback? onTap, IconData? icon}) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Center(
          child: icon != null
              ? Icon(icon, color: fg, size: fontSize)
              : Text(label, style: TextStyle(color: fg, fontSize: fontSize, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _btnRow(List<Widget> buttons) {
    return SizedBox(
      height: 56,
      child: Row(
        children: buttons
            .expand((btn) => [Expanded(child: btn), const SizedBox(width: 8)])
            .toList()
          ..removeLast(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F1623),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 320,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF7C3AED)]),
                    ),
                    child: const Icon(Icons.calculate_outlined, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text('Calculator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141A2B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2B3347)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_expression, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(_display, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Buttons grid
              Column(
                children: [
                  _btnRow([
                    _btn('AC',  bg: _acColor, fg: const Color(0xFFE5E7EB), fontSize: 17, onTap: _onClear),
                    _btn('+/−', bg: _acColor, fg: const Color(0xFFE5E7EB), fontSize: 17, onTap: _onToggleSign),
                    _btn('%',   bg: _acColor, fg: const Color(0xFFE5E7EB), fontSize: 17, onTap: _onPercent),
                    _btn('÷',   bg: _opColor, onTap: () => _onOperator('÷')),
                  ]),
                  const SizedBox(height: 8),
                  _btnRow([
                    _btn('7', onTap: () => _onDigit('7')),
                    _btn('8', onTap: () => _onDigit('8')),
                    _btn('9', onTap: () => _onDigit('9')),
                    _btn('×', bg: _opColor, onTap: () => _onOperator('×')),
                  ]),
                  const SizedBox(height: 8),
                  _btnRow([
                    _btn('4', onTap: () => _onDigit('4')),
                    _btn('5', onTap: () => _onDigit('5')),
                    _btn('6', onTap: () => _onDigit('6')),
                    _btn('−', bg: _opColor, onTap: () => _onOperator('−')),
                  ]),
                  const SizedBox(height: 8),
                  _btnRow([
                    _btn('1', onTap: () => _onDigit('1')),
                    _btn('2', onTap: () => _onDigit('2')),
                    _btn('3', onTap: () => _onDigit('3')),
                    _btn('+', bg: _opColor, onTap: () => _onOperator('+')),
                  ]),
                  const SizedBox(height: 8),
                  // Last row: 0 is double-width
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _btn('0', fontSize: 20, onTap: () => _onDigit('0')),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _btn('.', onTap: _onDecimal)),
                        const SizedBox(width: 8),
                        Expanded(child: _btn('', icon: Icons.backspace_outlined, fg: const Color(0xFFE5E7EB), fontSize: 18, onTap: _onBackspace)),
                        const SizedBox(width: 8),
                        Expanded(child: _btn('=', bg: const Color(0xFF7C3AED), onTap: _onEquals)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
