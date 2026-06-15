import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/exercise.dart';
import '../../shared/providers/providers.dart';

/// Create a user-defined custom exercise that joins the searchable library.
class CustomExerciseScreen extends ConsumerStatefulWidget {
  const CustomExerciseScreen({super.key});

  @override
  ConsumerState<CustomExerciseScreen> createState() =>
      _CustomExerciseScreenState();
}

class _CustomExerciseScreenState extends ConsumerState<CustomExerciseScreen> {
  final _name = TextEditingController();
  String _group = AppConstants.muscleGroups.first;
  String _equipment = AppConstants.equipmentTypes.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom exercise'),
        actions: [
          TextButton(
            onPressed: _name.text.trim().isEmpty ? null : _save,
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Exercise name'),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _group,
            decoration: const InputDecoration(labelText: 'Muscle group'),
            items: AppConstants.muscleGroups
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _group = v!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _equipment,
            decoration: const InputDecoration(labelText: 'Equipment'),
            items: AppConstants.equipmentTypes
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _equipment = v!),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final id =
        'custom-${_name.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';
    final exercise = Exercise(
      id: id,
      name: _name.text.trim(),
      muscleGroup: _group,
      equipment: _equipment,
      isCustom: true,
    );
    await ref.read(exerciseRepositoryProvider).save(exercise);
    ref.read(dataRevisionProvider.notifier).state++;
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }
}
