import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CategoryBreakdownPieChart extends StatelessWidget {
  final Map<String, double> categoryData;
  final List<Color> colors;
  final String noDataText;

  const CategoryBreakdownPieChart({
    super.key,
    required this.categoryData,
    required this.colors,
    this.noDataText = "No data for this period",
  });

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return Center(child: Text(noDataText));
    }
    final totalValue = categoryData.values.fold(0.0, (sum, item) => sum + item);
    if (totalValue == 0) {
      return Center(child: Text(noDataText));
    }

    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    categoryData.forEach((category, amount) {
      final percentage = (amount / totalValue) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
      );
      colorIndex++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
}

class PieChartLegend extends StatelessWidget {
  final Map<String, double> categoryData;
  final List<Color> colors;

  const PieChartLegend({
    super.key,
    required this.categoryData,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) return const SizedBox.shrink();

    int colorIndex = 0;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: categoryData.keys.map((category) {
            final widget = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 16, height: 16, color: colors[colorIndex % colors.length]),
                const SizedBox(width: 4),
                Text(category == 'Uncategorized' ? l10n.uncategorized : category),
              ],
            );
            colorIndex++;
            return widget;
          }).toList(),
        ),
      ),
    );
  }
}