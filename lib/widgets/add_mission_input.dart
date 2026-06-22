import 'package:flutter/material.dart';

class AddMissionInput extends StatelessWidget {
  final TextEditingController controller;
  final void Function(
    String title,
    String category,
    String priority,
    DateTime? dueDate,
    TimeOfDay? start,
    TimeOfDay? end,
  )
  onAddMission;

  const AddMissionInput({
    super.key,
    required this.controller,
    required this.onAddMission,
  });

  void _showAddSheet(BuildContext context) {
    final title = controller.text.trim();
    if (title.isEmpty) return;

    String selectedCategory = 'General';
    String selectedPriority = 'Medium';
    DateTime? selectedDate;
    TimeOfDay? selectedStart;
    TimeOfDay? selectedEnd;
    final customCategories = <String>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'New Mission',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Mission title',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Category',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ...[
                          'General',
                          'Work',
                          'Study',
                          'Fitness',
                          ...customCategories,
                        ].map((cat) {
                          final isSel = selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSel,
                              selectedColor: Colors.green,
                              backgroundColor: Colors.grey[900],
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : Colors.grey[400],
                                fontSize: 12,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isSel
                                      ? Colors.green
                                      : Colors.transparent,
                                ),
                              ),
                              onSelected: (_) =>
                                  setSheetState(() => selectedCategory = cat),
                            ),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: const Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.grey,
                            ),
                            backgroundColor: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[700]!),
                            ),
                            onPressed: () {
                              final textController = TextEditingController();
                              showDialog(
                                context: sheetContext,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  title: const Text(
                                    'New Category',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  content: TextField(
                                    controller: textController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Category name',
                                      hintStyle: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[900],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        final name = textController.text.trim();
                                        if (name.isNotEmpty) {
                                          setSheetState(() {
                                            customCategories.add(name);
                                            selectedCategory = name;
                                          });
                                        }
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text(
                                        'Add',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Priority',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['High', 'Medium', 'Low'].map((p) {
                      final isSel = selectedPriority == p;
                      final color = p == 'High'
                          ? Colors.redAccent
                          : p == 'Medium'
                          ? Colors.amber
                          : Colors.grey;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: p == 'Low' ? 0 : 8),
                          child: GestureDetector(
                            onTap: () =>
                                setSheetState(() => selectedPriority = p),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? color.withValues(alpha: 0.12)
                                    : Colors.grey[900],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel ? color : Colors.grey[800]!,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSel ? color : Colors.transparent,
                                      border: Border.all(
                                        color: isSel
                                            ? color
                                            : Colors.grey[500]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSel
                                        ? Center(
                                            child: Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    p,
                                    style: TextStyle(
                                      color: isSel ? color : Colors.grey[400],
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: sheetContext,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date == null) return;
                        setSheetState(() => selectedDate = date);

                        final start = await showTimePicker(
                          context: sheetContext,
                          initialTime:
                              selectedStart ??
                              const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (start == null) return;
                        setSheetState(() => selectedStart = start);

                        final end = await showTimePicker(
                          context: sheetContext,
                          initialTime:
                              selectedEnd ??
                              TimeOfDay(
                                hour: start.hour + 1,
                                minute: start.minute,
                              ),
                        );
                        if (end != null) {
                          setSheetState(() => selectedEnd = end);
                        }
                      },
                      child: Text(
                        _formatSheetDate(
                          selectedDate,
                          selectedStart,
                          selectedEnd,
                          sheetContext,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final t = controller.text.trim();
                        if (t.isEmpty) return;
                        onAddMission(
                          t,
                          selectedCategory,
                          selectedPriority,
                          selectedDate,
                          selectedStart,
                          selectedEnd,
                        );
                        controller.clear();
                        Navigator.pop(sheetContext);
                      },
                      child: const Text(
                        'Add Mission',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatSheetDate(
    DateTime? date,
    TimeOfDay? start,
    TimeOfDay? end,
    BuildContext context,
  ) {
    if (date == null && start == null && end == null) {
      return '📅 Set Date & Time (optional)';
    }
    final dateStr = date != null
        ? '${date.day}.${date.month}.${date.year}'
        : '';
    final startStr = start != null ? start.format(context) : '';
    final endStr = end != null ? end.format(context) : '';
    if (dateStr.isNotEmpty && startStr.isNotEmpty && endStr.isNotEmpty) {
      return '📅 $dateStr  $startStr - $endStr';
    }
    if (dateStr.isNotEmpty && startStr.isNotEmpty) {
      return '📅 $dateStr  $startStr';
    }
    if (dateStr.isNotEmpty) return '📅 $dateStr';
    return '📅 $startStr - $endStr';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: (_) => _showAddSheet(context),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter new mission',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: () => _showAddSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
