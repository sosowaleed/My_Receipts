import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:my_receipts/models/transaction.dart';
import 'package:my_receipts/services/projection_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:my_receipts/widgets/transaction_overlay.dart';

class ProjectionLineChart extends StatefulWidget {
  final double initialBalance; // The balance at the VERY beginning of history
  final List<Transaction> historicalTransactions;
  final List<Transaction> activeRecurrentTransactions;
  final ProjectionPeriod period;
  final bool isSimulation;

  const ProjectionLineChart({
    super.key,
    required this.initialBalance,
    required this.historicalTransactions,
    required this.activeRecurrentTransactions,
    required this.period,
    this.isSimulation = false,
  });

  @override
  State<ProjectionLineChart> createState() => _ProjectionLineChartState();
}

class _ProjectionLineChartState extends State<ProjectionLineChart> {
  int? _highlightedSpotIndex;
  // This will now hold the single transaction associated with the highlighted spot
  Transaction? _highlightedTransaction;
  Timer? _highlightTimer;

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  /*void _showTransactionInfo(BuildContext context, List<Transaction> transactions, DateTime periodEndDate) {
    final l10n = AppLocalizations.of(context)!;
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final simProvider = Provider.of<SimulationProvider>(context, listen: false);
    final currencyFormat = NumberFormat.currency(
        locale: profileProvider.appLocale.toString(),
        symbol: profileProvider.appLocale.languageCode == 'ar' ? 'SAR' : '\$');

    // Determine if we are in a simulation context by checking the active provider
    final bool isSimulation = simProvider.isSimulating;

    showModalBottomSheet(
      context: context,
      builder: (modalCtx) { // Use a different context name to avoid confusion
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.transactionsInThisPeriod),
            leading: const CloseButton(),
            primary: false,
          ),
          body: transactions.isEmpty
              ? Center(child: Text(l10n.noTransactionsInThisPeriod))
              : ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (listCtx, index) {
              final tx = transactions[index];
              final isIncome = tx.type == TransactionType.income;

              return ListTile(
                leading: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
                title: Text(tx.description),
                subtitle: Text(
                  tx.isRecurrent
                      ? "Recurrent (${tx.recurrenceType})"
                      : DateFormat.yMd().format(tx.timestamp),
                ),
                trailing: Text(
                  currencyFormat.format(tx.amount),
                  style: TextStyle(
                      color: isIncome ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold),
                ),
                // --- ADD onTap HANDLER ---
                onTap: () {
                  // Close the transaction list bottom sheet first
                  Navigator.of(modalCtx).pop();

                  // Now open the edit overlay
                  showModalBottomSheet(
                    context: context, // Use the main screen's context
                    isScrollControlled: true,
                    builder: (overlayCtx) => TransactionOverlay(
                      type: tx.type,
                      existingTransaction: tx,
                      isSimulation: isSimulation,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }*/

  // Generate historical spots from real transactions.
  // Each spot directly corresponds to a transaction.
  List<FlSpot> _generateHistoricalSpots(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return [FlSpot(0, widget.initialBalance)];
    }

    final sortedTxs = List<Transaction>.from(transactions)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final List<FlSpot> spots = [];
    double runningBalance = widget.initialBalance;

