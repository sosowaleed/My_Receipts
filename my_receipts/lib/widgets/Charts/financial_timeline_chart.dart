import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:my_receipts/models/transaction.dart';
import 'package:my_receipts/services/projection_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:my_receipts/widgets/transaction_overlay.dart';
import 'package:my_receipts/models/timeline_period.dart';
import 'package:my_receipts/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class FinancialTimelineChart extends StatefulWidget {
  final double initialBalance; // The balance at the VERY beginning of history
  final List<Transaction> transactions;
  final List<Transaction> activeRecurrentTransactions;
  final TimelinePeriod period;
  final bool isSimulation;
  final DateTime viewingDate;

  const FinancialTimelineChart({
    super.key,
    required this.initialBalance,
    required this.transactions,
    required this.activeRecurrentTransactions,
    required this.period,
    this.isSimulation = false,
    required this.viewingDate,
  });

  @override
  State<FinancialTimelineChart> createState() => _FinancialTimelineChartState();
}

class _FinancialTimelineChartState extends State<FinancialTimelineChart> {
  int? _highlightedSpotIndex;

  // This will now hold the single transaction associated with the highlighted spot
  Transaction? _highlightedTransaction;
  Timer? _highlightTimer;

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  // Helper function to generate spots for the line chart
  List<FlSpot> _generateHistoricalSpots(List<Transaction> transactions) {
    if (transactions.isEmpty) return [];

    final sortedTxs = List<Transaction>.from(transactions)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final List<FlSpot> spots = [];
    double runningBalance = widget.initialBalance;

    for (final tx in sortedTxs) {
      runningBalance +=
          (tx.type == TransactionType.income ? tx.amount : -tx.amount);
      // X-axis is now time (millisecondsSinceEpoch), Y-axis is balance
      spots.add(FlSpot(
          tx.timestamp.millisecondsSinceEpoch.toDouble(), runningBalance));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final projectionService = ProjectionService();

    final historicalSpots = _generateHistoricalSpots(widget.transactions);

    List<FlSpot> projectionSpots = [];
    bool showProjection = (widget.period == TimelinePeriod.year ||
            widget.period == TimelinePeriod.all) &&
        widget.viewingDate.year >= DateTime.now().year;

    if (showProjection) {
      // Start from the last historical point or now if no history exists
      final lastSpot = historicalSpots.isNotEmpty
          ? historicalSpots.last
          : FlSpot(DateTime.now().millisecondsSinceEpoch.toDouble(),
              widget.initialBalance);

      final projectionData = projectionService.generateProjection(
        startingBalance: lastSpot.y,
        startingX: lastSpot.x,
        historicalTransactions: widget.transactions,
        activeRecurrentTransactions: widget.activeRecurrentTransactions,
        period: widget.period,
        useTimestampX: true, // Use timestamps for X-axis alignment
      );

      projectionSpots = projectionData.spots;
    }

    // --- Dynamic Axis Range Calculation ---
    final allSpots = [...historicalSpots, ...projectionSpots];
    double minY = 0; // Start Y-axis at 0
    double maxY = widget.initialBalance;
    for (var spot in allSpots) {
      if (spot.y > maxY) maxY = spot.y;
      if (spot.y < minY) minY = spot.y;
    }

    final yPadding = (maxY - minY) * 0.1;
    minY -= yPadding;
    maxY += yPadding;

    if ((maxY - minY).abs() < 1) {
      minY -= 10;
      maxY += 10;
    }

    DateTime start, end;
    double interval;

    switch (widget.period) {
      case TimelinePeriod.week:
        start = widget.viewingDate
            .subtract(Duration(days: widget.viewingDate.weekday % 7));
        start = DateTime(start.year, start.month, start.day);
        end = start
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        interval = const Duration(days: 1).inMilliseconds.toDouble();
        break;
      case TimelinePeriod.month:
        start = DateTime(widget.viewingDate.year, widget.viewingDate.month, 1);
        end = DateTime(widget.viewingDate.year, widget.viewingDate.month + 1, 0,
            23, 59, 59);
        interval = const Duration(days: 7).inMilliseconds.toDouble();
        break;
      case TimelinePeriod.year:
        start = DateTime(widget.viewingDate.year, 1, 1);
        end = DateTime(widget.viewingDate.year, 12, 31, 23, 59, 59);
        interval = const Duration(days: 30).inMilliseconds.toDouble();
        break;
      case TimelinePeriod.all:
        if (allSpots.isEmpty) {
          start = widget.viewingDate;
          end = widget.viewingDate.add(const Duration(days: 30));
        } else {
          double minTimestamp =
              allSpots.map((s) => s.x).reduce((a, b) => a < b ? a : b);
          double maxTimestamp =
              allSpots.map((s) => s.x).reduce((a, b) => a > b ? a : b);
          start = DateTime.fromMillisecondsSinceEpoch(minTimestamp.toInt());
          end = DateTime.fromMillisecondsSinceEpoch(maxTimestamp.toInt());
        }
        interval = const Duration(days: 365).inMilliseconds.toDouble();
        break;
      case TimelinePeriod.day:
        start = DateTime(widget.viewingDate.year, widget.viewingDate.month,
            widget.viewingDate.day);
        end = DateTime(widget.viewingDate.year, widget.viewingDate.month,
            widget.viewingDate.day, 23, 59, 59);
        interval = const Duration(hours: 4).inMilliseconds.toDouble();
        break;
    }

    double minX = start.millisecondsSinceEpoch.toDouble();
    double maxX = end.millisecondsSinceEpoch.toDouble();

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              clipData: const FlClipData.all(),
              minX: minX,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: interval,
                    getTitlesWidget: _getBottomTitleWidgets,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(NumberFormat.compact().format(value)),
                      );
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineTouchData: LineTouchData(
                getTouchedSpotIndicator:
                    (LineChartBarData barData, List<int> spotIndexes) {
                      if (barData.spots != historicalSpots) return [];
                  return spotIndexes.map((spotIndex) {
                    return TouchedSpotIndicatorData(
                      const FlLine(color: Colors.blue, strokeWidth: 4),
                      FlDotData(
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 8,
                          color: Colors.blue,
                          strokeColor: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }).toList();
                },
                touchCallback:
                    (FlTouchEvent event, LineTouchResponse? response) {
                  if (response == null || response.lineBarSpots == null) {
                    if (event is FlTapUpEvent) {
                      setState(() {
                        _highlightedSpotIndex = null;
                        _highlightedTransaction = null;
                      });
                    }
                    return;
                  }

                  if (event is FlTapUpEvent) {
                    if (response.lineBarSpots!.isNotEmpty) {
                      final spot = response.lineBarSpots![0];

                      if (spot.barIndex != 0) {
                        setState(() {
                          _highlightedSpotIndex = null;
                          _highlightedTransaction = null;
                        });
                        return;
                      }

                      final spotIndex = spot.spotIndex;
                      setState(() {
                        _highlightedSpotIndex = spotIndex;
                        final sortedTxs = List<Transaction>.from(
                            widget.transactions)
                          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                        if (spotIndex < sortedTxs.length) {
                          _highlightedTransaction = sortedTxs[spotIndex];
                        }

                        _highlightTimer?.cancel();
                        _highlightTimer = Timer(const Duration(seconds: 5), () {
                          if (mounted) {
                            setState(() {
                              _highlightedSpotIndex = null;
                              _highlightedTransaction = null;
                            });
                          }
                        });
                      });
                    } else {
                      setState(() {
                        _highlightedSpotIndex = null;
                        _highlightedTransaction = null;
                      });
                    }
                  }
                },
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: historicalSpots,
                  isCurved: false,
                  color: Colors.grey[800],
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: projectionSpots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 4,
                  dashArray: [8, 4],
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2)),
                ),
              ],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _highlightedTransaction != null ? 80 : 0,
          child: _highlightedTransaction != null
              ? _buildHighlightWidget(_highlightedTransaction!)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _getBottomTitleWidgets(double value, TitleMeta meta) {
    final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    String text = '';
    switch (widget.period) {
      case TimelinePeriod.day:
        text = DateFormat.j().format(dt); // Hour
        break;
      case TimelinePeriod.week:
        text = DateFormat.E().format(dt); // Day of week (Mon, Tue)
        break;
      case TimelinePeriod.month:
        final weekOfMonth = (dt.day / 7).ceil();
        text = 'W$weekOfMonth';
        break;
      case TimelinePeriod.year:
        text = DateFormat.MMM().format(dt); // Month
        break;
      case TimelinePeriod.all:
        text = DateFormat.y().format(dt); // Year
        break;
    }
    return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(text, style: const TextStyle(fontSize: 10)));
  }

  Widget _buildHighlightWidget(Transaction tx) {
    return ClipRect(
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (overlayCtx) => TransactionOverlay(
              type: tx.type,
              existingTransaction: tx,
              isSimulation: widget.isSimulation,
            ),
          );
          // --- Trigger refresh after editing ---
          if (mounted) {
            if (widget.isSimulation) {
              // Simulation handles notifyListeners in SimulationProvider
            } else {
              Provider.of<ProfileProvider>(context, listen: false).refreshCurrentProfile();
            }

            // Clear highlight after edit to reflect changes
            setState(() {
              _highlightedTransaction = null;
            });
          }
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: ListTile(
            leading: Icon(
              tx.type == TransactionType.income
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color:
                  tx.type == TransactionType.income ? Colors.green : Colors.red,
            ),
            title: Text(
              tx.description,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondaryContainer),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              DateFormat.yMd().format(tx.timestamp),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer),
            ),
            trailing: Text(
              NumberFormat.simpleCurrency(name: '\$').format(tx.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: tx.type == TransactionType.income
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            dense: true,
          ),
        ),
      ),
    );
  }
}
