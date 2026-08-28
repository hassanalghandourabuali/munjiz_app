import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/models.dart';

class TaskFormDialog extends StatefulWidget {
  final String projectId;
  final Task task;

  const TaskFormDialog(
    this.projectId, {
    required this.task,
    super.key,
  });

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  late final TextEditingController _title;
  late final TextEditingController _desc;

  late String _status;
  late String _priority;
  String? _memberId;

  List<Member> _members = [];
  bool _loadingMembers = true;

  @override
  void initState() {
    super.initState();

    _title = TextEditingController(
      text: widget.task.title,
    );

    _desc = TextEditingController(
      text: widget.task.description,
    );

    _status = widget.task.status;
    _priority = widget.task.priority;
    _memberId = widget.task.memberId;

    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final app = context.read<AppProvider>();

      final members = await app.membersOf(widget.projectId);

      if (!mounted) return;

      setState(() {
        _members = members;
        _loadingMembers = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingMembers = false;
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();

    final isEdit = widget.task.id.isNotEmpty;

    return AlertDialog(
      title: Text(
        isEdit ? 'تعديل مهمة' : 'مهمة جديدة',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              autofocus: !isEdit,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                hintText: 'أدخل عنوان المهمة',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.task_alt,
                ),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _desc,
              textInputAction: TextInputAction.done,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'الوصف',
                hintText: 'وصف المهمة',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.description_outlined,
                ),
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _status,
              items: statusOrder
                  .map(
                    (status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        statusLabels[status]!,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _status = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'الحالة',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.flag_outlined,
                ),
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _priority,
              items: priorityLabels.keys
                  .map(
                    (priority) => DropdownMenuItem<String>(
                      value: priority,
                      child: Text(
                        priorityLabels[priority]!,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _priority = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'الأولوية',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.priority_high,
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (_loadingMembers)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              )
            else
              DropdownButtonFormField<String?>(
                value: _memberId,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('بدون مسؤول'),
                  ),
                  ..._members.map(
                    (member) => DropdownMenuItem<String?>(
                      value: member.id,
                      child: Text(member.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _memberId = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'المسؤول',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.person_outline,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('إلغاء'),
        ),

        ElevatedButton(
          onPressed: () async {
            final title = _title.text.trim();
            final description = _desc.text.trim();

            if (title.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'يرجى إدخال عنوان المهمة',
                  ),
                ),
              );
              return;
            }

            try {
              if (isEdit) {
                widget.task
                  ..title = title
                  ..description = description
                  ..status = _status
                  ..priority = _priority
                  ..memberId = _memberId;

                await app.editTask(widget.task);
              } else {
                await app.addTask(
                  widget.projectId,
                  title: title,
                  description: description,
                  status: _status,
                  priority: _priority,
                  memberId: _memberId,
                );
              }

              if (!mounted) return;

              Navigator.pop(context);
            } catch (e) {
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'حدث خطأ أثناء حفظ المهمة: $e',
                  ),
                ),
              );
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}