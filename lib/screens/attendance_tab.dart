import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../db/database_helper.dart';
import '../models/member.dart';
import '../models/attendance_record.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import 'member_form_screen.dart';

class AttendanceTab extends StatefulWidget {
  final String category; // 'Gents' | 'Ladies'
  final String day;
  final String date; // yyyy-MM-dd
  final String searchQuery;
  const AttendanceTab({
    super.key,
    required this.category,
    required this.day,
    required this.date,
    this.searchQuery = '',
  });

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  final _db = DatabaseHelper.instance;
  List<Member> _members = [];
  final Map<int, String> _status = {};
  final Map<int, String> _pvValue = {}; // e.g. "PV | 06:00" or "" if unset
  bool _loading = true;
  bool _saving = false;
  String? _lastVerifyMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AttendanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date || oldWidget.day != widget.day) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final members = await _db.getMembers(widget.category);
      final existing =
          await _db.getAttendanceForDate(widget.category, widget.date);

      _status.clear();
      _pvValue.clear();

      for (final m in members) {
        final rec = existing[m.id];
        _status[m.id!] = rec?.status ?? '';
        _pvValue[m.id!] = rec?.pvTime ?? '';
      }

      setState(() {
        _members = members;
        _loading = false;
        _lastVerifyMessage = null;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    final records = _members.map((m) {
      return AttendanceRecord(
        memberId: m.id!,
        date: widget.date,
        day: widget.day,
        status: _status[m.id!] ?? '',
        pvTime: _pvValue[m.id!] ?? '',
      );
    }).toList();

    await _db.saveAttendanceBatch(records);

    final reread = await _db.getAttendanceForDate(widget.category, widget.date);
    int matched = 0;
    int mismatched = 0;
    for (final m in _members) {
      final expectedStatus = _status[m.id!] ?? '';
      final expectedPv = _pvValue[m.id!] ?? '';
      final saved = reread[m.id!];
      if (saved != null &&
          saved.status == expectedStatus &&
          saved.pvTime == expectedPv) {
        matched++;
      } else {
        mismatched++;
      }
    }

    setState(() {
      _saving = false;
      _lastVerifyMessage = mismatched == 0
          ? 'Saved & verified: all $matched record(s) confirmed in database.'
          : 'Saved with issues: $matched confirmed, $mismatched did NOT match after refresh.';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lastVerifyMessage!),
          backgroundColor:
              mismatched == 0 ? AppTheme.presentGreen : AppTheme.absentRed,
        ),
      );
    }

    await _load();
  }

  Future<void> _exportPdf() async {
    final rows = await _buildExportRows();
    final file = await ExportService.exportPdf(
      category: widget.category,
      day: widget.day,
      date: widget.date,
      rows: rows,
      sanchalakName: widget.category == 'Gents'
          ? 'Rev. _______________________'
          : 'Rev. Sunita Sunil Khamkar Ji',
      shikshakName: widget.category == 'Gents'
          ? 'Rev. Nitesh Gawade Ji'
          : 'Rev. Uma Sachin Jadhav Ji',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved: ${file.path.split('/').last}')),
    );
    await ExportService.shareFile(file);
  }

  Future<void> _exportPng() async {
    final rows = await _buildExportRows();
    final file = await ExportService.exportPng(
      category: widget.category,
      day: widget.day,
      date: widget.date,
      rows: rows,
      sanchalakName: widget.category == 'Gents'
          ? 'Rev. _______________________'
          : 'Rev. Sunita Sunil Khamkar Ji',
      shikshakName: widget.category == 'Gents'
          ? 'Rev. Nitesh Gawade Ji'
          : 'Rev. Uma Sachin Jadhav Ji',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image saved: ${file.path.split('/').last}')),
    );
    await ExportService.shareFile(file);
  }

  Future<void> _exportExcel() async {
    final rows = await _buildExportRows();
    final file = await ExportService.exportExcel(
      category: widget.category,
      day: widget.day,
      date: widget.date,
      rows: rows,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Excel saved: ${file.path.split('/').last}')),
    );
    await ExportService.shareFile(file);
  }

  Future<List<ExportRow>> _buildExportRows() async {
    final saved = await _db.getAttendanceForDate(widget.category, widget.date);
    return _members.map((m) => ExportRow(m, saved[m.id])).toList();
  }

  // ---------------- PV/PC Spinner Picker ----------------

  static const List<String> _types = ['PV', 'PC'];
  static final List<String> _hours =
      List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));
  static final List<String> _minutes =
      List.generate(60, (i) => i.toString().padLeft(2, '0'));

  Future<void> _openPvPicker(Member m) async {
    // Parse existing value if present, e.g. "PV | 06:00"
    String currentType = 'PV';
    String currentHour = '06';
    String currentMinute = '00';
    final existing = _pvValue[m.id!] ?? '';
    if (existing.contains('|')) {
      final parts = existing.split('|');
      final type = parts[0].trim();
      final time = parts.length > 1 ? parts[1].trim() : '';
      if (_types.contains(type)) currentType = type;
      final timeParts = time.split(':');
      if (timeParts.length == 2) {
        if (_hours.contains(timeParts[0].trim())) {
          currentHour = timeParts[0].trim();
        }
        if (_minutes.contains(timeParts[1].trim())) {
          currentMinute = timeParts[1].trim();
        }
      }
    }

    int typeIndex = _types.indexOf(currentType);
    int hourIndex = _hours.indexOf(currentHour);
    int minuteIndex = _minutes.indexOf(currentMinute);
    if (typeIndex < 0) typeIndex = 0;
    if (hourIndex < 0) hourIndex = 0;
    if (minuteIndex < 0) minuteIndex = 0;

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        int selType = typeIndex;
        int selHour = hourIndex;
        int selMinute = minuteIndex;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              // Clear this member's PV/PC value.
                              Navigator.pop(ctx, '');
                            },
                            child: const Text('Clear'),
                          ),
                          Text(
                            m.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          TextButton(
                            onPressed: () {
                              final value =
                                  '${_types[selType]} | ${_hours[selHour]}:${_minutes[selMinute]}';
                              Navigator.pop(ctx, value);
                            },
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 180,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: CupertinoPicker(
                              itemExtent: 36,
                              scrollController: FixedExtentScrollController(
                                  initialItem: selType),
                              onSelectedItemChanged: (i) =>
                                  setModalState(() => selType = i),
                              children: _types
                                  .map((t) => Center(
                                      child: Text(t,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600))))
                                  .toList(),
                            ),
                          ),
                          const Text('|', style: TextStyle(fontSize: 18)),
                          Expanded(
                            flex: 3,
                            child: CupertinoPicker(
                              itemExtent: 36,
                              scrollController: FixedExtentScrollController(
                                  initialItem: selHour),
                              onSelectedItemChanged: (i) =>
                                  setModalState(() => selHour = i),
                              children: _hours
                                  .map((h) => Center(
                                      child: Text(h,
                                          style:
                                              const TextStyle(fontSize: 18))))
                                  .toList(),
                            ),
                          ),
                          const Text(':', style: TextStyle(fontSize: 18)),
                          Expanded(
                            flex: 3,
                            child: CupertinoPicker(
                              itemExtent: 36,
                              scrollController: FixedExtentScrollController(
                                  initialItem: selMinute),
                              onSelectedItemChanged: (i) =>
                                  setModalState(() => selMinute = i),
                              children: _minutes
                                  .map((mn) => Center(
                                      child: Text(mn,
                                          style:
                                              const TextStyle(fontSize: 18))))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _pvValue[m.id!] = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final query = widget.searchQuery.trim().toLowerCase();
    final visibleMembers = query.isEmpty
        ? _members
        : _members.where((m) => m.name.toLowerCase().contains(query)).toList();

    return Column(
      children: [
        _buildHeaderBlock(),
        if (_lastVerifyMessage != null)
          Container(
            width: double.infinity,
            color: _lastVerifyMessage!.startsWith('Saved &')
                ? AppTheme.presentGreen.withOpacity(0.12)
                : AppTheme.absentRed.withOpacity(0.12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child:
                Text(_lastVerifyMessage!, style: const TextStyle(fontSize: 12)),
          ),
        Expanded(
          child: visibleMembers.isEmpty
              ? Center(
                  child: Text(
                    query.isEmpty
                        ? 'No members yet. Tap + to add one.'
                        : 'No members match "$query".',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
                  itemCount: visibleMembers.length,
                  itemBuilder: (context, i) => _buildCard(visibleMembers[i]),
                ),
        ),
        _buildActionBar(),
      ],
    );
  }

  Widget _buildHeaderBlock() {
    return Container(
      width: double.infinity,
      color: AppTheme.headerBlue.withOpacity(0.06),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY SATSANG ATTENDANCE CHART - ${widget.category.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const Text('IIT SURYA NAGAR - UNIT NO. 1740',
              style: TextStyle(fontSize: 11)),
          const SizedBox(height: 2),
          Text('DAY: ${widget.day}    DATE: ${widget.date}',
              style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Widget _buildCard(Member m) {
    final status = _status[m.id!] ?? '';
    final pv = _pvValue[m.id!] ?? '';
    final avatarColor = widget.category == 'Gents'
        ? const Color(0xFFEAB966)
        : const Color(0xFF1A7AC5);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: avatarColor.withOpacity(0.25),
              child: Text(_initials(m.name),
                  style: TextStyle(
                      color: avatarColor.withOpacity(1),
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _editMember(m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${m.srNo}.',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(m.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    Text('${m.perNo} ${m.snsdNo}'.trim(),
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            _statusChip('P', status == 'Present', AppTheme.presentGreen,
                () => setState(() => _status[m.id!] = 'Present')),
            const SizedBox(width: 4),
            _statusChip('A', status == 'Absent', AppTheme.absentRed,
                () => setState(() => _status[m.id!] = 'Absent')),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _openPvPicker(m),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                constraints: const BoxConstraints(minWidth: 78),
                decoration: BoxDecoration(
                  color: pv.isEmpty
                      ? Colors.grey.shade100
                      : AppTheme.headerBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: pv.isEmpty
                          ? Colors.grey.shade300
                          : AppTheme.headerBlue.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time,
                        size: 13,
                        color: pv.isEmpty ? Colors.grey : AppTheme.headerBlue),
                    const SizedBox(width: 4),
                    Text(
                      pv.isEmpty ? 'PV/PC' : pv,
                      style: TextStyle(
                        fontSize: 11,
                        color: pv.isEmpty
                            ? Colors.grey.shade600
                            : AppTheme.headerBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(
      String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _saveAll,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: const Text('Save & Verify'),
              ),
            ),
            const SizedBox(width: 8),
            _roundIconButton(Icons.picture_as_pdf, 'Export PDF', _exportPdf),
            _roundIconButton(Icons.image, 'Export Image', _exportPng),
            _roundIconButton(Icons.table_chart, 'Export Excel', _exportExcel),
            _roundIconButton(
                Icons.person_add, 'Add Member', () => _editMember(null)),
          ],
        ),
      ),
    );
  }

  Widget _roundIconButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: AppTheme.headerBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(icon, color: AppTheme.headerBlue),
        ),
      ),
    );
  }

  Future<void> _editMember(Member? m) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MemberFormScreen(category: widget.category, member: m),
      ),
    );
    if (result == true) _load();
  }
}
