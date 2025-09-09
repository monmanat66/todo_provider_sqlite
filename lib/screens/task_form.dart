import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskFormData {
  String title = '';
  String? notes;
  DateTime? dueDate;
  int priority = 0;
  String? tags; // comma-separated
}

class TaskForm extends StatefulWidget {
  final TaskFormData initial;
  final void Function(TaskFormData) onSubmit;
  const TaskForm({super.key, required this.initial, required this.onSubmit});

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late TaskFormData data;
  final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    data = TaskFormData()
      ..title = widget.initial.title
      ..notes = widget.initial.notes
      ..dueDate = widget.initial.dueDate
      ..priority = widget.initial.priority
      ..tags = widget.initial.tags;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = now.subtract(const Duration(days: 0));
    final last = now.add(const Duration(days: 365 * 3));
    final picked = await showDatePicker(
      context: context,
      initialDate: data.dueDate ?? now,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) setState(() => data.dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: data.title,
              decoration: const InputDecoration(
                labelText: 'ชื่องาน',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'กรอกชื่องาน' : null,
              onSaved: (v) => data.title = v!.trim(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: data.notes,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด (notes)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onSaved: (v) => data.notes = v?.trim().isEmpty == true ? null : v?.trim(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'กำหนดเสร็จ (due date)',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(data.dueDate == null
                          ? 'ไม่กำหนด'
                          : _dateFmt.format(data.dueDate!)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: data.priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Low')),
                      DropdownMenuItem(value: 1, child: Text('Medium')),
                      DropdownMenuItem(value: 2, child: Text('High')),
                    ],
                    onChanged: (v) => setState(() => data.priority = v ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: data.tags,
              decoration: const InputDecoration(
                labelText: 'Tags (คั่นด้วย ,)',
                border: OutlineInputBorder(),
              ),
              onSaved: (v) => data.tags = v?.trim().isEmpty == true ? null : v?.trim(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('บันทึก'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    widget.onSubmit(data);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
