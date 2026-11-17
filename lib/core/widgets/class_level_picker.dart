import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class ClassLevelGroup {
  const ClassLevelGroup(this.label, this.levels);

  final String label;
  final List<String> levels;
}

const List<ClassLevelGroup> kClassLevelGroups = [
  ClassLevelGroup('Class 1-5', ['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5']),
  ClassLevelGroup('Class 6-8', ['Class 6', 'Class 7', 'Class 8']),
  ClassLevelGroup('Matric (9-10)', ['Class 9', 'Class 10']),
  ClassLevelGroup('FSc / Inter (11-12)', ['Class 11', 'Class 12']),
  ClassLevelGroup('O/A Levels', ['O Levels', 'A Levels']),
  ClassLevelGroup('University', ['University']),
];

const List<String> kClassLevelsList = [
  'Class 1',
  'Class 2',
  'Class 3',
  'Class 4',
  'Class 5',
  'Class 6',
  'Class 7',
  'Class 8',
  'Class 9',
  'Class 10',
  'Class 11',
  'Class 12',
  'O Levels',
  'A Levels',
  'University',
];

class ClassLevelPicker extends StatefulWidget {
  const ClassLevelPicker({
    super.key,
    required this.selectedLevels,
    required this.onChanged,
    this.singleSelection = false,
    this.maxSelections = 10,
    this.allowCustom = true,
  });

  final Set<String> selectedLevels;
  final ValueChanged<Set<String>> onChanged;
  final bool singleSelection;
  final int maxSelections;
  final bool allowCustom;

  @override
  State<ClassLevelPicker> createState() => _ClassLevelPickerState();
}

class _ClassLevelPickerState extends State<ClassLevelPicker> {
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _showLimitMessage() {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('Choose up to ${widget.maxSelections} classes.')),
    );
  }

  void _toggleGroup(ClassLevelGroup group) {
    final selected = Set<String>.of(widget.selectedLevels);
    final groupSelected = group.levels.every(selected.contains);
    if (groupSelected) {
      selected.removeAll(group.levels);
    } else {
      final additions = group.levels.where((level) => !selected.contains(level));
      if (selected.length + additions.length > widget.maxSelections) {
        _showLimitMessage();
        return;
      }
      selected.addAll(additions);
    }
    widget.onChanged(selected);
  }

  void _toggleLevel(String level, bool selected) {
    final next = Set<String>.of(widget.selectedLevels);
    if (widget.singleSelection) {
      widget.onChanged(selected ? {level} : <String>{});
      return;
    }
    if (selected) {
      if (next.length >= widget.maxSelections) {
        _showLimitMessage();
        return;
      }
      next.add(level);
    } else {
      next.remove(level);
    }
    widget.onChanged(next);
  }

  void _selectAll() {
    if (kClassLevelsList.length > widget.maxSelections) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            'Select groups individually; this profile can include up to ${widget.maxSelections} classes.',
          ),
        ),
      );
      return;
    }
    widget.onChanged(Set<String>.of(kClassLevelsList));
  }

  void _addCustomLevel() {
    final level = _customController.text.trim();
    if (level.isEmpty) return;
    if (widget.selectedLevels.any(
      (selected) => selected.toLowerCase() == level.toLowerCase(),
    )) {
      _customController.clear();
      return;
    }
    if (widget.singleSelection) {
      widget.onChanged({level});
    } else if (widget.selectedLevels.length >= widget.maxSelections) {
      _showLimitMessage();
      return;
    } else {
      widget.onChanged({...widget.selectedLevels, level});
    }
    _customController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.selectedLevels.length;
    final customLevels = widget.selectedLevels
        .where((level) => !kClassLevelsList.contains(level))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('$selectedCount selected'),
            ),
            if (!widget.singleSelection)
              TextButton(onPressed: _selectAll, child: const Text('Select all')),
            TextButton(
              onPressed: () => widget.onChanged(<String>{}),
              child: const Text('Clear'),
            ),
          ],
        ),
        if (!widget.singleSelection)
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: kClassLevelGroups.map((group) {
              final isSelected = group.levels.every(
                widget.selectedLevels.contains,
              );
              return FilterChip(
                label: Text(group.label),
                selected: isSelected,
                onSelected: (_) => _toggleGroup(group),
              );
            }).toList(),
          ),
        ...kClassLevelGroups.map((group) {
          final isExpanded = widget.selectedLevels.any(group.levels.contains);
          return ExpansionTile(
            key: PageStorageKey<String>('class-level-${group.label}'),
            initiallyExpanded: isExpanded,
            tilePadding: EdgeInsets.zero,
            title: Text(group.label),
            children: group.levels.map((level) {
              if (widget.singleSelection) {
                final selected = widget.selectedLevels.contains(level);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(level),
                  selected: selected,
                  onTap: () => _toggleLevel(level, !selected),
                );
              }
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(level),
                value: widget.selectedLevels.contains(level),
                onChanged: (selected) => _toggleLevel(level, selected ?? false),
              );
            }).toList(),
          );
        }),
        if (customLevels.isNotEmpty)
          Wrap(
            spacing: AppSpacing.xs,
            children: customLevels
                .map(
                  (level) => InputChip(
                    label: Text(level),
                    onDeleted: () {
                      final next = Set<String>.of(widget.selectedLevels)
                        ..remove(level);
                      widget.onChanged(next);
                    },
                  ),
                )
                .toList(),
          ),
        if (widget.allowCustom) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Custom class',
                    hintText: 'Add another class level',
                  ),
                  onSubmitted: (_) => _addCustomLevel(),
                ),
              ),
              IconButton(
                tooltip: 'Add class',
                onPressed: _addCustomLevel,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
