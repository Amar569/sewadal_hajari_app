import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/member.dart';

class MemberFormScreen extends StatefulWidget {
  final String category;
  final Member? member; // null = add new
  const MemberFormScreen({super.key, required this.category, this.member});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _srNoCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _perNoCtrl;
  late TextEditingController _snsdCtrl;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _srNoCtrl = TextEditingController(text: m?.srNo.toString() ?? '');
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _perNoCtrl = TextEditingController(text: m?.perNo ?? 'SNSD2015');
    _snsdCtrl = TextEditingController(text: m?.snsdNo ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = DatabaseHelper.instance;
    final member = Member(
      id: widget.member?.id,
      srNo: int.parse(_srNoCtrl.text.trim()),
      name: _nameCtrl.text.trim(),
      perNo: _perNoCtrl.text.trim(),
      snsdNo: _snsdCtrl.text.trim(),
      category: widget.category,
    );
    if (widget.member == null) {
      await db.insertMember(member);
    } else {
      await db.updateMember(member);
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    if (widget.member?.id == null) return;
    await DatabaseHelper.instance.deleteMember(widget.member!.id!);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.member != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Member' : 'Add Member (${widget.category})'),
        actions: [
          if (isEdit)
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _srNoCtrl,
                decoration: const InputDecoration(labelText: 'Sr. No'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || int.tryParse(v) == null)
                    ? 'Enter a valid number'
                    : null,
              ),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              TextFormField(
                controller: _perNoCtrl,
                decoration:
                    const InputDecoration(labelText: 'Per. No (e.g. SNSD2015)'),
              ),
              TextFormField(
                controller: _snsdCtrl,
                decoration: const InputDecoration(labelText: 'SNSD Number'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: _save, child: const Text('Save Member')),
            ],
          ),
        ),
      ),
    );
  }
}
