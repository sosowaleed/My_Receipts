import 'package:flutter/material.dart';
import 'package:my_receipts/models/sim.dart';
import 'package:my_receipts/models/transaction.dart';
import 'package:my_receipts/services/database_service.dart';

class SimulationProvider with ChangeNotifier {
  final dbService = DatabaseService.instance;

  Sim? _activeSimulation;
  List<Transaction> _simulatedTransactions = [];
  bool _isSimulating = false;

  Sim? get activeSimulation => _activeSimulation;
  List<Transaction> get simulatedTransactions => _simulatedTransactions;
  bool get isSimulating => _isSimulating;

  /// Starts a simulation session with a given Sim object and its transactions.
  void startSimulation(Sim sim, List<Transaction> initialTxs) {
    _activeSimulation = sim;
    _simulatedTransactions = initialTxs;
    _isSimulating = true;
    notifyListeners();
  }

  /// Ends the current simulation session, clearing the state.
  void stopSimulation() {
    _activeSimulation = null;
    _simulatedTransactions = [];
    _isSimulating = false;
    notifyListeners();
  }

  /// Adds a new transaction to the active simulation and its database table.
  Future<void> addSimulatedTransaction(Transaction tx) async {
    if (!_isSimulating) return;
    final newTx = await dbService.createSimulatedTransaction(tx, _activeSimulation!.id);
    _simulatedTransactions.add(newTx);
    notifyListeners();
  }

  /// Updates an existing transaction in the active simulation.
  Future<void> updateSimulatedTransaction(Transaction tx) async {
    if (!_isSimulating) return;
    await dbService.updateSimulatedTransaction(tx);
    final index = _simulatedTransactions.indexWhere((t) => t.id == tx.id);
    if (index != -1) {
      _simulatedTransactions[index] = tx;
      notifyListeners();
    }
  }

  /// Deletes a transaction from the active simulation.
  Future<void> deleteSimulatedTransaction(int txId) async {
    if (!_isSimulating) return;
    await dbService.deleteSimulatedTransaction(txId);
    _simulatedTransactions.removeWhere((t) => t.id == txId);
    notifyListeners();
  }
}