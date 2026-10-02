import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'attendance_tab.dart';
import 'exports_screen.dart';
import '../theme/app_theme.dart';
import '../services/export_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _dayStr => DateFormat('EEEE').format(_selectedDate);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _editHeader() async {
  final ctrl = TextEditingController(text: await ExportService.loadHeader());
  if (!mounted) return;
  final saved = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Report header'),
      content: TextField(
        controller: ctrl,
        maxLength: 60,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          hintText: 'e.g. SATSANG BHAWAN',
          helperText: 'Shown at the top of every PDF, image and Excel file.\nLeave empty for no header.',
          helperMaxLines: 2,
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save')),
      ],
    ),
  );
  if (saved == null) return;
  await ExportService.saveHeader(saved);
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Header saved. It will appear in new exports.')),
  );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.headerBlue,
                  AppTheme.headerBlue.withOpacity(0.8),
                ],
              ),
            ),
          ),
          title: const Text(
            'Sewadal Hajari Book',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(21),
                    color: Colors.white,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(3),
                  dividerColor: Colors.transparent,
                  labelColor: AppTheme.headerBlue,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: 'GENTS'),
                    Tab(text: 'LADIES'),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Saved PDF/Excel',
              icon: const Icon(Icons.folder_open),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportsScreen()),
              ),
            ),
            IconButton(
              tooltip: 'Edit report header',
              icon: const Icon(Icons.title),
              onPressed: _editHeader,
            ),
          ],
        ),
        body: Column(
          children: [
            // ---- Date row ----
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: AppTheme.headerBlue),
                  const SizedBox(width: 8),
                  Text('$_dayStr, $_dateStr',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.headerBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Change Date',
                        style: TextStyle(
                          color: AppTheme.headerBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ---- Search bar ----
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search member by name...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  filled: true,
                  fillColor: const Color(0xFFF4F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  AttendanceTab(
                    category: 'Gents',
                    day: _dayStr,
                    date: _dateStr,
                    searchQuery: _searchQuery,
                  ),
                  AttendanceTab(
                    category: 'Ladies',
                    day: _dayStr,
                    date: _dateStr,
                    searchQuery: _searchQuery,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
