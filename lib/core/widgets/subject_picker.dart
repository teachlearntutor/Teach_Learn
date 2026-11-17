import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class SubjectGroup {
  const SubjectGroup(this.label, this.subjects);

  final String label;
  final List<SubjectOption> subjects;
}

class SubjectOption {
  const SubjectOption(this.label, this.value);

  final String label;
  final String value;
}

const List<SubjectGroup> kSubjectGroups = [
  SubjectGroup('Core', [
    SubjectOption('English', 'English'),
    SubjectOption('Urdu', 'Urdu'),
    SubjectOption('Islamiat', 'Islamiat'),
    SubjectOption('Pak Studies', 'Pak Studies'),
    SubjectOption('Math', 'Mathematics'),
  ]),
  SubjectGroup('Science', [
    SubjectOption('Physics', 'Physics'),
    SubjectOption('Chemistry', 'Chemistry'),
    SubjectOption('Biology', 'Biology'),
  ]),
  SubjectGroup('Computer', [
    SubjectOption('Computer Science', 'Computer Science'),
    SubjectOption('IT', 'IT'),
  ]),
  SubjectGroup('Pre-Medical', [
    SubjectOption('Bio', 'Biology'),
    SubjectOption('Chem', 'Chemistry'),
    SubjectOption('Phys', 'Physics'),
    SubjectOption('Eng', 'English'),
    SubjectOption('Urdu', 'Urdu'),
  ]),
  SubjectGroup('Pre-Engineering', [
    SubjectOption('Math', 'Mathematics'),
    SubjectOption('Phys', 'Physics'),
    SubjectOption('Chem', 'Chemistry'),
  ]),
  SubjectGroup('ICS', [
    SubjectOption('Math', 'Mathematics'),
    SubjectOption('Phys', 'Physics'),
    SubjectOption('Computer', 'Computer Science'),
  ]),
  SubjectGroup('Commerce/ICom', [
    SubjectOption('Accounting', 'Accounting'),
    SubjectOption('Business', 'Business'),
    SubjectOption('Economics', 'Economics'),
    SubjectOption('Statistics', 'Statistics'),
  ]),
  SubjectGroup('Languages', [
    SubjectOption('Arabic', 'Arabic'),
    SubjectOption('Persian', 'Persian'),
    SubjectOption('French', 'French'),
    SubjectOption('Pashto', 'Pashto'),
    SubjectOption('Punjabi', 'Punjabi'),
    SubjectOption('Sindhi', 'Sindhi'),
  ]),
];

const List<String> kAllSubjects = [
  'English',
  'Urdu',
  'Islamiat',
  'Pak Studies',
  'Mathematics',
  'Physics',
  'Chemistry',
  'Biology',
  'Computer Science',
  'IT',
  'Accounting',
  'Business',
  'Economics',
  'Statistics',
  'Arabic',
  'Persian',
  'French',
  'Pashto',
  'Punjabi',
  'Sindhi',
];

const Map<String, List<String>> _subjectPresets = {
  'Pre-Medical': ['Biology', 'Chemistry', 'Physics', 'English', 'Urdu'],
  'Pre-Engineering': ['Mathematics', 'Physics', 'Chemistry'],
  'ICS': ['Mathematics', 'Physics', 'Computer Science'],
  'Commerce': ['Accounting', 'Business', 'Economics', 'Statistics'],
  'Matric Science': [
    'English',
    'Urdu',
    'Islamiat',
    'Pak Studies',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
  ],
  'Matric Arts': [
    'English',
    'Urdu',
    'Islamiat',
    'Pak Studies',
    'Mathematics',
    'Arabic',
    'Persian',
  ],
};

class SubjectPicker extends StatefulWidget {
  const SubjectPicker({
    super.key,
    required this.selectedSubjects,
    required this.onChanged,
    this.maxSelections = 10,
  });

  final Set<String> selectedSubjects;
  final ValueChanged<Set<String>> onChanged;
  final int maxSelections;

  @override
  State<SubjectPicker> createState() => _SubjectPickerState();
}

