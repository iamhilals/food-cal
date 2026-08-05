import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MacroChart extends StatelessWidget {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  const MacroChart({
    super.key,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  @override
  Widget build(BuildContext context) {
    // Total macro weight in grams to calculate percentage distribution
    final double totalGrams = (protein + fat + carbs) > 0 ? (protein + fat + carbs) : 1;
    final double proteinRatio = protein / totalGrams;
    final double fatRatio = fat / totalGrams;
    final double carbsRatio = carbs / totalGrams;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSlate, width: 1),
      ),
      child: Column(
        children: [
          // Calories Header Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Toplam Besin Değerleri',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent),
                      const SizedBox(width: 4),
                      Text(
                        '${calories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryTeal, size: 28),
            ],
          ),
          const Divider(color: AppTheme.borderSlate, height: 24),
          // Macro Progress Indicators Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroProgress(
                context: context,
                label: 'Protein',
                value: '${protein.toStringAsFixed(1)} g',
                ratio: proteinRatio,
                color: Colors.redAccent,
              ),
              _buildMacroProgress(
                context: context,
                label: 'Yağ',
                value: '${fat.toStringAsFixed(1)} g',
                ratio: fatRatio,
                color: Colors.orange,
              ),
              _buildMacroProgress(
                context: context,
                label: 'Karb.',
                value: '${carbs.toStringAsFixed(1)} g',
                ratio: carbsRatio,
                color: Colors.blueAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgress({
    required BuildContext context,
    required String label,
    required String value,
    required double ratio,
    required Color color,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: ratio,
                strokeWidth: 6,
                backgroundColor: AppTheme.darkBg,
                color: color,
              ),
            ),
            Text(
              '${(ratio * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
