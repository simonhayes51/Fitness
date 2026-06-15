import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/food.dart';
import '../../data/models/food_log.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/common.dart';
import 'barcode_scanner_screen.dart';

/// Search the food database, scan a barcode, or create a custom food, then pick
/// a portion. Returns a [FoodLogEntry] to the caller.
class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({required this.mealType, required this.day, super.key});
  final String mealType;
  final DateTime day;

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  String _search = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(nutritionRepositoryProvider);
    final results = repo.searchFoods(_search);

    return Scaffold(
      appBar: AppBar(title: Text('Add to ${widget.mealType}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search foods…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    minimumSize: const Size(54, 54),
                  ),
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcode,
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _createCustom,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create custom food'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    icon: Icons.no_food,
                    title: 'No foods found',
                    message: 'Scan a barcode or create a custom food.')
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final f = results[i];
                      return ListTile(
                        title: Text(f.label),
                        subtitle: Text(
                            '${f.calories.round()} kcal · P${f.protein.round()} '
                            'C${f.carbs.round()} F${f.fat.round()} '
                            'per ${f.servingSize.round()}${f.servingUnit}'),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => _pickPortion(f),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final String? code;
    if (kIsWeb) {
      code = await _webBarcodeDialog();
    } else {
      code = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
      );
    }
    if (code == null || !mounted) return;

    // 1. Try local DB.
    final repo = ref.read(nutritionRepositoryProvider);
    final local = repo.foodByBarcode(code);
    if (local != null) {
      _pickPortion(local);
      return;
    }

    // 2. Fall back to the online food API.
    setState(() => _loading = true);
    final remote = await ref.read(foodApiProvider).lookupBarcode(code);
    if (!mounted) return;
    setState(() => _loading = false);

    if (remote != null) {
      await repo.saveFood(remote); // Cache for offline next time.
      _pickPortion(remote);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No match for $code. Add it as a custom food.')),
      );
      _createCustom(barcode: code);
    }
  }

  Future<String?> _webBarcodeDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter barcode'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 5000112548167'),
          onSubmitted: (v) => Navigator.pop(_, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(_, ctrl.text.trim()),
              child: const Text('Look up')),
        ],
      ),
    );
    ctrl.dispose();
    return result?.isEmpty == true ? null : result;
  }

  Future<void> _pickPortion(Food food) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PortionSheet(food: food),
    );
    if (amount == null || !mounted) return;
    Navigator.pop(
      context,
      FoodLogEntry(
        food: food,
        amount: amount,
        mealType: widget.mealType,
        loggedAt: DateTime(widget.day.year, widget.day.month, widget.day.day,
            DateTime.now().hour, DateTime.now().minute),
      ),
    );
  }

  Future<void> _createCustom({String barcode = ''}) async {
    final food = await showModalBottomSheet<Food>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CustomFoodSheet(barcode: barcode),
    );
    if (food == null || !mounted) return;
    await ref.read(nutritionRepositoryProvider).saveFood(food);
    _pickPortion(food);
  }
}

/// Portion selector with live macro preview.
class _PortionSheet extends StatefulWidget {
  const _PortionSheet({required this.food});
  final Food food;

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  late double _amount = widget.food.servingSize;
  late final TextEditingController _amountCtrl =
      TextEditingController(text: _amount.toStringAsFixed(0));

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final macros = widget.food.forAmount(_amount);
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
          Text(widget.food.label,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount (${widget.food.servingUnit})',
            ),
            onChanged: (v) =>
                setState(() => _amount = double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _macro('${macros.calories.round()}', 'kcal', AppColors.calories),
              _macro('${macros.protein.round()}g', 'protein', AppColors.protein),
              _macro('${macros.carbs.round()}g', 'carbs', AppColors.carbs),
              _macro('${macros.fat.round()}g', 'fat', AppColors.fat),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _amount > 0 ? () => Navigator.pop(context, _amount) : null,
            child: const Text('Add to diary'),
          ),
        ],
      ),
    );
  }

  Widget _macro(String value, String label, Color color) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w900, color: color, fontSize: 18)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}

/// Manual custom-food entry sheet (per 100g/serving).
class _CustomFoodSheet extends StatefulWidget {
  const _CustomFoodSheet({this.barcode = ''});
  final String barcode;

  @override
  State<_CustomFoodSheet> createState() => _CustomFoodSheetState();
}

class _CustomFoodSheetState extends State<_CustomFoodSheet> {
  final _name = TextEditingController();
  final _serving = TextEditingController(text: '100');
  final _cals = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
            Text('Custom food', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serving,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Serving size (g/ml)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _macroField(_cals, 'Calories')),
                const SizedBox(width: 10),
                Expanded(child: _macroField(_protein, 'Protein')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _macroField(_carbs, 'Carbs')),
                const SizedBox(width: 10),
                Expanded(child: _macroField(_fat, 'Fat')),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: const Text('Save food'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroField(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      );

  void _save() {
    if (_name.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      Food(
        name: _name.text.trim(),
        barcode: widget.barcode,
        servingSize: double.tryParse(_serving.text) ?? 100,
        servingUnit: 'g',
        calories: double.tryParse(_cals.text) ?? 0,
        protein: double.tryParse(_protein.text) ?? 0,
        carbs: double.tryParse(_carbs.text) ?? 0,
        fat: double.tryParse(_fat.text) ?? 0,
        isCustom: true,
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _serving.dispose();
    _cals.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }
}
