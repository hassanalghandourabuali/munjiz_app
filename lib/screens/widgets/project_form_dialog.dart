import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/models.dart';

class ProjectFormDialog extends StatefulWidget {
  final Project? project;

  const ProjectFormDialog({
    this.project,
    super.key,
  });

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _desc;

  // [جديد] نوع الوحدة المختار (مشروع / مادة دراسية)
  late String _type;

  @override
  void initState() {
    super.initState();

    _name = TextEditingController(
      text: widget.project?.name ?? '',
    );

    _desc = TextEditingController(
      text: widget.project?.description ?? '',
    );

    _type = widget.project?.type ?? 'project'; // [جديد]
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  // ============================================================
  // Unit Type Selector  [جديد]
  // ============================================================

  IconData _iconFor(String type) {
    return type == 'studyChapter'
        ? Icons.menu_book_outlined
        : Icons.work_outline;
  }

  Widget _buildTypeSelector() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SegmentedButton<String>(
        segments: unitTypeLabels.entries
            .map(
              (e) => ButtonSegment<String>(
                value: e.key,
                label: Text(e.value),
                icon: Icon(_iconFor(e.key), size: 16),
              ),
            )
            .toList(),
        selected: <String>{_type},
        onSelectionChanged: (selection) {
          setState(() {
            _type = selection.first;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.project != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'تعديل مشروع' : 'مشروع جديد',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [جديد] اختيار نوع الوحدة
            const Padding(
              padding: EdgeInsets.only(bottom: 8, right: 4),
              child: Text(
                'نوع الوحدة',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            _buildTypeSelector(),

            const SizedBox(height: 16),

            TextField(
              controller: _name,
              autofocus: !isEdit,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'اسم المشروع',
                hintText: 'أدخل اسم المشروع',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.folder_outlined,
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _desc,
              textInputAction: TextInputAction.done,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'الوصف',
                hintText: 'وصف مختصر للمشروع',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.description_outlined,
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
            final name = _name.text.trim();
            final description = _desc.text.trim();

            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'يرجى إدخال اسم المشروع',
                  ),
                ),
              );
              return;
            }

            final app = context.read<AppProvider>();

            try {
              if (isEdit) {
                await app.editProject(
                  Project(
                    id: widget.project!.id,
                    name: name,
                    description: description,
                    startDate: widget.project!.startDate,
                    endDate: widget.project!.endDate,
                    createdAt: widget.project!.createdAt,
                    type: _type, // [جديد]
                  ),
                );
              } else {
                await app.createProject(
                  name: name,
                  description: description,
                  type: _type, // [جديد]
                );
              }

              if (!mounted) return;

              Navigator.pop(context);
            } catch (e) {
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'حدث خطأ أثناء حفظ المشروع: $e',
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
