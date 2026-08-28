import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }

    final databasePath = await getDatabasesPath();
    final path = p.join(databasePath, 'munjiz.db');

    _db = await openDatabase(
      path,
      version: 2, // [جديد] كان 1 — رُفع بسبب إضافة عمود type وجدول lessons_learned
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE projects(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            start_date TEXT,
            end_date TEXT,
            created_at TEXT NOT NULL,
            type TEXT NOT NULL DEFAULT 'project'
          )
        ''');
        // [جديد] عمود type أُضيف مباشرة هون لأي تثبيت جديد للتطبيق

        await database.execute('''
          CREATE TABLE members(
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL,
            name TEXT NOT NULL,
            role TEXT,
            FOREIGN KEY(project_id)
              REFERENCES projects(id)
              ON DELETE CASCADE
          )
        ''');

        await database.execute('''
          CREATE TABLE tasks(
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL,
            member_id TEXT,
            title TEXT NOT NULL,
            description TEXT,
            status TEXT NOT NULL,
            priority TEXT NOT NULL,
            due_date TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY(project_id)
              REFERENCES projects(id)
              ON DELETE CASCADE,
            FOREIGN KEY(member_id)
              REFERENCES members(id)
              ON DELETE SET NULL
          )
        ''');

        // [جديد] جدول جديد بالكامل — يخزّن إجابات "الدرس المستفاد"
        await database.execute('''
          CREATE TABLE lessons_learned(
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL,
            note TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(project_id)
              REFERENCES projects(id)
              ON DELETE CASCADE
          )
        ''');

        await database.execute('''
          CREATE INDEX idx_members_project_id
          ON members(project_id)
        ''');

        await database.execute('''
          CREATE INDEX idx_tasks_project_id
          ON tasks(project_id)
        ''');

        await database.execute('''
          CREATE INDEX idx_tasks_member_id
          ON tasks(member_id)
        ''');

        // [جديد]
        await database.execute('''
          CREATE INDEX idx_lessons_project_id
          ON lessons_learned(project_id)
        ''');
      },
      // [جديد] onUpgrade كامل — يشتغل فقط عند من عنده قاعدة بيانات قديمة (version 1)
      // بدون ما يمسح أي بيانات موجودة عندهم
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute('''
            ALTER TABLE projects
            ADD COLUMN type TEXT NOT NULL DEFAULT 'project'
          ''');

          await database.execute('''
            CREATE TABLE lessons_learned(
              id TEXT PRIMARY KEY,
              project_id TEXT NOT NULL,
              note TEXT NOT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY(project_id)
                REFERENCES projects(id)
                ON DELETE CASCADE
            )
          ''');

          await database.execute('''
            CREATE INDEX idx_lessons_project_id
            ON lessons_learned(project_id)
          ''');
        }
      },
    );

    return _db!;
  }

  // ============================================================
  // Projects
  // ============================================================

  Future<List<Project>> getProjects() async {
    final database = await db;

    final rows = await database.query(
      'projects',
      orderBy: 'created_at DESC',
    );

    return rows.map(Project.fromMap).toList();
  }

  Future<Project> insertProject(Project project) async {
    final database = await db;

    await database.insert(
      'projects',
      project.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return project;
  }

  Future<void> updateProject(Project project) async {
    final database = await db;

    await database.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<void> deleteProject(String id) async {
    final database = await db;

    await database.transaction((transaction) async {
      await transaction.delete(
        'tasks',
        where: 'project_id = ?',
        whereArgs: [id],
      );

      await transaction.delete(
        'members',
        where: 'project_id = ?',
        whereArgs: [id],
      );

      // [جديد] حذف الدروس المستفادة المرتبطة عند حذف الوحدة
      await transaction.delete(
        'lessons_learned',
        where: 'project_id = ?',
        whereArgs: [id],
      );

      await transaction.delete(
        'projects',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ============================================================
  // Members
  // ============================================================

  Future<List<Member>> getMembers(String projectId) async {
    final database = await db;

    final rows = await database.query(
      'members',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'name ASC',
    );

    return rows.map(Member.fromMap).toList();
  }

  Future<Member> insertMember(Member member) async {
    final database = await db;

    await database.insert(
      'members',
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return member;
  }

  Future<void> updateMember(Member member) async {
    final database = await db;

    await database.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<void> deleteMember(String id) async {
    final database = await db;

    await database.transaction((transaction) async {
      await transaction.update(
        'tasks',
        {'member_id': null},
        where: 'member_id = ?',
        whereArgs: [id],
      );

      await transaction.delete(
        'members',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ============================================================
  // Tasks
  // ============================================================

  Future<List<Task>> getTasks(String projectId) async {
    final database = await db;

    final rows = await database.query(
      'tasks',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'created_at DESC',
    );

    return rows.map(Task.fromMap).toList();
  }

  Future<Task> insertTask(Task task) async {
    final database = await db;

    await database.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return task;
  }

  Future<void> updateTask(Task task) async {
    final database = await db;

    await database.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final database = await db;

    await database.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // [جديد] Lessons Learned
  // ============================================================

  Future<List<LessonLearned>> getLessonsLearned(String projectId) async {
    final database = await db;

    final rows = await database.query(
      'lessons_learned',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'created_at DESC',
    );

    return rows.map(LessonLearned.fromMap).toList();
  }

  Future<LessonLearned> insertLessonLearned(LessonLearned lesson) async {
    final database = await db;

    await database.insert(
      'lessons_learned',
      lesson.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return lesson;
  }

  Future<void> deleteLessonLearned(String id) async {
    final database = await db;

    await database.delete(
      'lessons_learned',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}