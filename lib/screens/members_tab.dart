import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';

class MembersTab extends StatelessWidget {
  final String projectId;

  const MembersTab(this.projectId, {super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        app.membersOf(projectId),
        app.tasksOf(projectId),
      ]),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snap.hasError) {
          return Center(
            child: Text(
              'حدث خطأ أثناء تحميل الأعضاء',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
        }

        final members = snap.data != null
            ? snap.data![0] as List<Member>
            : <Member>[];

        final tasks = snap.data != null
            ? snap.data![1] as List<Task>
            : <Task>[];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'اسم العضو',
                        hintText: 'أدخل اسم عضو الفريق',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_add_outlined),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (value) async {
                        final name = value.trim();

                        if (name.isEmpty) return;

                        await app.addMember(
                          projectId,
                          name: name,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: members.isEmpty
                  ? const Center(
                      child: Text(
                        'لا يوجد أعضاء بعد.\nأدخل اسم العضو لإضافته.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: members.length,
                      itemBuilder: (_, i) {
                        final member = members[i];

                        final memberTasks = tasks
                            .where((task) => task.memberId == member.id)
                            .toList();

                        final done = memberTasks
                            .where((task) => task.status == 'done')
                            .length;

                        final percentage = memberTasks.isEmpty
                            ? 0
                            : done * 100 ~/ memberTasks.length;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                member.name.isNotEmpty
                                    ? member.name.characters.first
                                    : '?',
                              ),
                            ),
                            title: Text(
                              member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${memberTasks.length} مهمة • $percentage% منجزة',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                              ),
                              tooltip: 'حذف العضو',
                              onPressed: () async {
                                final confirmed =
                                    await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) {
                                    return AlertDialog(
                                      title: const Text('حذف العضو'),
                                      content: Text(
                                        'هل أنت متأكد من حذف "${member.name}"؟',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                            dialogContext,
                                            false,
                                          ),
                                          child: const Text('إلغاء'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                            dialogContext,
                                            true,
                                          ),
                                          child: const Text('حذف'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirmed == true) {
                                  await app.removeMember(member.id);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}