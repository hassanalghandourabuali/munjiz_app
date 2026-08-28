import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'celebration_screen.dart'; // [جديد]

class ProgressTab extends StatefulWidget {
  final String projectId;

  const ProgressTab(this.projectId, {super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

// [جديد] تحويل الودجت من StatelessWidget إلى StatefulWidget — لازم عشان
// نقدر نتحكم بمتى تُفتح شاشة الاحتفال (مرة واحدة بس، مش مع كل rebuild)
class _ProgressTabState extends State<ProgressTab> {
  bool _checkedCelebration = false; // [جديد]

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return FutureBuilder<Map<String, dynamic>>(
      future: app.statsOf(widget.projectId),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snap.hasError) {
          return Center(
            child: Text(
              'حدث خطأ أثناء تحميل بيانات التقدم',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
        }

        final s = snap.data ?? {};

        final progress = (s['progress'] ?? 0) as int;
        final todo = (s['todo'] ?? 0) as int;
        final inProgress = (s['inProgress'] ?? 0) as int;
        final done = (s['done'] ?? 0) as int;
        final overdue = (s['overdue'] ?? 0) as int;

        // [جديد] فحص لحظة الإنجاز — مرة واحدة بس بعد أول رسم للشاشة
        if (progress == 100 && !_checkedCelebration) {
          _checkedCelebration = true;
          _maybeShowCelebration(app);
        }

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: progress / 100,
                          strokeWidth: 14,
                          backgroundColor: Colors.black12,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$progress%',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'نسبة الإنجاز',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _chip(
                      'لم تبدأ',
                      todo,
                      Colors.amber,
                    ),
                    _chip(
                      'قيد التنفيذ',
                      inProgress,
                      Colors.lightBlue,
                    ),
                    _chip(
                      'منجزة',
                      done,
                      Colors.green,
                    ),
                    _chip(
                      'متأخرة',
                      overdue,
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // [جديد] يتحقق هل تم الاحتفال بهذه الوحدة من قبل، ولو لأ يفتح شاشة الاحتفال
  Future<void> _maybeShowCelebration(AppProvider app) async {
    final already = await app.hasCelebrated(widget.projectId);

    if (already || !mounted) {
      return;
    }

    final project = app.projects.firstWhere(
      (p) => p.id == widget.projectId,
      orElse: () => app.projects.first,
    );

    // ننتظر حتى ينتهي الرسم الحالي للشاشة قبل فتح شاشة جديدة فوقها
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CelebrationScreen(project: project),
        ),
      );
    });
  }

  Widget _chip(
    String label,
    int count,
    Color color,
  ) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 10,
      ),
      label: Text(
        '$label: $count',
      ),
    );
  }
}
