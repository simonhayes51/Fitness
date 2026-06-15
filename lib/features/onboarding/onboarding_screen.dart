import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/profile_provider.dart';
import '../../shared/widgets/common.dart';

/// First-launch onboarding: collects body data, activity level and goal, then
/// computes nutrition targets and marks the profile onboarded.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  // Collected values.
  String _name = '';
  Sex _sex = Sex.male;
  int _age = 25;
  double _height = 175;
  double _weight = 75;
  ActivityLevel _activity = ActivityLevel.moderate;
  FitnessGoal _goal = FitnessGoal.maintain;
  UnitSystem _units = UnitSystem.metric;

  static const _pageCount = 5;

  void _next() {
    if (_page < _pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(profileProvider.notifier).update(
          ref.read(profileProvider).copyWith(
                name: _name.trim().isEmpty ? 'Athlete' : _name.trim(),
                sex: _sex,
                age: _age,
                heightCm: _height,
                weightKg: _weight,
                activityLevel: _activity,
                goal: _goal,
                unitSystem: _units,
                onboarded: true,
              ),
        );
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  for (int i = 0; i < _pageCount; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _page ? AppColors.primary : Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _welcomePage(),
                  _namePage(),
                  _bodyPage(),
                  _activityPage(),
                  _goalPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                onPressed: _next,
                child: Text(_page == _pageCount - 1 ? 'Start training' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrap(String title, String subtitle, Widget body) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Theme.of(context).hintColor)),
          const SizedBox(height: 28),
          body,
        ],
      ),
    );
  }

  Widget _welcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.local_fire_department,
                size: 56, color: Colors.white),
          ),
          const SizedBox(height: 28),
          const Text('Welcome to ForgeFit',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(
            'Track workouts, dial in nutrition, and watch your strength climb — '
            'all in one place. Let\'s set up your profile.',
            style: TextStyle(
                color: Theme.of(context).hintColor, fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _namePage() {
    return _wrap(
      'What should we call you?',
      'Your name personalises greetings and progress cards.',
      TextField(
        decoration: const InputDecoration(hintText: 'e.g. Alex'),
        textCapitalization: TextCapitalization.words,
        onChanged: (v) => _name = v,
      ),
    );
  }

  Widget _bodyPage() {
    return _wrap(
      'Your stats',
      'We use these for calorie and macro targets.',
      Column(
        children: [
          Row(
            children: [
              Expanded(child: _segUnits()),
            ],
          ),
          const SizedBox(height: 20),
          _segSex(),
          const SizedBox(height: 20),
          _slider('Age', _age.toDouble(), 14, 90, '${_age}y',
              (v) => setState(() => _age = v.round()),
              divisions: 76),
          _slider(
            'Height',
            _height,
            120,
            220,
            _units == UnitSystem.metric
                ? '${_height.round()} cm'
                : '${(_height / 2.54).round()} in',
            (v) => setState(() => _height = v.roundToDouble()),
            divisions: 100,
          ),
          _slider(
            'Weight',
            _weight,
            35,
            200,
            _units == UnitSystem.metric
                ? '${_weight.round()} kg'
                : '${(_weight * 2.20462).round()} lbs',
            (v) => setState(() => _weight = v.roundToDouble()),
            divisions: 165,
          ),
        ],
      ),
    );
  }

  Widget _activityPage() {
    return _wrap(
      'How active are you?',
      'Outside of your training sessions.',
      Column(
        children: [
          for (final level in ActivityLevel.values)
            _selectableCard(
              selected: _activity == level,
              title: level.label,
              subtitle: level.description,
              onTap: () => setState(() => _activity = level),
            ),
        ],
      ),
    );
  }

  Widget _goalPage() {
    return _wrap(
      'Your primary goal',
      'This sets your daily calorie and protein targets.',
      Column(
        children: [
          for (final goal in FitnessGoal.values)
            _selectableCard(
              selected: _goal == goal,
              title: goal.label,
              subtitle: switch (goal) {
                FitnessGoal.loseFat => '~20% calorie deficit, high protein',
                FitnessGoal.maintain => 'Eat at maintenance',
                FitnessGoal.gainMuscle => '~10% calorie surplus',
              },
              onTap: () => setState(() => _goal = goal),
            ),
        ],
      ),
    );
  }

  Widget _segUnits() {
    return SegmentedButton<UnitSystem>(
      segments: const [
        ButtonSegment(value: UnitSystem.metric, label: Text('Metric (kg/cm)')),
        ButtonSegment(value: UnitSystem.imperial, label: Text('Imperial')),
      ],
      selected: {_units},
      onSelectionChanged: (s) => setState(() => _units = s.first),
    );
  }

  Widget _segSex() {
    return SegmentedButton<Sex>(
      segments: const [
        ButtonSegment(value: Sex.male, label: Text('Male')),
        ButtonSegment(value: Sex.female, label: Text('Female')),
      ],
      selected: {_sex},
      onSelectionChanged: (s) => setState(() => _sex = s.first),
    );
  }

  Widget _slider(String label, double value, double min, double max,
      String display, ValueChanged<double> onChanged, {int? divisions}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(display,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.primary)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _selectableCard({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        color: selected ? AppColors.primary.withOpacity(0.14) : null,
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : Theme.of(context).hintColor,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Theme.of(context).hintColor, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
