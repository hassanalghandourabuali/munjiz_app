import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';
import 'widgets/task_form_dialog.dart';

class KanbanTab extends StatelessWidget {
  final String projectId;

  const KanbanTab(
    this.projectId, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return FutureBuilder<List<Task>>(
      future: app.tasksOf(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'حدث خطأ أثناء تحميل المهام:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final tasks = snapshot.data ?? [];

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: statusOrder.map((status) {
                  final columnTasks =
                      tasks.where((task) => task.status == status).toList();

                  return SizedBox(
                    width: 300,
                    height: constraints.maxHeight - 16,
                    child: _KanbanColumn(
                      projectId: projectId,
                      status: status,
                      tasks: columnTasks,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String projectId;
  final String status;
  final List<Task> tasks;

  const _KanbanColumn({
    required this.projectId,
    required this.status,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ------------------------------------------------------
          // Column Header
          // ------------------------------------------------------

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    statusLabels[status] ?? status,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black12,
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // Tasks
          // ------------------------------------------------------

          Expanded(
            child: tasks.isEmpty
                ? _buildEmptyColumn(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: tasks.length + 1,
                    itemBuilder: (context, index) {
                      if (index == tasks.length) {
                        return _buildAddButton(context, status);
                      }

                      return _TaskCard(
                        projectId: projectId,
                        task: tasks[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyColumn(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              Icon(
                Icons.task_alt,
                size: 40,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'لا توجد مهام',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        _buildAddButton(context, status),
      ],
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    String status,
  ) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('إضافة مهمة'),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => TaskFormDialog(
            projectId,
            task: Task(
              id: '',
              projectId: projectId,
              title: '',
              status: status,
              priority: 'medium',
              createdAt: '',
            ),
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String projectId;
  final Task task;

  const _TaskCard({
    required this.projectId,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------
            // Title + Menu
            // ----------------------------------------------------

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (value) async {
                    await _handleAction(
                      context,
                      app,
                      value,
                    );
                  },
                  itemBuilder: (_) {
                    return [
                      ...statusOrder.map(
                        (status) => PopupMenuItem<String>(
                          value: status,
                          child: Text(
                            'نقل إلى: ${statusLabels[status]}',
                          ),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('تعديل'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('حذف'),
                      ),
                    ];
                  },
                ),
              ],
            ),

            if (task.description.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 8),

            // ----------------------------------------------------
            // Priority
            // ----------------------------------------------------

            Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 16,
                  color: _priorityColor(task.priority),
                ),
                const SizedBox(width: 5),
                Text(
                  priorityLabels[task.priority] ?? task.priority,
                  style: TextStyle(
                    fontSize: 12,
                    color: _priorityColor(task.priority),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // ----------------------------------------------------
            // Due Date
            // ----------------------------------------------------

            if (task.dueDate != null && task.dueDate!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    task.dueDate!,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    AppProvider app,
    String value,
  ) async {
    if (value == 'edit') {
      await showDialog(
        context: context,
        builder: (_) => TaskFormDialog(
          projectId,
          task: task,
        ),
      );

      return;
    }

    if (value == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('حذف المهمة'),
            content: const Text(
              'هل أنت متأكد من رغبتك في حذف هذه المهمة؟',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('حذف'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        await app.removeTask(task.id);
      }

      return;
    }

    if (statusLabels.containsKey(value) && value != task.status) {
      task.status = value;
      await app.editTask(task);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
