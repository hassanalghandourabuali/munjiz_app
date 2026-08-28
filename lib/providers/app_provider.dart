import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database_helper.dart';
import '../models/models.dart';

String _uid() {
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${UniqueKey().hashCode.toRadixString(36)}';
}

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Project> projects = [];

  bool _ready = false;

  bool get ready => _ready;

  // ============================================================
  // Theme
  // ============================================================

  ThemeMode themeMode = ThemeMode.system;

  static const _themeKey = 'theme_mode';

  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);

    if (saved == 'light') {
      themeMode = ThemeMode.light;
    } else if (saved == 'dark') {
      themeMode = ThemeMode.dark;
    } else {
      themeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _themeKey,
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
              ? 'dark'
              : 'system',
    );

    notifyListeners();
  }

  // ============================================================
  // [جديد] Demo Project Seeding
  // ============================================================
  // أول مرة بس يُفتح فيها التطبيق، نزرع مشروعًا تجريبيًا جاهزًا فيه
  // أعضاء ومهام بحالات مختلفة، عشان المستخدم يشوف شكل التطبيق وهو
  // "شغال" بدل ما يواجه شاشة فاضية تمامًا. نستخدم فلاغ بـ
  // SharedPreferences حتى لا يتكرر الزرع حتى لو المستخدم حذف
  // المشروع التجريبي أو كل مشاريعه لاحقًا.

  static const _demoSeededKey = 'demo_seeded_v1';

  Future<void> _seedDemoProjectIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySeeded = prefs.getBool(_demoSeededKey) ?? false;

    if (alreadySeeded) {
      return;
    }

    // نسجّل الفلاغ فورًا حتى لو صار خطأ أثناء الزرع، ما يعاد المحاولة
    // بشكل متكرر ويكدّس مشاريع تجريبية.
    await prefs.setBool(_demoSeededKey, true);

    try {
      final project = await createProject(
        name: '🧪 مشروع تجريبي — جرّبيه!',
        description: 'مشروع جاهز لتستكشفي فيه المميزات: الأعضاء، توزيع المهام، '
            'لوحة كانبان، ونسبة التقدم. احذفيه أي وقت وابدئي مشروعك الحقيقي.',
        type: 'project',
      );

      final designer = await addMember(
        project.id,
        name: 'سارة',
        role: 'مصممة',
      );

      final developer = await addMember(
        project.id,
        name: 'أحمد',
        role: 'مطوّر',
      );

      final writer = await addMember(
        project.id,
        name: 'لين',
        role: 'كاتبة محتوى',
      );

      await addTask(
        project.id,
        title: 'تصميم شعار المشروع',
        description: 'مثال على مهمة منجزة — لاحظي شريط التقدم بالأعلى.',
        memberId: designer.id,
        status: 'done',
        priority: 'high',
      );

      await addTask(
        project.id,
        title: 'إعداد قاعدة البيانات المحلية',
        memberId: developer.id,
        status: 'done',
        priority: 'high',
      );

      await addTask(
        project.id,
        title: 'كتابة المحتوى التعريفي',
        description: 'مثال على مهمة قيد التنفيذ.',
        memberId: writer.id,
        status: 'inProgress',
        priority: 'medium',
      );

      await addTask(
        project.id,
        title: 'ربط الواجهة بإدارة الحالة',
        memberId: developer.id,
        status: 'inProgress',
        priority: 'high',
      );

      await addTask(
        project.id,
        title: 'مراجعة نهائية قبل التسليم',
        description: 'مثال على مهمة لسا ما بدأت — جربي تسحبيها بين الأعمدة.',
        status: 'todo',
        priority: 'low',
      );
    } catch (e) {
      debugPrint('خطأ أثناء زرع المشروع التجريبي: $e');
    }
  }

  // ============================================================
  // Initialization
  // ============================================================

  Future<void> init() async {
    await loadThemeMode();
    await _seedDemoProjectIfNeeded(); // [جديد]

    try {
      projects = await _db.getProjects();
    } catch (e) {
      debugPrint('خطأ أثناء تحميل المشاريع: $e');
      projects = [];
    }

    _ready = true;
    notifyListeners();
  }

  // ============================================================
  // Projects
  // ============================================================

  Future<Project> createProject({
    required String name,
    String description = '',
    String? startDate,
    String? endDate,
    String type = 'project', // [جديد] 'project' | 'studyChapter'
  }) async {
    final project = Project(
      id: _uid(),
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now().toIso8601String(),
      type: type, // [جديد]
    );

    await _db.insertProject(project);

    projects.insert(0, project);

    notifyListeners();

    return project;
  }

  Future<void> editProject(Project project) async {
    await _db.updateProject(project);

    final index = projects.indexWhere(
      (item) => item.id == project.id,
    );

    if (index >= 0) {
      projects[index] = project;
    }

    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    await _db.deleteProject(id);

    projects.removeWhere(
      (project) => project.id == id,
    );

    notifyListeners();
  }

  // ============================================================
  // Members
  // ============================================================

  Future<List<Member>> membersOf(String projectId) {
    return _db.getMembers(projectId);
  }

  Future<Member> addMember(
    String projectId, {
    required String name,
    String role = '',
  }) async {
    final member = Member(
      id: _uid(),
      projectId: projectId,
      name: name,
      role: role,
    );

    await _db.insertMember(member);

    notifyListeners();

    return member;
  }

  Future<void> editMember(Member member) async {
    await _db.updateMember(member);

    notifyListeners();
  }

  Future<void> removeMember(String id) async {
    await _db.deleteMember(id);

    notifyListeners();
  }

  // ============================================================
  // Tasks
  // ============================================================

  Future<List<Task>> tasksOf(String projectId) {
    return _db.getTasks(projectId);
  }

  Future<Task> addTask(
    String projectId, {
    required String title,
    String description = '',
    String? memberId,
    String status = 'todo',
    String priority = 'medium',
    String? dueDate,
  }) async {
    final task = Task(
      id: _uid(),
      projectId: projectId,
      memberId: memberId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: dueDate,
      createdAt: DateTime.now().toIso8601String(),
    );

    await _db.insertTask(task);

    notifyListeners();

    return task;
  }

  Future<void> editTask(Task task) async {
    await _db.updateTask(task);

    notifyListeners();
  }

  Future<void> removeTask(String id) async {
    await _db.deleteTask(id);

    notifyListeners();
  }

  // ============================================================
  // Statistics
  // ============================================================

  Future<Map<String, dynamic>> statsOf(String projectId) async {
    final tasks = await _db.getTasks(projectId);

    final total = tasks.length;

    final done = tasks
        .where(
          (task) => task.status == 'done',
        )
        .length;

    final inProgress = tasks
        .where(
          (task) => task.status == 'inProgress',
        )
        .length;

    final todo = tasks
        .where(
          (task) => task.status == 'todo',
        )
        .length;

    final progress = total == 0 ? 0 : (done * 100 ~/ total);

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final overdue = tasks.where((task) {
      if (task.status == 'done') {
        return false;
      }

      if (task.dueDate == null) {
        return false;
      }

      final parsedDate = DateTime.tryParse(
        task.dueDate!,
      );

      if (parsedDate == null) {
        return false;
      }

      final dateOnly = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
      );

      return dateOnly.isBefore(today);
    }).length;

    return {
      'total': total,
      'done': done,
      'inProgress': inProgress,
      'todo': todo,
      'progress': progress,
      'overdue': overdue,
    };
  }

  // [جديد] نسبة مساهمة كل عضو — تُستخدم بشاشة "لحظة الإنجاز"
  Future<List<Map<String, dynamic>>> memberContributions(
    String projectId,
  ) async {
    final tasks = await _db.getTasks(projectId);
    final members = await _db.getMembers(projectId);

    final doneTasks = tasks
        .where(
          (task) => task.status == 'done',
        )
        .toList();

    final totalDone = doneTasks.length;

    final result = <Map<String, dynamic>>[];

    for (final member in members) {
      final memberDone = doneTasks
          .where(
            (task) => task.memberId == member.id,
          )
          .length;

      final percentage = totalDone == 0 ? 0 : (memberDone * 100 ~/ totalDone);

      result.add({
        'member': member,
        'doneCount': memberDone,
        'percentage': percentage,
      });
    }

    // ترتيب تنازلي حسب المساهمة
    result.sort(
      (a, b) => (b['doneCount'] as int).compareTo(a['doneCount'] as int),
    );

    return result;
  }

  // ============================================================
  // [جديد] Lessons Learned
  // ============================================================

  Future<List<LessonLearned>> lessonsLearnedOf(String projectId) {
    return _db.getLessonsLearned(projectId);
  }

  Future<LessonLearned> addLessonLearned(
    String projectId, {
    required String note,
  }) async {
    final lesson = LessonLearned(
      id: _uid(),
      projectId: projectId,
      note: note,
      createdAt: DateTime.now().toIso8601String(),
    );

    await _db.insertLessonLearned(lesson);

    notifyListeners();

    return lesson;
  }

  Future<void> removeLessonLearned(String id) async {
    await _db.deleteLessonLearned(id);

    notifyListeners();
  }

  // ============================================================
  // [جديد] Completion Celebration Tracking
  // ============================================================
  // يستخدم SharedPreferences لتذكّر أي وحدة (مشروع/مادة) تم الاحتفال
  // بإنجازها من قبل، حتى لا تظهر شاشة الاحتفال أكثر من مرة لنفس الوحدة.

  static const _celebratedKey = 'celebrated_project_ids';

  Future<bool> hasCelebrated(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_celebratedKey) ?? [];
    return list.contains(projectId);
  }

  Future<void> markCelebrated(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_celebratedKey) ?? [];

    if (!list.contains(projectId)) {
      list.add(projectId);
      await prefs.setStringList(_celebratedKey, list);
    }
  }

  // ============================================================
  // Export
  // ============================================================

  Future<Map<String, dynamic>> exportProject(
    String projectId,
  ) async {
    final projectIndex = projects.indexWhere(
      (project) => project.id == projectId,
    );

    if (projectIndex < 0) {
      throw Exception('المشروع غير موجود');
    }

    final project = projects[projectIndex];

    final members = await _db.getMembers(projectId);
    final tasks = await _db.getTasks(projectId);

    return {
      'munjiz': true,
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'project': project.toJson(), // [جديد] toJson تتضمن type تلقائيًا الآن
      'members': members.map((member) => member.toJson()).toList(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
  }

  // ============================================================
  // Import
  // ============================================================

  Future<Project> importProject(
    Map<String, dynamic> json,
  ) async {
    if (json['munjiz'] != true) {
      throw Exception('الملف ليس ملف مشروع مُنجز صالح');
    }

    final projectJson = json['project'];

    if (projectJson is! Map) {
      throw Exception('بيانات المشروع غير موجودة');
    }

    final newProjectId = _uid();

    final Map<String, String> memberIdMap = {};

    final membersJson = json['members'];

    if (membersJson is List) {
      for (final item in membersJson) {
        if (item is! Map) {
          continue;
        }

        final oldMemberId = item['id']?.toString();

        if (oldMemberId == null || oldMemberId.isEmpty) {
          continue;
        }

        final newMemberId = _uid();

        memberIdMap[oldMemberId] = newMemberId;

        final member = Member(
          id: newMemberId,
          projectId: newProjectId,
          name: item['name']?.toString() ?? 'عضو',
          role: item['role']?.toString() ?? '',
        );

        await _db.insertMember(member);
      }
    }

    final tasksJson = json['tasks'];

    if (tasksJson is List) {
      for (final item in tasksJson) {
        if (item is! Map) {
          continue;
        }

        final oldMemberId = item['memberId']?.toString();

        String? newMemberId;

        if (oldMemberId != null) {
          newMemberId = memberIdMap[oldMemberId];
        }

        final task = Task(
          id: _uid(),
          projectId: newProjectId,
          memberId: newMemberId,
          title: item['title']?.toString() ?? 'مهمة',
          description: item['description']?.toString() ?? '',
          status: _validStatus(
            item['status']?.toString(),
          ),
          priority: _validPriority(
            item['priority']?.toString(),
          ),
          dueDate: item['dueDate']?.toString(),
          createdAt: DateTime.now().toIso8601String(),
        );

        await _db.insertTask(task);
      }
    }

    final project = Project(
      id: newProjectId,
      name: projectJson['name']?.toString() ?? 'مشروع مستورد',
      description: projectJson['description']?.toString() ?? '',
      startDate: projectJson['startDate']?.toString(),
      endDate: projectJson['endDate']?.toString(),
      createdAt: DateTime.now().toIso8601String(),
      type: projectJson['type']?.toString() ?? 'project', // [جديد]
    );

    await _db.insertProject(project);

    projects.insert(0, project);

    notifyListeners();

    return project;
  }

  // ============================================================
  // Validation Helpers
  // ============================================================

  String _validStatus(String? status) {
    if (status != null && statusLabels.containsKey(status)) {
      return status;
    }

    return 'todo';
  }

  String _validPriority(String? priority) {
    if (priority != null && priorityLabels.containsKey(priority)) {
      return priority;
    }

    return 'medium';
  }

  // ============================================================
  // JSON Encoding
  // ============================================================

  String encodeExport(
    Map<String, dynamic> data,
  ) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
