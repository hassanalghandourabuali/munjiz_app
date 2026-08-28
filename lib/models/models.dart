class Project {
  final String id;
  final String name;
  final String description;
  final String? startDate;
  final String? endDate;
  final String createdAt;
  final String type; // 'project' | 'studyChapter'   // [جديد]

  Project({
    required this.id,
    required this.name,
    this.description = '',
    this.startDate,
    this.endDate,
    required this.createdAt,
    this.type =
        'project', // [جديد] القيمة الافتراضية تحافظ على البيانات القديمة
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'start_date': startDate,
        'end_date': endDate,
        'created_at': createdAt,
        'type': type, // [جديد]
      };

  factory Project.fromMap(Map<String, dynamic> m) => Project(
        id: m['id'] as String,
        name: m['name'] as String,
        description: (m['description'] as String?) ?? '',
        startDate: m['start_date'] as String?,
        endDate: m['end_date'] as String?,
        createdAt: m['created_at'] as String,
        type: (m['type'] as String?) ?? 'project', // [جديد]
      );

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] ?? '',
        startDate: j['startDate'],
        endDate: j['endDate'],
        createdAt: j['createdAt'] ?? DateTime.now().toIso8601String(),
        type: j['type'] ?? 'project', // [جديد]
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'startDate': startDate,
        'endDate': endDate,
        'createdAt': createdAt,
        'type': type, // [جديد]
      };
}

class Member {
  final String id;
  final String projectId;
  final String name;
  final String role;

  Member({
    required this.id,
    required this.projectId,
    required this.name,
    this.role = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'project_id': projectId,
        'name': name,
        'role': role,
      };

  factory Member.fromMap(Map<String, dynamic> m) => Member(
        id: m['id'] as String,
        projectId: m['project_id'] as String,
        name: m['name'] as String,
        role: (m['role'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'role': role,
      };
}

class Task {
  final String id;
  final String projectId;
  String? memberId;
  String title;
  String description;
  String status; // todo | inProgress | done
  String priority; // high | medium | low
  final String? dueDate;
  final String createdAt;

  Task({
    required this.id,
    required this.projectId,
    this.memberId,
    required this.title,
    this.description = '',
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'project_id': projectId,
        'member_id': memberId,
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'due_date': dueDate,
        'created_at': createdAt,
      };

  factory Task.fromMap(Map<String, dynamic> m) => Task(
        id: m['id'] as String,
        projectId: m['project_id'] as String,
        memberId: m['member_id'] as String?,
        title: m['title'] as String,
        description: (m['description'] as String?) ?? '',
        status: m['status'] as String,
        priority: m['priority'] as String,
        dueDate: m['due_date'] as String?,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'memberId': memberId,
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'dueDate': dueDate,
        'createdAt': createdAt,
      };
}

// [جديد] كلاس جديد بالكامل — يخزّن إجابة "الدرس المستفاد" عند اكتمال أي وحدة
class LessonLearned {
  final String id;
  final String projectId;
  final String note;
  final String createdAt;

  LessonLearned({
    required this.id,
    required this.projectId,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'project_id': projectId,
        'note': note,
        'created_at': createdAt,
      };

  factory LessonLearned.fromMap(Map<String, dynamic> m) => LessonLearned(
        id: m['id'] as String,
        projectId: m['project_id'] as String,
        note: m['note'] as String,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'note': note,
        'createdAt': createdAt,
      };
}

const statusLabels = {
  'todo': 'لم تبدأ',
  'inProgress': 'قيد التنفيذ',
  'done': 'منجزة',
};

const statusOrder = [
  'todo',
  'inProgress',
  'done',
];

const priorityLabels = {
  'high': 'عالية',
  'medium': 'متوسطة',
  'low': 'منخفضة',
};

// [جديد] تسميات نوع الوحدة (مشروع / مادة دراسية)
const unitTypeLabels = {
  'project': 'مشروع',
  'studyChapter': 'مادة/شابتر دراسي',
};
