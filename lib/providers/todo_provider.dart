import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../services/todo_db.dart';

enum SortMode { created, due, priority }

class TodoProvider extends ChangeNotifier {
  final _db = TodoDB();
  List<Todo> _items = [];
  bool _isLoading = false;

  // UI states
  String _query = '';
  bool _showCompleted = true;
  SortMode _sortMode = SortMode.due;

  // last deleted for undo
  Todo? _lastDeleted;

  List<Todo> get items => _applyView();
  bool get isLoading => _isLoading;
  String get query => _query;
  bool get showCompleted => _showCompleted;
  SortMode get sortMode => _sortMode;

  int get totalCount => _items.length;
  int get doneCount => _items.where((e) => e.isDone).length;
  int get activeCount => totalCount - doneCount;

  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();
    _items = await _db.getTodos();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTodo(String title, {String? notes, int? dueAt, int priority = 0, String? tags}) async {
    if (title.trim().isEmpty) return;
    final todo = Todo(title: title.trim(), notes: notes, dueAtMillis: dueAt, priority: priority, tags: tags);
    await _db.insertTodo(todo);
    await loadTodos();
  }

  Future<void> toggleDone(Todo todo) async {
    final updated = Todo(
      id: todo.id,
      title: todo.title,
      notes: todo.notes,
      dueAtMillis: todo.dueAtMillis,
      priority: todo.priority,
      isDone: !todo.isDone,
      tags: todo.tags,
      createdAt: todo.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.updateTodo(updated);
    final idx = _items.indexWhere((t) => t.id == todo.id);
    if (idx != -1) {
      _items[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> editTodo(Todo todo, {String? title, String? notes, int? dueAt, int? priority, String? tags}) async {
    final updated = Todo(
      id: todo.id,
      title: title ?? todo.title,
      notes: notes ?? todo.notes,
      dueAtMillis: dueAt ?? todo.dueAtMillis,
      priority: priority ?? todo.priority,
      isDone: todo.isDone,
      tags: tags ?? todo.tags,
      createdAt: todo.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.updateTodo(updated);
    final idx = _items.indexWhere((t) => t.id == todo.id);
    if (idx != -1) {
      _items[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteTodo(Todo todo) async {
    if (todo.id == null) return;
    _lastDeleted = todo;
    await _db.deleteTodo(todo.id!);
    _items.removeWhere((t) => t.id == todo.id);
    notifyListeners();
  }

  Future<void> undoDelete() async {
    final t = _lastDeleted;
    if (t == null) return;
    _lastDeleted = null;
    await _db.insertTodo(t);
    await loadTodos();
  }

  Future<void> clearAll() async {
    await _db.clearAll();
    _items = [];
    notifyListeners();
  }

  // view helpers
  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setShowCompleted(bool show) {
    _showCompleted = show;
    notifyListeners();
  }

  void setSortMode(SortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  List<Todo> _applyView() {
    Iterable<Todo> list = _items;

    // filter by completed
    if (!_showCompleted) {
      list = list.where((e) => !e.isDone);
    }

    // filter by query in title or tags
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) =>
          e.title.toLowerCase().contains(q) ||
          (e.tags ?? '').toLowerCase().contains(q));
    }

    // sort
    final l = list.toList();
    switch (_sortMode) {
      case SortMode.created:
        l.sort((a, b) => (b.createdAt).compareTo(a.createdAt));
        break;
      case SortMode.due:
        int val(int? x) => x ?? 9999999999999;
        l.sort((a, b) {
          final ad = val(a.dueAtMillis);
          final bd = val(b.dueAtMillis);
          if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
          final cmp = ad.compareTo(bd);
          if (cmp != 0) return cmp;
          return b.priority.compareTo(a.priority);
        });
        break;
      case SortMode.priority:
        l.sort((a, b) {
          if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
          return b.priority.compareTo(a.priority);
        });
        break;
    }
    return l;
  }
}
