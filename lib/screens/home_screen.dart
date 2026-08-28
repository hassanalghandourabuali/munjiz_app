import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';
import 'project_detail_screen.dart';
import 'widgets/project_form_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ============================================================
  // Import Project
  // ============================================================

  Future<void> _importProject() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final bytes = result.files.single.bytes;

      if (bytes == null) {
        throw Exception('تعذر قراءة الملف');
      }

      final content = utf8.decode(bytes);

      final decoded = jsonDecode(content);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('تنسيق ملف المشروع غير صحيح');
      }

      if (!mounted) return;

      final project = await context.read<AppProvider>().importProject(
            decoded,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم استيراد المشروع "${project.name}" بنجاح',
          ),
        ),
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(project.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل استيراد المشروع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // Create Project
  // ============================================================

  Future<void> _createProject() async {
    await showDialog(
      context: context,
      builder: (_) => const ProjectFormDialog(),
    );
  }

  // ============================================================
  // Open Project
  // ============================================================

  void _openProject(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(project.id),
      ),
    );
  }

  // ============================================================
  // Theme Menu
  // ============================================================

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  Widget _buildThemeMenu(AppProvider app) {
    return PopupMenuButton<ThemeMode>(
      icon: Icon(_themeIcon(app.themeMode)),
      tooltip: 'تبديل المظهر',
      onSelected: (mode) {
        app.setThemeMode(mode);
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: ThemeMode.light,
          checked: app.themeMode == ThemeMode.light,
          child: const Text('فاتح'),
        ),
        CheckedPopupMenuItem(
          value: ThemeMode.dark,
          checked: app.themeMode == ThemeMode.dark,
          child: const Text('داكن'),
        ),
        CheckedPopupMenuItem(
          value: ThemeMode.system,
          checked: app.themeMode == ThemeMode.system,
          child: const Text('حسب النظام'),
        ),
      ],
    );
  }

  // ============================================================
  // Unit Type Badge  [جديد]
  // ============================================================
  // شارة صغيرة تبيّن نوع الوحدة (مشروع / مادة دراسية) جنب كل عنصر بالقائمة.

  IconData _unitTypeIcon(String type) {
    switch (type) {
      case 'studyChapter':
        return Icons.menu_book_outlined;
      case 'project':
      default:
        return Icons.work_outline;
    }
  }

  Widget _buildUnitTypeBadge(BuildContext context, String type) {
    final label = unitTypeLabels[type] ?? unitTypeLabels['project']!;
    final color = type == 'studyChapter'
        ? Colors.teal
        : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_unitTypeIcon(type), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مُنجز',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          _buildThemeMenu(app),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'استيراد مشروع',
            onPressed: _importProject,
          ),
        ],
      ),
      body: !app.ready
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : app.projects.isEmpty
              ? _buildEmptyState()
              : _buildProjectsList(app),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('مشروع جديد'),
        onPressed: _createProject,
      ),
    );
  }

  // ============================================================
  // Empty State  [محدّث] — رسالة إرشادية بدل الشاشة الفارغة البسيطة
  // ============================================================
  // هذه الشاشة ما رح تظهر عادةً لأنه فيه مشروع تجريبي بيُزرع تلقائيًا
  // أول تشغيل (راجعي app_provider.dart)، بس بتظهر لو المستخدم حذف كل
  // مشاريعه لاحقًا — فبدل ما تكون فاضية بالكامل، بنشرح له بسرعة شو
  // يقدر يعمل بالتطبيق.

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد مشاريع بعد',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'اضغطي على "مشروع جديد" وابدئي — تقدري تختاري مشروع '
              'جماعي أو مادة دراسية.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 28),

            // [جديد] بطاقة نصائح سريعة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'شو تقدري تعملي بتطبيق مُنجز؟',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTipRow(
                    Icons.group_outlined,
                    'وزّعي المهام على أعضاء الفريق وتابعي مين مسؤول عن شو.',
                  ),
                  const SizedBox(height: 10),
                  _buildTipRow(
                    Icons.view_kanban_outlined,
                    'استخدمي لوحة كانبان لسحب المهام بين "لم تبدأ"، "قيد التنفيذ"، و"منجزة".',
                  ),
                  const SizedBox(height: 10),
                  _buildTipRow(
                    Icons.celebration_outlined,
                    'لما توصلي 100%، رح تنفتح شاشة احتفال فيها ملخص مساهمة كل عضو.',
                  ),
                  const SizedBox(height: 10),
                  _buildTipRow(
                    Icons.wifi_off_outlined,
                    'كل شي بيتخزّن على جهازك مباشرة — بيشتغل حتى بدون إنترنت.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [جديد] سطر نصيحة واحد بالبطاقة الإرشادية
  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Projects List
  // ============================================================

  Widget _buildProjectsList(AppProvider app) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: app.projects.length,
      itemBuilder: (context, index) {
        final project = app.projects[index];

        return FutureBuilder<Map<String, dynamic>>(
          future: app.statsOf(project.id),
          builder: (context, snapshot) {
            final stats = snapshot.data;

            final total = stats?['total'] ?? 0;
            final progress = stats?['progress'] ?? 0;

            return Card(
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    '$progress%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // [جديد] شارة نوع الوحدة
                    _buildUnitTypeBadge(context, project.type),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(
                    top: 4,
                  ),
                  child: Text(
                    '$total مهمة • $progress% منجزة',
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_left,
                ),
                onTap: () => _openProject(project),
              ),
            );
          },
        );
      },
    );
  }
}