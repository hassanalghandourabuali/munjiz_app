import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/app_provider.dart';
import '../services/pdf_report_service.dart';

class ReportTab extends StatelessWidget {
  final String projectId;

  const ReportTab(this.projectId, {super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return FutureBuilder<Map<String, dynamic>>(
      future: app.statsOf(projectId),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snap.hasError) {
          return Center(
            child: Text(
              'حدث خطأ أثناء تحميل التقرير',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
        }

        final s = snap.data ?? {};

        final total = s['total'] ?? 0;
        final done = s['done'] ?? 0;
        final inProgress = s['inProgress'] ?? 0;
        final todo = s['todo'] ?? 0;
        final overdue = s['overdue'] ?? 0;
        final progress = s['progress'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'تقرير المشروع',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _reportItem(
                context,
                icon: Icons.assignment_outlined,
                title: 'إجمالي المهام',
                value: '$total',
              ),
              _reportItem(
                context,
                icon: Icons.check_circle_outline,
                title: 'المهام المنجزة',
                value: '$done',
              ),
              _reportItem(
                context,
                icon: Icons.pending_actions,
                title: 'قيد التنفيذ',
                value: '$inProgress',
              ),
              _reportItem(
                context,
                icon: Icons.radio_button_unchecked,
                title: 'لم تبدأ',
                value: '$todo',
              ),
              _reportItem(
                context,
                icon: Icons.warning_amber_outlined,
                title: 'المهام المتأخرة',
                value: '$overdue',
              ),
              _reportItem(
                context,
                icon: Icons.trending_up,
                title: 'نسبة الإنجاز',
                value: '$progress%',
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('تصدير المشروع'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
                onPressed: () async {
                  try {
                    final data = await app.exportProject(projectId);
                    final text = app.encodeExport(data);

                    final dir = await getTemporaryDirectory();

                    final file = File(
                      '${dir.path}/munjiz_project.json',
                    );

                    await file.writeAsString(
                      text,
                      flush: true,
                    );

                    await Share.shareXFiles(
                      [XFile(file.path)],
                      text: 'مشروع مُنجز',
                    );
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'فشل تصدير المشروع: $e',
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('تصدير تقرير PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
                onPressed: () async {
                  try {
                    final project = app.projects.firstWhere(
                      (p) => p.id == projectId,
                    );

                    await PdfReportService.generateAndShare(
                      project: project,
                      stats: s,
                    );
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'فشل إنشاء التقرير: $e',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _reportItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
