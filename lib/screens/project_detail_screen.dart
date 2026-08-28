import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'kanban_tab.dart';
import 'members_tab.dart';
import 'progress_tab.dart';
import 'report_tab.dart';
import 'widgets/project_form_dialog.dart'; // [جديد]

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailScreen(
    this.projectId, {
    super.key,
  });

  // ============================================================
  // [جديد] تعديل المشروع
  // ============================================================

  Future<void> _editProject(BuildContext context, project) async {
    await showDialog(
      context: context,
      builder: (_) => ProjectFormDialog(project: project),
    );
  }

  // ============================================================
  // [جديد] حذف المشروع
  // ============================================================

  Future<void> _deleteProject(BuildContext context, project) async {
    // [محدّث] نمسك كل الكائنات المرتبطة بالـcontext قبل أي await،
    // حتى لا نحتاج لاستخدام BuildContext نفسه بعد نقطة انتظار
    // غير متزامنة — هذا يزيل تحذير use_build_context_synchronously
    // نهائيًا بدل الاعتماد على فحص context.mounted.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final appProvider = context.read<AppProvider>();
    final projectName = project.name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف المشروع'),
          content: Text(
            'هل أنت متأكدة من رغبتك في حذف مشروع "$projectName"؟\n'
            'سيتم حذف كل الأعضاء والمهام المرتبطة به بشكل نهائي، '
            'ولا يمكن التراجع عن هذه العملية.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('حذف نهائيًا'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await appProvider.deleteProject(projectId);

    // نرجع للشاشة الرئيسية بعد الحذف، لأنه المشروع لم يعد موجودًا.
    navigator.pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text('تم حذف مشروع "$projectName"'),
      ),
    );
  }

  // ============================================================
  // [جديد] قائمة خيارات المشروع (تعديل / حذف)
  // ============================================================

  Widget _buildOptionsMenu(BuildContext context, project) {
    return PopupMenuButton<String>(
      tooltip: 'خيارات المشروع',
      onSelected: (value) {
        if (value == 'edit') {
          _editProject(context, project);
        } else if (value == 'delete') {
          _deleteProject(context, project);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 20),
              SizedBox(width: 10),
              Text('تعديل المشروع'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 10),
              Text('حذف المشروع', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    final projectIndex = app.projects.indexWhere(
      (project) => project.id == projectId,
    );

    // إذا لم يعد المشروع موجودًا، نرجع للشاشة السابقة.
    if (projectIndex == -1) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('المشروع'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              const Text(
                'المشروع غير موجود',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('رجوع'),
              ),
            ],
          ),
        ),
      );
    }

    final project = app.projects[projectIndex];

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            project.name,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          actions: [
            _buildOptionsMenu(context, project), // [جديد]
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(
                icon: Icon(Icons.view_kanban_outlined),
                text: 'المهام',
              ),
              Tab(
                icon: Icon(Icons.people_outline),
                text: 'الأعضاء',
              ),
              Tab(
                icon: Icon(Icons.pie_chart_outline),
                text: 'التقدم',
              ),
              Tab(
                icon: Icon(Icons.assessment_outlined),
                text: 'التقرير',
              ),
            ],
          ),
        ),
        body: TabBarView( 
          children: [
            KanbanTab(projectId),
            MembersTab(projectId),
            ProgressTab(projectId),
            ReportTab(projectId),
          ],
        ),
      ),
    );
  }
}
