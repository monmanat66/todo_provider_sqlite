class Todo {
  final int? id;
  String title;
  String? notes;
  int? dueAtMillis; // nullable
  int priority; // 0=low,1=medium,2=high
  bool isDone;
  String? tags; // comma-separated tags, e.g. "school,work"
  int createdAt;
  int updatedAt;

  Todo({
    this.id,
    required this.title,
    this.notes,
    this.dueAtMillis,
    this.priority = 0,
    this.isDone = false,
    this.tags,
    int? createdAt,
    int? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'due_at': dueAtMillis,
      'priority': priority,
      'is_done': isDone ? 1 : 0,
      'tags': tags,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int?,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      dueAtMillis: map['due_at'] as int?,
      priority: (map['priority'] as int?) ?? 0,
      isDone: (map['is_done'] as int? ?? 0) == 1,
      tags: map['tags'] as String?,
      createdAt: (map['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: (map['updated_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
