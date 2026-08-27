import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _service = WalletService();
  final _formKey = GlobalKey<FormState>();

  String _selectedOwner = 'Kalyan';
  String _selectedType = 'credential';
  bool _loading = false;

  // Credential controllers
  final _bankNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tPasswordController = TextEditingController();
  final _cardPinController = TextEditingController();
  String _channel = 'Both';
  String _bankStatus = 'Active';

  // ID controllers
  String _idType = 'Aadhaar';
  final _idNumberController = TextEditingController();
  final _idNameController = TextEditingController();
  DateTime? _validFrom, _validTo;

  // Card controllers
  final _cardLabelController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  final List<String> _owners = [
    'Kalyan', 'Latha', 'Anshika', 'Amma', 'Dad',
    'Chinnu', 'Arshika', 'Kartheek', 'Srikanth', 'Common Family'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030305),
      body: Stack(
        children: [
          const _GridBackground(),
          _buildBackgroundOrbs(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildOwnerSelector(),
                        const SizedBox(height: 20),
                        _buildTypeSelector(),
                        const SizedBox(height: 20),
                        _buildForm(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_loading) _buildLoader(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Wallet Vault', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Secure and group your records', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          _buildTopIcon(Icons.pie_chart_outline, onTap: () => Navigator.pushNamed(context, '/report/wallet')),
          const SizedBox(width: 8),
          _buildTopIcon(Icons.home_outlined, onTap: () => Navigator.popUntil(context, (r) => r.isFirst)),
        ],
      ),
    );
  }

  Widget _buildTopIcon(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
      ),
    );
  }

  Widget _buildOwnerSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF151A25).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Wallet Owner / Folder', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedOwner,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: _owners.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _selectedOwner = v!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF151A25).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(left: 4, bottom: 12), child: Text('Choose Entry Type', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold))),
          Row(
            children: [
              Expanded(child: _TypeChip(label: 'Bank', isActive: _selectedType == 'credential', color: Colors.cyanAccent, onTap: () => setState(() => _selectedType = 'credential'))),
              const SizedBox(width: 8),
              Expanded(child: _TypeChip(label: 'IDs', isActive: _selectedType == 'id_card', color: Colors.indigoAccent, onTap: () => setState(() => _selectedType = 'id_card'))),
              const SizedBox(width: 8),
              Expanded(child: _TypeChip(label: 'Cards', isActive: _selectedType == 'card', color: Colors.tealAccent, onTap: () => setState(() => _selectedType = 'card'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_selectedType == 'credential') _buildCredentialForm(),
          if (_selectedType == 'id_card') _buildIdForm(),
          if (_selectedType == 'card') _buildCardForm(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getTypeColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    if (_selectedType == 'credential') return Colors.cyan.shade600;
    if (_selectedType == 'id_card') return Colors.indigo.shade600;
    return Colors.teal.shade600;
  }

  Widget _buildCredentialForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF151A25).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bank Login Credentials', style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _Input(label: 'Bank Name', controller: _bankNameController),
          const SizedBox(height: 16),
          _Input(label: 'Username/Customer ID', controller: _usernameController),
          const SizedBox(height: 16),
          _Input(label: 'Login Password', controller: _passwordController, isPassword: true),
          const SizedBox(height: 16),
          _Input(label: 'T-Password/T-PIN', controller: _tPasswordController, isPassword: true),
          const SizedBox(height: 16),
          _buildDropdown('Web/Mobile App', _channel, ['Web', 'Mobile App', 'Both'], (v) => setState(() => _channel = v!)),
          const SizedBox(height: 16),
          _Input(label: 'Card PIN', controller: _cardPinController, isPassword: true),
          const SizedBox(height: 16),
          _buildDropdown('Status', _bankStatus, ['Active', 'Inactive', 'Blocked'], (v) => setState(() => _bankStatus = v!)),
        ],
      ),
    );
  }

  Widget _buildIdForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF151A25).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ID Card Number', style: TextStyle(color: Colors.indigoAccent, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildDropdown('ID Type', _idType, ['Aadhaar', 'PAN', 'Driving License', 'Passport', 'Voter ID', 'Other'], (v) => setState(() => _idType = v!)),
          const SizedBox(height: 16),
          _Input(label: 'ID Number', controller: _idNumberController),
          const SizedBox(height: 16),
          _Input(label: 'Name on ID (optional)', controller: _idNameController),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _DateBtn(label: 'Valid From', date: _validFrom, onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1950), lastDate: DateTime.now()); if(d!=null) setState(()=>_validFrom=d); })),
              const SizedBox(width: 12),
              Expanded(child: _DateBtn(label: 'Valid To', date: _validTo, onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1950), lastDate: DateTime(2100)); if(d!=null) setState(()=>_validTo=d); })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF151A25).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Card Number + CVV', style: TextStyle(color: Colors.tealAccent, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _Input(label: 'Card Label', controller: _cardLabelController),
          const SizedBox(height: 16),
          _Input(label: 'Card Number', controller: _cardNumberController, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Input(label: 'MM/YY', controller: _cardExpiryController)),
              const SizedBox(width: 12),
              Expanded(child: _Input(label: 'CVV', controller: _cardCvvController, keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          _Input(label: 'Card Holder Name (optional)', controller: _cardHolderController),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> opts, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: opts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    Map<String, dynamic> payload = {
      'owner': _selectedOwner,
      'type': _selectedType,
    };

    if (_selectedType == 'credential') {
      payload.addAll({
        'title': _bankNameController.text,
        'textValue': 'Username: ${_usernameController.text}\nPassword: ${_passwordController.text}\nT-PIN: ${_tPasswordController.text}\nChannel: $_channel\nPIN: ${_cardPinController.text}\nStatus: $_bankStatus',
        'credBankName': _bankNameController.text,
        'credUsername': _usernameController.text,
        'credLoginPassword': _passwordController.text,
        'credTPassOrPin': _tPasswordController.text,
        'credChannel': _channel,
        'credCardPin': _cardPinController.text,
        'credStatus': _bankStatus,
      });
    } else if (_selectedType == 'id_card') {
      payload.addAll({
        'title': _idType,
        'idType': _idType,
        'idNumber': _idNumberController.text,
        'idName': _idNameController.text,
        if (_validFrom != null) 'validFrom': DateFormat('yyyy-MM-dd').format(_validFrom!),
        if (_validTo != null) 'validTo': DateFormat('yyyy-MM-dd').format(_validTo!),
      });
    } else {
      payload.addAll({
        'title': _cardLabelController.text,
        'cardLabel': _cardLabelController.text,
        'cardNumber': _cardNumberController.text,
        'cardExpiry': _cardExpiryController.text,
        'cardCvv': _cardCvvController.text,
        'cardHolder': _cardHolderController.text,
      });
    }

    setState(() => _loading = true);
    final ok = await _service.addEntry(payload);
    setState(() => _loading = false);

    if (ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record saved successfully!')));
      _clearFormFields();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save failed.')));
    }
  }

  void _clearFormFields() {
    _bankNameController.clear(); _usernameController.clear(); _passwordController.clear(); _tPasswordController.clear(); _cardPinController.clear();
    _idNumberController.clear(); _idNameController.clear();
    _cardLabelController.clear(); _cardNumberController.clear(); _cardExpiryController.clear(); _cardCvvController.clear(); _cardHolderController.clear();
    setState(() { _validFrom = null; _validTo = null; });
  }

  Widget _buildLoader() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(children: [
      Positioned(top: -100, left: -100, child: _Orb(color: Colors.indigoAccent.withValues(alpha: 0.1), size: 400)),
      Positioned(bottom: -100, right: -100, child: _Orb(color: Colors.cyanAccent.withValues(alpha: 0.1), size: 400)),
    ]);
  }
}

