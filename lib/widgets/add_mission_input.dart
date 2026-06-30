import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget scheduleRow({
              required IconData icon,
              required String label,
              required String value,
              required VoidCallback onSet,
              VoidCallback? onClear,
            }) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: value == 'Not set'
                              ? AppColors.onSurfaceVariant.withValues(alpha: 0.5)
                              : AppColors.onSurface,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 28,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onSet,
                        child: Text(
                          value == 'Not set' ? 'Set' : 'Change',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    if (onClear != null)
                      SizedBox(
                        height: 28,
                        width: 28,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, size: 14),
                          style: IconButton.styleFrom(
                            foregroundColor: AppColors.onSurfaceVariant,
                          ),
                          onPressed: onClear,
                        ),
                      ),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.onSurfaceVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'New Mission',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Mission title',
                      hintStyle: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Category',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
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
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surfaceContainerLow,
                              labelStyle: TextStyle(
                                color: isSel
                                    ? AppColors.onSurface
                                    : AppColors.onSurfaceVariant,
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
                                      ? AppColors.primary
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
                              color: AppColors.onSurfaceVariant,
                            ),
                            backgroundColor: AppColors.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: AppColors.outline),
                            ),
                            onPressed: () {
                              final textController = TextEditingController();
                              showDialog(
                                context: sheetContext,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.surfaceContainer,
                                  title: const Text(
                                    'New Category',
                                    style: TextStyle(
                                      color: AppColors.onSurface,
                                      fontSize: 16,
                                    ),
                                  ),
                                  content: TextField(
                                    controller: textController,
                                    style: const TextStyle(
                                      color: AppColors.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Category name',
                                      hintStyle: const TextStyle(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.surfaceContainerLow,
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
                                        style: TextStyle(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
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
                                        style: TextStyle(
                                          color: AppColors.onSurface,
                                        ),
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
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['High', 'Medium', 'Low'].map((p) {
                      final isSel = selectedPriority == p;
                      final color = p == 'High'
                          ? AppColors.priorityHigh
                          : p == 'Medium'
                          ? AppColors.priorityMedium
                          : AppColors.priorityLow;
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
                                    : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel
                                      ? color
                                      : AppColors.surfaceContainerHigh,
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
                                            : AppColors.onSurfaceVariant,
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
                                                color: AppColors.onSurface,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    p,
                                    style: TextStyle(
                                      color: isSel
                                          ? color
                                          : AppColors.onSurfaceVariant,
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
                  const Text(
                    'Schedule (optional)',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        // ── Date row ──
                        scheduleRow(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: selectedDate != null
                              ? '${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}'
                              : 'Not set',
                          onSet: () async {
                            final date = await showDatePicker(
                              context: sheetContext,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date == null) return;
                            if (!sheetContext.mounted) return;
                            setSheetState(() {
                              selectedDate = date;
                              selectedStart = null;
                              selectedEnd = null;
                            });
                          },
                          onClear: selectedDate != null
                              ? () => setSheetState(() {
                                    selectedDate = null;
                                    selectedStart = null;
                                    selectedEnd = null;
                                  })
                              : null,
                        ),
                        // ── Start time row (requires date) ──
                        if (selectedDate != null) ...[
                          const Divider(
                            height: 1,
                            color: AppColors.surfaceContainerHigh,
                          ),
                          scheduleRow(
                            icon: Icons.schedule,
                            label: 'Start time',
                            value: selectedStart != null
                                ? selectedStart!.format(sheetContext)
                                : 'Not set',
                            onSet: () async {
                              final picked = await showTimePicker(
                                context: sheetContext,
                                initialTime:
                                    selectedStart ??
                                    const TimeOfDay(hour: 9, minute: 0),
                              );
                              if (picked == null) return;
                              if (!sheetContext.mounted) return;
                              setSheetState(() => selectedStart = picked);
                            },
                            onClear: selectedStart != null
                                ? () => setSheetState(
                                      () => selectedStart = null,
                                    )
                                : null,
                          ),
                        ],
                        // ── End time row (requires start) ──
                        if (selectedStart != null) ...[
                          const Divider(
                            height: 1,
                            color: AppColors.surfaceContainerHigh,
                          ),
                          scheduleRow(
                            icon: Icons.schedule,
                            label: 'End time',
                            value: selectedEnd != null
                                ? selectedEnd!.format(sheetContext)
                                : 'Not set',
                            onSet: () async {
                              final picked = await showTimePicker(
                                context: sheetContext,
                                initialTime:
                                    selectedEnd ??
                                    TimeOfDay(
                                      hour: selectedStart!.hour + 1,
                                      minute: selectedStart!.minute,
                                    ),
                              );
                              if (picked == null) return;
                              if (!sheetContext.mounted) return;
                              setSheetState(() => selectedEnd = picked);
                            },
                            onClear: selectedEnd != null
                                ? () => setSheetState(
                                      () => selectedEnd = null,
                                    )
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
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
                          color: AppColors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: (_) => _showAddSheet(context),
            style: const TextStyle(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: 'Enter new mission',
              hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
              filled: true,
              fillColor: AppColors.surfaceContainer,
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
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Icon(Icons.add, color: AppColors.onSurface),
          ),
        ),
      ],
    );
  }
}
