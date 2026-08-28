import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';

// [جديد] شاشة كاملة جديدة — تُعرض مرة واحدة عند وصول أي وحدة لنسبة إنجاز 100%
class CelebrationScreen extends StatefulWidget {
  final Project project;

  const CelebrationScreen({super.key, required this.project});

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen> {
  final _lessonController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _lessonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('لحظة الإنجاز'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: app.memberContributions(widget.project.id),
        builder: (context, snap) {
          final contributions = snap.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.celebration,
                  size: 72,
                  color: Colors.amber,
                ),
                const SizedBox(height: 12),
                Text(
                  'مبروك! أنجزتم "${widget.project.name}" 🎉',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (contributions.isNotEmpty) ...[
                  const Text(
                    'مساهمة الأعضاء',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...contributions.map((c) {
                    final member = c['member'] as Member;
                    final percentage = c['percentage'] as int;
                    final doneCount = c['doneCount'] as int;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${member.name} — $doneCount مهمة ($percentage%)'),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 8,
                              backgroundColor: Colors.black12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
                const Text(
                  'شو أهم شي تعلمناه من هالمشروع؟',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'اختياري — بينحفظ بأرشيفك الشخصي وتقدر ترجعله لاحقًا',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _lessonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'اكتب الدرس المستفاد هون...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : () => _finish(save: true),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حفظ ومتابعة'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _saving ? null : () => _finish(save: false),
                  child: const Text('تخطي'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _finish({required bool save}) async {
    final app = context.read<AppProvider>();

    setState(() => _saving = true);

    if (save && _lessonController.text.trim().isNotEmpty) {
      await app.addLessonLearned(
        widget.project.id,
        note: _lessonController.text.trim(),
      );
    }

    await app.markCelebrated(widget.project.id);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
