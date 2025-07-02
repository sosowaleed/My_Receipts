import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:my_receipts/models/category.dart';
import 'package:my_receipts/models/transaction.dart';
import 'package:my_receipts/providers/profile_provider.dart';
import 'package:my_receipts/utils/snackbar_helper.dart';
import 'package:provider/provider.dart';

// A simple class to hold controllers for one draft transaction
class _DraftTransaction {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descController = TextEditingController(text: " ");
  final TextEditingController quantityController = TextEditingController(text: "1");
  int? selectedCategoryId;
}

class TransactionOverlay extends StatefulWidget {
  final TransactionType type;
  final Transaction? existingTransaction; // Used for editing
  const TransactionOverlay({super.key, required this.type, this.existingTransaction});

  @override
  State<TransactionOverlay> createState() => _TransactionOverlayState();
}

class _TransactionOverlayState extends State<TransactionOverlay> {
  late List<_DraftTransaction> _drafts;
  bool get _isEditing => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    _drafts = [_DraftTransaction()];
    if (_isEditing) {
      final tx = widget.existingTransaction!;
      _drafts.first.amountController.text = tx.amount.toString();
      _drafts.first.descController.text = tx.description;
      _drafts.first.quantityController.text = tx.quantity.toString();
      _drafts.first.selectedCategoryId = tx.categoryId;
    }
  }

  @override
  void dispose() {
    for (var draft in _drafts) {
      draft.amountController.dispose();
      draft.descController.dispose();
      draft.quantityController.dispose();
    }
    super.dispose();
  }

  Future<void> _saveTransactions() async {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    bool allValid = true;

    // Validate all forms
    for (var draft in _drafts) {
      if (!draft.formKey.currentState!.validate()) {
        allValid = false;
      }
    }

    if (!allValid) return;

    if (_isEditing) {
      // Handle update for a single transaction
      final draft = _drafts.first;
      final updatedTx = Transaction(
        id: widget.existingTransaction!.id,
        profileId: widget.existingTransaction!.profileId,
        type: widget.type,
        amount: double.parse(draft.amountController.text),
        description: draft.descController.text,
        categoryId: draft.selectedCategoryId!,
        quantity: int.parse(draft.quantityController.text),
        timestamp: widget.existingTransaction!.timestamp, // Keep original timestamp on edit
      );
      await provider.updateTransaction(updatedTx, widget.existingTransaction!);
      if (mounted) SnackbarHelper.show(context, l10n.transactionUpdated);
    } else {
      // Handle adding new transactions
      final List<Transaction> newTransactions = [];
      for (var draft in _drafts) {
        newTransactions.add(Transaction(
          profileId: provider.currentProfile!.id!,
          type: widget.type,
          amount: double.parse(draft.amountController.text),
          description: draft.descController.text,
          categoryId: draft.selectedCategoryId!,
          quantity: int.parse(draft.quantityController.text),
          timestamp: DateTime.now(),
        ));
      }
      await provider.addBatchTransactions(newTransactions);
      if (mounted) SnackbarHelper.show(context, l10n.transactionSaved);
    }

    if (mounted) Navigator.of(context).pop();
  }

  void _addAnotherReceipt() {
    setState(() {
      _drafts.add(_DraftTransaction());
    });
  }

  void _removeReceiptAt(int index) {
    setState(() {
      _drafts.removeAt(index);
    });
  }

  Future<void> _handleCategorySelection(String? value, _DraftTransaction draft) async {
    if (value == 'add_new') {
      final l10n = AppLocalizations.of(context)!;
      final newCategoryName = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final controller = TextEditingController();
          return AlertDialog(
            title: Text(l10n.enterCategoryName),
            content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: l10n.categoryName)),
            actions: [
              TextButton(child: Text(l10n.cancel), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(child: Text(l10n.save), onPressed: () => Navigator.of(ctx).pop(controller.text)),
            ],
          );
        },
      );
      if (newCategoryName != null && newCategoryName.isNotEmpty) {
        final provider = Provider.of<ProfileProvider>(context, listen: false);
        final newCategory = await provider.addCategory(newCategoryName, widget.type);
        setState(() {
          draft.selectedCategoryId = newCategory.id;
        });
        if (mounted) SnackbarHelper.show(context, l10n.categoryAdded(newCategoryName).replaceAll('{categoryName}', newCategoryName));
      }
    } else {
      setState(() {
        draft.selectedCategoryId = int.parse(value!);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _isEditing ? l10n.editTransaction : (widget.type == TransactionType.income ? l10n.incomeOverlayTitle : l10n.outgoingOverlayTitle);

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        child: Padding(
          // This is the inner padding for aesthetics only.
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _drafts.length,
                itemBuilder: (context, index) {
                  return _buildTransactionForm(_drafts[index], index, l10n);
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!_isEditing)
                    TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(l10n.addAnother),
                      onPressed: _addAnotherReceipt,
                    ),
                  const Spacer(),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel)),
                  ElevatedButton(
                      onPressed: _saveTransactions, child: Text(l10n.save)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionForm(_DraftTransaction draft, int index, AppLocalizations l10n) {
    return Form(
      key: draft.formKey,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              if (!_isEditing && _drafts.length > 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeReceiptAt(index),
                  ),
                ),
              TextFormField(
                controller: draft.amountController,
                decoration: InputDecoration(labelText: l10n.amount),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || double.tryParse(v) == null) ? l10n.errorInvalidNumber : null,
              ),
              TextFormField(
                controller: draft.descController,
                decoration: InputDecoration(labelText: l10n.description),
                validator: (v) => (v == null || v.isEmpty) ? l10n.errorFieldRequired : null,
              ),
              Consumer<ProfileProvider>(
                builder: (context, provider, child) {
                  // Choose the correct category list based on the overlay's type
                  final categories = widget.type == TransactionType.income
                      ? provider.incomeCategories
                      : provider.outgoingCategories;

                  return DropdownButtonFormField<String>(
                    value: draft.selectedCategoryId?.toString(),
                    hint: Text(l10n.category),
                    isExpanded: true,
                    items: [
                      ...categories.map((Category cat) { // Use the correct list
                        return DropdownMenuItem<String>(
                          value: cat.id.toString(),
                          child: Text(cat.name),
                        );
                      }),
                      DropdownMenuItem<String>(
                        value: 'add_new',
                        child: Text(l10n.addNewCategory, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue)),
                      ),
                    ],
                    onChanged: (value) => _handleCategorySelection(value, draft),
                    validator: (v) => v == null || v == 'add_new' ? l10n.errorFieldRequired : null,
                  );
                },
              ),
              TextFormField(
                controller: draft.quantityController,
                decoration: InputDecoration(labelText: l10n.quantity),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || int.tryParse(v) == null) ? l10n.errorInvalidNumber : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}