import 'package:flutter/material.dart';
import '../core_constants.dart';
import '../core_ui_utils.dart';
import 'invites_models.dart';
import 'invites_service.dart';

class InvitesEntryScreen extends StatefulWidget {
  final InvitesRecord? editRecord;

  const InvitesEntryScreen({super.key, this.editRecord});

  @override
  State<InvitesEntryScreen> createState() => _InvitesEntryScreenState();
}

class _InvitesEntryScreenState extends State<InvitesEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final InvitesService _service = InvitesService();

  late String _sNo;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  String _status = KtStrings.pendingStatus;
  bool _isActive = true;
  bool _isSaving = false;

  final List<String> _statusOptions = [
    KtStrings.pendingStatus,
    KtStrings.invitedStatus,
    KtStrings.attendingStatus,
    KtStrings.declinedStatus,
    KtStrings.vipStatus,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editRecord != null) {
      final rec = widget.editRecord!;
      _sNo = rec.sNo;
      _nameController.text = rec.name;
      _phoneController.text = rec.phone;
      _placeController.text = rec.place;
      _remarksController.text = rec.remarks;
      _status = rec.status;
      _isActive = rec.isActive;
    } else {
      _generateNewSNo();
    }
  }

  void _generateNewSNo() {
    setState(() {
      _sNo = InvitesRecord.generateSNo();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _placeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final record = InvitesRecord(
      sNo: _sNo,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      status: _status,
      place: _placeController.text.trim(),
      isActive: _isActive,
      remarks: _remarksController.text.trim(),
      date: widget.editRecord?.date ?? DateTime.now().toIso8601String(),
    );

    bool success;
    if (widget.editRecord != null) {
      success = await _service.updateRecord(record);
    } else {
      success = await _service.addRecord(record);
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      ktShowCustomToast(
        context,
        widget.editRecord != null ? KtStrings.recordUpdated : KtStrings.recordSaved,
      );
      if (widget.editRecord != null) {
        Navigator.pop(context, true);
      } else {
        _resetForm();
      }
    } else {
      ktShowCustomToast(context, KtStrings.saveFailed);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _phoneController.clear();
    _placeController.clear();
    _remarksController.clear();
    setState(() {
      _status = KtStrings.invitedStatus;
      _isActive = true;
    });
    _generateNewSNo();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.editRecord != null;

    return Scaffold(
      backgroundColor: isDark ? ktBgDark : ktLightScaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? ktDarkBlueHeader : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ktInvitesPrimary, ktInvitesSecondary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? KtStrings.editInvite : KtStrings.invitesTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  KtStrings.invitesSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? ktTextGray400 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ktHeaderIcon(
              Icons.home_rounded,
              () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ktHeaderIcon(
              Icons.bar_chart_rounded,
              () => Navigator.pushNamed(context, '/report/invites'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. S.No Auto-generated Card
                _buildSNoCard(isDark),
                const SizedBox(height: 20),

                // 2. Main Entry Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? ktCardBg : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Field
                      _buildTextFieldLabel(KtStrings.nameLabel, isDark, required: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: _inputDecoration(
                          hint: KtStrings.enterNameHint,
                          icon: Icons.person_outline_rounded,
                          isDark: isDark,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter Name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Phone Field
                      _buildTextFieldLabel(KtStrings.phoneLabel, isDark, required: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: _inputDecoration(
                          hint: KtStrings.enterPhoneHint,
                          icon: Icons.phone_outlined,
                          isDark: isDark,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter Phone Number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Place Field
                      _buildTextFieldLabel(KtStrings.placeLabel, isDark, required: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _placeController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: _inputDecoration(
                          hint: KtStrings.enterPlaceHint,
                          icon: Icons.location_on_outlined,
                          isDark: isDark,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter Place';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Status Selection Chips
                      _buildTextFieldLabel(KtStrings.statusLabel, isDark),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _statusOptions.map((st) {
                          final isSelected = _status == st;
                          return ChoiceChip(
                            label: Text(
                              st,
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: ktInvitesPrimary,
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? ktInvitesPrimary
                                    : (isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.1)),
                              ),
                            ),
                            onSelected: (sel) {
                              if (sel) {
                                setState(() {
                                  _status = st;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // isActive Toggle Switch Card
                      _buildIsActiveToggleCard(isDark),
                      const SizedBox(height: 20),

                      // Remarks Field - Address Field Type Big Input Box
                      _buildTextFieldLabel(KtStrings.remarks, isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _remarksController,
                        minLines: 3,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          hint: KtStrings.enterRemarksAddressHint,
                          icon: Icons.map_outlined,
                          isDark: isDark,
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit / Update & Clear Action Buttons
                Row(
                  children: [
                    if (!isEdit)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _resetForm,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text(KtStrings.clearAll),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : Colors.black87,
                            side: BorderSide(
                              color: isDark ? ktBorderWhite10 : Colors.black26,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    if (!isEdit) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [ktInvitesPrimary, ktInvitesSecondary],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: ktInvitesPrimary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveRecord,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(isEdit ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                  color: Colors.white),
                          label: Text(
                            _isSaving
                                ? KtStrings.loading
                                : (isEdit ? KtStrings.updateRecord : KtStrings.addInvite),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSNoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF31103F)]
              : [const Color(0xFFFDF4FF), const Color(0xFFF3E8FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ktInvitesPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ktInvitesPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.tag_rounded, color: ktInvitesPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${KtStrings.sNoLabel} (Auto Generated)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? ktTextGray400 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _sNo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: ktInvitesPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Last 3 digits of current ms',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          if (widget.editRecord == null)
            IconButton(
              tooltip: 'Regenerate S.No',
              icon: const Icon(Icons.refresh_rounded, color: ktInvitesPrimary),
              onPressed: _generateNewSNo,
            ),
        ],
      ),
    );
  }

  Widget _buildIsActiveToggleCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1222) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (_isActive ? ktEmerald : ktRose).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isActive ? Icons.check_circle_outline_rounded : Icons.pause_circle_outline_rounded,
              color: _isActive ? ktEmerald : ktRose,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  KtStrings.isActiveLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  _isActive ? KtStrings.activeText : KtStrings.inactiveText,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isActive ? ktEmerald : ktRose,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isActive,
            activeColor: ktEmerald,
            onChanged: (val) {
              setState(() {
                _isActive = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldLabel(String label, bool isDark, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white70 : Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: ktRose, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : Colors.black38,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: ktInvitesPrimary, size: 20),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: isDark ? const Color(0xFF0B1222) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ktInvitesPrimary, width: 2),
      ),
    );
  }
}