class _TypeChip extends StatelessWidget {
  final String label; final bool isActive; final Color color; final VoidCallback onTap;
  const _TypeChip({required this.label, required this.isActive, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: isActive ? color.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: isActive ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1))),
        child: Center(child: Text(label, style: TextStyle(color: isActive ? color : Colors.white38, fontSize: 13, fontWeight: FontWeight.bold))),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final String label; final TextEditingController controller; final bool isPassword; final TextInputType? keyboardType;
  const _Input({required this.label, required this.controller, this.isPassword = false, this.keyboardType});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextField(controller: controller, obscureText: isPassword, keyboardType: keyboardType, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(filled: true, fillColor: Colors.black.withValues(alpha: 0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
    ]);
  }
}

class _DateBtn extends StatelessWidget {
  final String label; final DateTime? date; final VoidCallback onTap;
  const _DateBtn({required this.label, required this.date, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))), child: Row(children: [const Icon(Icons.calendar_today, color: Colors.white38, size: 14), const SizedBox(width: 8), Text(date != null ? DateFormat('dd/MM/yyyy').format(date!) : 'Select', style: const TextStyle(color: Colors.white, fontSize: 14))]))),
    ]);
  }
}

class _Orb extends StatelessWidget {
  final Color color; final double size;
  const _Orb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) { return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent))); }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();
  @override
  Widget build(BuildContext context) { return CustomPaint(size: Size.infinite, painter: _GridPainter()); }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.01)..strokeWidth = 1.0;
    const step = 40.0;
    for (double i = 0; i < size.width; i += step) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += step) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