    for (int i = 0; i < sortedTxs.length; i++) {
      final tx = sortedTxs[i];
      runningBalance += (tx.type == TransactionType.income ? tx.amount : -tx.amount);
      spots.add(FlSpot(i.toDouble(), runningBalance));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final projectionService = ProjectionService();
    // --- GENERATE BOTH DATA SETS ---
    final historicalSpots = _generateHistoricalSpots(widget.historicalTransactions);
    final lastHistoricalSpot = historicalSpots.isNotEmpty ? historicalSpots.last : FlSpot(0, widget.initialBalance);

    final projectionSpots = projectionService.generateProjection(
      startingBalance: lastHistoricalSpot.y,
      startingX: lastHistoricalSpot.x,
      historicalTransactions: widget.historicalTransactions,
      activeRecurrentTransactions: widget.activeRecurrentTransactions,
      period: widget.period,
    );
    // Combine historical and projection spots for axis calculation
    final allSpots = [...historicalSpots, ...projectionSpots];

    /*if (projectionData.spots.length < 2) {
      return Center(child: Text(l10n.noDataForPeriod('')));
    }*/

    double minY = double.maxFinite;
    double maxY = double.negativeInfinity;
    for (var spot in allSpots) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }
    final yPadding = (maxY - minY) * 0.1;
    minY -= yPadding;
    maxY += yPadding;
    if (minY.abs() == maxY.abs() || (maxY-minY).abs() < 1) {
      minY -= 10;
      maxY += 10;
    }

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineTouchData: LineTouchData(
                // This property is for drawing the indicator. It's called for whichever
                // bar the touch is registered on.
                getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                  // Since our touchCallback below will filter out touches on the projection line,
                  // this callback will now ONLY ever be called for barIndex 0.
                  // The style here will apply to the touched spot on the historical line.
                  return spotIndexes.map((spotIndex) {
                    return TouchedSpotIndicatorData(
                      const FlLine(color: Colors.blue, strokeWidth: 4),
                      FlDotData(
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 8,
                          color: Colors.blue,
                          strokeColor: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }).toList();
                },
                touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                  // If there's no touch or no spots were touched, do nothing.
                  if (response == null || response.lineBarSpots == null) {
                    // This part is important: if the user taps away from any line,
                    // we should clear the highlight.
                    if (event is FlTapUpEvent) {
                      setState(() {
                        _highlightedSpotIndex = null;
                        _highlightedTransaction = null;
                      });
                    }
                    return;
                  }

                  // We only care about when the touch is released.
                  if (event is FlTapUpEvent) {
                    // It's possible to touch multiple lines if they are close.
                    // We only care about the first one.
                    if (response.lineBarSpots!.isNotEmpty) {
                      final spot = response.lineBarSpots![0];

                      // CRITICAL FIX: Only react if the touch was on the historical line (barIndex 0).
                      if (spot.barIndex != 0) {
                        // If the user tapped the projection line, clear any existing highlight and do nothing else.
                        setState(() {
                          _highlightedSpotIndex = null;
                          _highlightedTransaction = null;
                        });
                        return;
                      }

                      // If we get here, the user tapped the historical line.
                      final spotIndex = spot.spotIndex;
                      setState(() {
                        _highlightedSpotIndex = spotIndex;
                        final sortedTxs = List<Transaction>.from(widget.historicalTransactions)
                          ..sort((a,b)=>a.timestamp.compareTo(b.timestamp));

                        // Safety check for index out of bounds
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
                      // User tapped on the chart but missed all lines.
                      setState(() {
                        _highlightedSpotIndex = null;
                        _highlightedTransaction = null;
                      });
                    }
                  }
                },
              ),
              lineBarsData: [
                // BAR 0: HISTORICAL
                LineChartBarData(
                  spots: historicalSpots,
                  isCurved: false,
                  color: Colors.grey[800],
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
                // BAR 1: PROJECTION
                LineChartBarData(
                  spots: projectionSpots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 4,
                  dashArray: [8, 4],
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
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

  /*Widget _getBottomTitleWidgets(
      double value, TitleMeta meta, ProjectionData data) {
    String text = '';
    final int index = value.toInt();
    final date = data.dateMap[index];
    if (date == null) return const SizedBox.shrink();

    int interval;
    switch (widget.period) {
      case ProjectionPeriod.day:
        interval = 7;
        break;
      case ProjectionPeriod.week:
        interval = 2;
        break;
      case ProjectionPeriod.month:
        interval = 3;
        break;
      case ProjectionPeriod.year:
        interval = 1;
        break;
    }

    if (index % interval == 0) {
      switch (widget.period) {
        case ProjectionPeriod.day:
          text = DateFormat.d(AppLocalizations.of(context)!.localeName).format(date);
          break;
        case ProjectionPeriod.week:
          text = 'W$index';
          break;
        case ProjectionPeriod.month:
          text = DateFormat.MMM(AppLocalizations.of(context)!.localeName).format(date);
          break;
        case ProjectionPeriod.year:
          text = DateFormat.y(AppLocalizations.of(context)!.localeName).format(date);
          break;
      }
    }

    return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: const TextStyle(fontSize: 10)));
  }*/

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
              // --- USE THE WIDGET'S FLAG HERE ---
              isSimulation: widget.isSimulation,
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          color: Theme.of(context).colorScheme.secondaryContainer,
          // --- THIS IS THE FIX: Using ListTile correctly ---
          child: ListTile(
            leading: Icon(
              tx.type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
              color: tx.type == TransactionType.income ? Colors.green : Colors.red,
            ),
            title: Text(
              tx.description,
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondaryContainer),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              DateFormat.yMd().format(tx.timestamp),
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
            ),
            // The trailing widget must be a single, constrained element.
            // A Column is unconstrained and will overflow. A Text widget is perfect.
            trailing: Text(
              NumberFormat.simpleCurrency(name: '\$').format(tx.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16, // Make it slightly larger
                color: tx.type == TransactionType.income ? Colors.green : Colors.red,
              ),
            ),
            dense: true, // Makes the ListTile more compact
          ),
        ),
      ),
    );
  }
}