class _SubjectPickerState extends State<SubjectPicker> {
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _showLimitMessage() {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text('You can select up to ${widget.maxSelections} subjects.'),
      ),
    );
  }

  void _selectGroup(SubjectGroup group) {
    final next = Set<String>.of(widget.selectedSubjects);
    final values = group.subjects.map((subject) => subject.value).toSet();
    final allSelected = values.every(next.contains);
    if (allSelected) {
      next.removeAll(values);
    } else {
      final additions = values.where((subject) => !next.contains(subject));
      next.addAll(additions);
      _keepWithinLimit(next);
    }
    widget.onChanged(next);
  }

  void _applyPreset(String name) {
    final next = <String>{
      ...widget.selectedSubjects,
      ..._subjectPresets[name]!,
    };
    final exceededLimit = next.length > widget.maxSelections;
    _keepWithinLimit(next);
    widget.onChanged(next);
    if (exceededLimit) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            'Preset exceeds the ${widget.maxSelections}-subject limit; selected the first ${widget.maxSelections}.',
          ),
        ),
      );
    }
  }

  void _keepWithinLimit(Set<String> subjects) {
    if (subjects.length <= widget.maxSelections) return;
    final limited = subjects.take(widget.maxSelections).toSet();
    subjects
      ..clear()
      ..addAll(limited);
  }

  void _toggleSubject(String subject, bool selected) {
    final next = Set<String>.of(widget.selectedSubjects);
    if (selected) {
      if (next.length >= widget.maxSelections) {
        _showLimitMessage();
        return;
      }
      next.add(subject);
    } else {
      next.remove(subject);
    }
    widget.onChanged(next);
  }

  void _addCustomSubject() {
    final subject = _customController.text.trim();
    if (subject.isEmpty) return;
    if (widget.selectedSubjects.any(
      (selected) => selected.toLowerCase() == subject.toLowerCase(),
    )) {
      _customController.clear();
      return;
    }
    if (widget.selectedSubjects.length >= widget.maxSelections) {
      _showLimitMessage();
      return;
    }
    widget.onChanged({...widget.selectedSubjects, subject});
    _customController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final knownSubjects = kAllSubjects.toSet();
    final customSubjects = widget.selectedSubjects
        .where((subject) => !knownSubjects.contains(subject))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${widget.selectedSubjects.length}/${widget.maxSelections}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: () => widget.onChanged(<String>{}),
              child: const Text('Clear'),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: _subjectPresets.entries.map((preset) {
            final selected = preset.value.every(
              widget.selectedSubjects.contains,
            );
            return FilterChip(
              label: Text(preset.key),
              selected: selected,
              onSelected: (_) => _applyPreset(preset.key),
            );
          }).toList(),
        ),
        ...kSubjectGroups.map((group) {
          final values = group.subjects.map((subject) => subject.value);
          final isSelected = values.every(widget.selectedSubjects.contains);
          return ExpansionTile(
            key: PageStorageKey<String>('subject-group-${group.label}'),
            initiallyExpanded: group.subjects.any(
              (subject) => widget.selectedSubjects.contains(subject.value),
            ),
            tilePadding: EdgeInsets.zero,
            title: Row(
              children: [
                Expanded(child: Text(group.label)),
                TextButton(
                  onPressed: () => _selectGroup(group),
                  child: Text(isSelected ? 'Clear' : 'Select all'),
                ),
              ],
            ),
            children: group.subjects.map((option) {
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option.label),
                value: widget.selectedSubjects.contains(option.value),
                onChanged: (selected) =>
                    _toggleSubject(option.value, selected ?? false),
              );
            }).toList(),
          );
        }),
        if (customSubjects.isNotEmpty)
          Wrap(
            spacing: AppSpacing.xs,
            children: customSubjects
                .map(
                  (subject) => InputChip(
                    label: Text(subject),
                    onDeleted: () {
                      final next = Set<String>.of(widget.selectedSubjects)
                        ..remove(subject);
                      widget.onChanged(next);
                    },
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Custom subject',
                  hintText: 'Add another subject',
                ),
                onSubmitted: (_) => _addCustomSubject(),
              ),
            ),
            IconButton(
              tooltip: 'Add subject',
              onPressed: _addCustomSubject,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
