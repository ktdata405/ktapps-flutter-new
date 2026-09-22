import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core_constants.dart';
import '../core_ui_utils.dart';
import 'invites_entry_screen.dart';
import 'invites_models.dart';
import 'invites_service.dart';

class InvitesReportScreen extends StatefulWidget {
  const InvitesReportScreen({super.key});

  @override
  State<InvitesReportScreen> createState() => _InvitesReportScreenState();
}

class _InvitesReportScreenState extends State<InvitesReportScreen> {
  final InvitesService _service = InvitesService();
  List<InvitesRecord> _allRecords = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Active, Attending, Pending, Inactive

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
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    final records = await _service.fetchRecords();
    if (!mounted) return;
    setState(() {
      _allRecords = records;
      _isLoading = false;
    });
  }

  /// Opens default system dial pad with prefilled phone number
  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) {
      if (mounted) {
        ktShowCustomToast(context, 'No valid phone number');
      }
      return;
    }

    final Uri url = Uri(scheme: 'tel', path: cleanPhone);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch dial pad: $e');
      if (mounted) {
        ktShowCustomToast(context, 'Dial: $cleanPhone');
      }
    }
  }

  /// Inline status change directly within report or bottom sheet
  Future<bool> _updateStatus(InvitesRecord record, String newStatus) async {
    if (record.status == newStatus) return true;

    final updated = record.copyWith(status: newStatus);
    setState(() {
      final index = _allRecords.indexWhere((r) => r.sNo == record.sNo);
      if (index != -1) {
        _allRecords[index] = updated;
      }
    });

    final success = await _service.updateRecord(updated);
    if (!mounted) return success;

    if (success) {
      ktShowCustomToast(context, 'Status updated to $newStatus');
    } else {
      ktShowCustomToast(context, 'Failed to update status');
      _fetchData();
    }
    return success;
  }

  List<InvitesRecord> get _filteredRecords {
    return _allRecords.where((rec) {
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          rec.name.toLowerCase().contains(q) ||
          rec.place.toLowerCase().contains(q) ||
          rec.phone.contains(q) ||
          rec.remarks.toLowerCase().contains(q);

      if (!matchesSearch) return false;

      if (_selectedFilter == 'Active') return rec.isActive;
      if (_selectedFilter == 'Inactive') return !rec.isActive;
      if (_selectedFilter == 'Attending') return rec.status.toLowerCase() == 'attending';
      if (_selectedFilter == 'Pending') return rec.status.toLowerCase() == 'pending';

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredRecords;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive columns: 2 columns on mobile/app, 4 on desktop web
    final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    final totalCount = _allRecords.length;
    final activeCount = _allRecords.where((r) => r.isActive).length;
    final attendingCount = _allRecords.where((r) => r.status.toLowerCase() == 'attending').length;
    final pendingCount = _allRecords.where((r) => r.status.toLowerCase() == 'pending').length;

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
              child: const Icon(Icons.assessment_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  KtStrings.invitesReport,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  KtStrings.invitesReportSubtitle,
                  style: TextStyle(
                    fontSize: 10,
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
            child: ktHeaderIcon(Icons.refresh_rounded, _fetchData),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ktHeaderIcon(
              Icons.add_rounded,
              () => Navigator.pushNamed(context, '/invites').then((_) => _fetchData()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // KPI Summary Bar
            _buildKPIBar(
              totalCount: totalCount,
              activeCount: activeCount,
              attendingCount: attendingCount,
              pendingCount: pendingCount,
              isDark: isDark,
            ),

            // Search Bar & Filter Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Place, Phone...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: ktInvitesPrimary, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? ktCardBg : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ktInvitesPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Active', 'Attending', 'Pending', 'Inactive'].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: ktInvitesPrimary,
                            backgroundColor: isDark ? ktCardBg : Colors.white,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? ktInvitesPrimary
                                    : (isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.08)),
                              ),
                            ),
                            onSelected: (sel) {
                              if (sel) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Ultra-Compact Grid Layout with Active/Inactive text on Place line
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: ktInvitesPrimary),
                    )
                  : filtered.isEmpty
                      ? _buildEmptyState(isDark)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            mainAxisExtent: 82, // Compact card height
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final rec = filtered[index];
                            return _buildRecordGridTile(rec, isDark);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/invites').then((_) => _fetchData()),
        backgroundColor: ktInvitesPrimary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
        label: const Text(
          KtStrings.addInvite,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildKPIBar({
    required int totalCount,
    required int activeCount,
    required int attendingCount,
    required int pendingCount,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildKPICard('Total', totalCount.toString(), ktInvitesPrimary, isDark),
          _buildKPICard('Active', activeCount.toString(), ktEmerald, isDark),
          _buildKPICard('Attending', attendingCount.toString(), ktBlue500, isDark),
          _buildKPICard('Pending', pendingCount.toString(), ktAmber500, isDark),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, Color color, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }

  /// Extremely compact tile: Name clearly visible, Active/Inactive text on the same line as Place (right-aligned)
  Widget _buildRecordGridTile(InvitesRecord rec, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showRecordDetailsBottomSheet(rec, isDark),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Name: Prominently displayed and clear
                Text(
                  rec.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // 2. Place on Left, Active / Inactive text on Right (Same Line)
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 10,
                      color: ktInvitesPrimary,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        rec.place.isNotEmpty ? rec.place : 'No location',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rec.isActive ? KtStrings.activeText : KtStrings.inactiveText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: rec.isActive ? ktEmerald : ktRose,
                      ),
                    ),
                  ],
                ),

                // 3. Bottom Row: [ Status Badge ]  -----------------  [ Call Button ]
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status Badge
                    _buildStatusBadge(rec.status, isDark),

                    // Call Button Pill
                    InkWell(
                      onTap: () => _makePhoneCall(rec.phone),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: ktEmerald.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ktEmerald.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.call_rounded, color: ktEmerald, size: 10),
                            SizedBox(width: 2),
                            Text(
                              KtStrings.callAction,
                              style: TextStyle(
                                color: ktEmerald,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                              ),
                            ),
                          ],
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

  /// Global Bottom Sheet with interactive Status change selector and loader
  void _showRecordDetailsBottomSheet(InvitesRecord rec, bool isDark) {
    bool isUpdatingStatus = false;
    String? targetStatus;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sbContext, setSheetState) {
            final currentRec = _allRecords.firstWhere(
              (r) => r.sNo == rec.sNo,
              orElse: () => rec,
            );

            return Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Sheet Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: ktInvitesPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.celebration_rounded, color: ktInvitesPrimary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      currentRec.name,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  _buildActiveText(currentRec.isActive),
                                ],
                              ),
                              if (currentRec.place.isNotEmpty)
                                Text(
                                  currentRec.place,
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.black45),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Sheet Body
                  Flexible(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      shrinkWrap: true,
                      children: [
                        // Dial Pad Direct Call Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ktEmerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: ktEmerald.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_in_talk_rounded, color: ktEmerald, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  currentRec.phone,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  _makePhoneCall(currentRec.phone);
                                },
                                icon: const Icon(Icons.dialpad_rounded, size: 16, color: Colors.white),
                                label: const Text('Dial', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ktEmerald,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Interactive Status Selector Section with Loading State
                        Row(
                          children: [
                            Text(
                              'CHANGE STATUS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white54 : Colors.black54,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (isUpdatingStatus) ...[
                              const SizedBox(width: 10),
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ktInvitesPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Saving...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ktInvitesPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _statusOptions.map((st) {
                            final isSelected = currentRec.status == st;
                            final isTarget = isUpdatingStatus && targetStatus == st;
                            final color = _getStatusColor(st);

                            return ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isTarget) ...[
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    st,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              selected: isSelected,
                              selectedColor: color,
                              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSelected ? color : (isDark ? ktBorderWhite10 : Colors.black12),
                                ),
                              ),
                              onSelected: isUpdatingStatus
                                  ? null
                                  : (sel) async {
                                      if (sel && currentRec.status != st) {
                                        setSheetState(() {
                                          isUpdatingStatus = true;
                                          targetStatus = st;
                                        });

                                        await _updateStatus(currentRec, st);

                                        setSheetState(() {
                                          isUpdatingStatus = false;
                                          targetStatus = null;
                                        });
                                      }
                                    },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Remarks View
                        if (currentRec.remarks.isNotEmpty) ...[
                          Text(
                            KtStrings.remarks.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white54 : Colors.black54,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0B1222) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.08)),
                            ),
                            child: Text(
                              currentRec.remarks,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
                      border: Border(top: BorderSide(color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.05))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ktDeleteButton(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Invite?'),
                                content: Text('Are you sure you want to delete ${currentRec.name}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete', style: TextStyle(color: ktRose)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _service.deleteRecord(currentRec.sNo);
                              if (!mounted) return;
                              ktShowCustomToast(context, 'Invite deleted');
                              _fetchData();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ktEditButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InvitesEntryScreen(editRecord: currentRec),
                              ),
                            ).then((_) => _fetchData());
                          },
                          label: KtStrings.edit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActiveText(bool isActive) {
    final color = isActive ? ktEmerald : ktRose;
    return Text(
      isActive ? KtStrings.activeText : KtStrings.inactiveText,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'attending':
        return ktEmerald;
      case 'pending':
        return ktAmber500;
      case 'declined':
        return ktRose;
      case 'vip':
        return ktPurple500;
      case 'invited':
      default:
        return ktInvitesPrimary;
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.celebration_outlined,
            size: 56,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 12),
          Text(
            'No Invites Found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to create a new invitation record',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
