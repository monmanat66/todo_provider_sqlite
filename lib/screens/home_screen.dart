import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import 'task_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _enterSelection([Todo? first]) {
    setState(() {
      _selectionMode = true;
      _selectedIds.clear();
      if (first?.id != null) _selectedIds.add(first!.id!);
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelect(Todo t) {
    final id = t.id;
    if (id == null) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  Future<void> _addTaskSheet(BuildContext context) async {
    final formInit = TaskFormData();
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (_) => TaskForm(
        initial: formInit,
        onSubmit: (data) async {
          await context.read<TodoProvider>().addTodo(
                data.title,
                notes: data.notes,
                dueAt: data.dueDate?.millisecondsSinceEpoch,
                priority: data.priority,
                tags: data.tags,
              );
        },
      ),
    );
  }

  Future<void> _editTaskSheet(BuildContext context, Todo todo) async {
    final formInit = TaskFormData()
      ..title = todo.title
      ..notes = todo.notes
      ..dueDate = todo.dueAtMillis != null ? DateTime.fromMillisecondsSinceEpoch(todo.dueAtMillis!) : null
      ..priority = todo.priority
      ..tags = todo.tags;
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (_) => TaskForm(
        initial: formInit,
        onSubmit: (data) async {
          await context.read<TodoProvider>().editTodo(
                todo,
                title: data.title,
                notes: data.notes,
                dueAt: data.dueDate?.millisecondsSinceEpoch,
                priority: data.priority,
                tags: data.tags,
              );
        },
      ),
    );
  }

  void _showUndoSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ลบงานแล้ว'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => context.read<TodoProvider>().undoDelete(),
        ),
      ),
    );
  }

  String _priorityText(int p) => switch (p) { 2 => 'High', 1 => 'Med', _ => 'Low' };
  Color _priorityColor(BuildContext c, int p) {
    final cs = Theme.of(c).colorScheme;
    return switch (p) {
      2 => cs.error,
      1 => cs.tertiary,
      _ => cs.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TodoProvider>();
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('dd MMM');

    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text('เลือกแล้ว ${_selectedIds.length} รายการ')
            : const Text('งานของฉัน'),
        leading: _selectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: _exitSelection)
            : null,
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedIds.isEmpty ? null : () async {
                final items = List<Todo>.from(p.items);
                for (final t in items) {
                  if (t.id != null && _selectedIds.contains(t.id)) {
                    await p.deleteTodo(t);
                  }
                }
                if (mounted) {
                  _exitSelection();
                  _showUndoSnack(context);
                }
              },
            )
          else ...[
            PopupMenuButton(
              tooltip: 'Sort',
              icon: const Icon(Icons.sort),
              onSelected: (value) {
                p.setSortMode(value as SortMode);
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: SortMode.due,
                  checked: p.sortMode == SortMode.due,
                  child: const Text('ตามกำหนด (Due Date)'),
                ),
                CheckedPopupMenuItem(
                  value: SortMode.priority,
                  checked: p.sortMode == SortMode.priority,
                  child: const Text('ตาม Priority'),
                ),
                CheckedPopupMenuItem(
                  value: SortMode.created,
                  checked: p.sortMode == SortMode.created,
                  child: const Text('ล่าสุด'),
                ),
              ],
            ),
            IconButton(
              tooltip: p.showCompleted ? 'ซ่อนงานที่เสร็จ' : 'แสดงงานที่เสร็จ',
              icon: Icon(p.showCompleted ? Icons.visibility : Icons.visibility_off),
              onPressed: () => p.setShowCompleted(!p.showCompleted),
            ),
          ],
        ],
      ),
      floatingActionButton: !_selectionMode
          ? FloatingActionButton.extended(
              onPressed: () => _addTaskSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มงาน'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาชื่องานหรือแท็ก (#เรียน, #งาน)',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                p.setQuery('');
                              },
                            ),
                    ),
                    onChanged: p.setQuery,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Chip(
                    label: Text('ทั้งหมด ${p.totalCount}'),
                    backgroundColor: cs.primaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('ค้าง ${p.activeCount}'),
                    backgroundColor: cs.secondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('เสร็จ ${p.doneCount}'),
                    backgroundColor: cs.tertiaryContainer,
                  ),
                ]),
                if (!_selectionMode)
                  IconButton(
                    tooltip: 'โหมดเลือกหลายรายการ',
                    icon: const Icon(Icons.checklist),
                    onPressed: p.items.isEmpty ? null : () => _enterSelection(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: p.isLoading
                ? const Center(child: CircularProgressIndicator())
                : p.items.isEmpty
                    ? const Center(child: Text('ยังไม่มีกิจกรรม • กด "เพิ่มงาน"'))
                    : ListView.separated(
                        itemCount: p.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final t = p.items[i];
                          final id = t.id;
                          final selected = id != null && _selectedIds.contains(id);
                          final dueStr = t.dueAtMillis != null ? fmt.format(DateTime.fromMillisecondsSinceEpoch(t.dueAtMillis!)) : null;
                          final overdue = t.dueAtMillis != null && !t.isDone && DateTime.now().millisecondsSinceEpoch > t.dueAtMillis!;

                          Widget tile = ListTile(
                            leading: _selectionMode
                                ? Checkbox(value: selected, onChanged: (_) => _toggleSelect(t))
                                : Checkbox(
                                    value: t.isDone,
                                    onChanged: (_) => p.toggleDone(t),
                                  ),
                            title: Text(
                              t.title,
                              style: TextStyle(
                                decoration: t.isDone ? TextDecoration.lineThrough : null,
                                color: t.isDone ? Colors.grey : null,
                                fontWeight: selected ? FontWeight.w600 : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (t.notes?.isNotEmpty == true) Text(t.notes!),
                                Row(
                                  children: [
                                    if (dueStr != null)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0, top: 4),
                                        child: Chip(
                                          label: Text(dueStr + (overdue ? ' (เลยกำหนด)' : '')),
                                          backgroundColor: overdue ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Chip(
                                        label: Text('Priority ${_priorityText(t.priority)}'),
                                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                                        side: BorderSide(color: _priorityColor(context, t.priority)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                ),
                                if ((t.tags ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: -8,
                                      children: (t.tags ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).map((tag) => Chip(
                                        label: Text('#$tag'),
                                        visualDensity: VisualDensity.compact,
                                      )).toList(),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: _selectionMode
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editTaskSheet(context, t),
                                  ),
                            onTap: () {
                              if (_selectionMode) {
                                _toggleSelect(t);
                              } else {
                                p.toggleDone(t);
                              }
                            },
                            onLongPress: () => _enterSelection(t),
                          );

                          if (_selectionMode) return tile;

                          return Dismissible(
                            key: ValueKey(id ?? '${t.title}-$i'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              color: Colors.red,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('ลบงานนี้หรือไม่?'),
                                  content: Text(t.title),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
                                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) async {
                              await p.deleteTodo(t);
                              if (mounted) _showUndoSnack(context);
                            },
                            child: tile,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
