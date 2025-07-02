import 'package:flutter/material.dart';
import 'package:my_receipts/providers/profile_provider.dart';
import 'package:my_receipts/screens/prompt_screen.dart';
import 'package:my_receipts/screens/receipt_review_screen.dart';
import 'package:my_receipts/widgets/transaction_overlay.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:my_receipts/models/transaction.dart';

import '../models/profile.dart';
import '../services/csv_service.dart';
import '../utils/snackbar_helper.dart';
// Import other necessary files like csv_service later

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder will help us build different UIs based on screen width
    return LayoutBuilder(
      builder: (context, constraints) {
        // A common breakpoint for tablets
        final isWideScreen = constraints.maxWidth > 720;

        if (isWideScreen) {
          return _buildWideLayout(context);
        } else {
          return _buildNarrowLayout(context);
        }
      },
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, isWideScreen: false),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Row(
        children: [
          // The receipt review screen on the left
          const Expanded(
            flex: 2, // Takes 2/3 of the space
            child: ReceiptReviewScreen(),
          ),
          const VerticalDivider(width: 1),
          // The main home controls on the right
          Expanded(
            flex: 1, // Takes 1/3 of the space
            child: _buildBody(context, isWideScreen: true),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      title: Text(l10n.appName),
      actions: [
        // Language Selector
        PopupMenuButton<Locale>(
          onSelected: (Locale locale) {
            provider.setLocale(locale);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
            const PopupMenuItem<Locale>(
              value: Locale('en'),
              child: Text('English'),
            ),
            const PopupMenuItem<Locale>(
              value: Locale('ar'),
              child: Text('العربية'),
            ),
          ],
          icon: const Icon(Icons.language),
        ),
        // Profile Selector
        Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            return IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: l10n.profiles,
              onPressed: () => _showProfileDialog(context),
            );
          },
        ),
      ],
    );
  }

  void _showEditProfileNameDialog(BuildContext context, Profile profile) {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: profile.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.edit),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.profileName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final newName = nameController.text;
              if (newName.isNotEmpty && newName != profile.name) {
                provider.updateProfileName(profile.id!, newName);
              }
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: Text(l10n.profiles),
          children: [
            // Map each profile to a custom dialog option
            ...provider.allProfiles.map((profile) {
              final bool isCurrent = provider.currentProfile?.id == profile.id;
              return SimpleDialogOption(
                onPressed: () {
                  provider.switchProfile(profile.id!);
                  Navigator.pop(dialogContext);
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.name,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                    ),
                    // Profile edit icon
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      tooltip: l10n.edit,
                      onPressed: () {
                        Navigator.pop(dialogContext); // Close profile list
                        _showEditProfileNameDialog(context, profile);
                      },
                    ),
                    // Adjacent delete button
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red.shade600,
                      tooltip: l10n.deleteProfile,
                      onPressed: () {
                        // First, close the profile list dialog
                        Navigator.pop(dialogContext);
                        // Then, show the confirmation dialog
                        _confirmDeleteProfile(context, profile);
                      },
                    ),
                  ],
                ),
              );
            }),
            // Separator before the "Add" option
            const Divider(),
            // The "Add Profile" option
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                showDialog(
                  context: context,
                  builder: (_) => const Dialog(child: PromptScreen(isOverlay: true)),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.add),
                  const SizedBox(width: 8),
                  Text(l10n.addProfile),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteProfile(BuildContext context, Profile profile) {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteProfile),
        content: Text(l10n.confirmDeleteProfile(profile.name).replaceAll('{profileName}', profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              provider.deleteProfile(profile.id!);
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.ok, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool isWideScreen}) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          final walletAmount = provider.currentProfile?.walletAmount ?? 0.0;
          final currencyFormat = NumberFormat.currency(
            locale: provider.appLocale.toString(),
            symbol: provider.appLocale.languageCode == 'ar' ? 'SAR' : '\$', // Example symbols
          );

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currencyFormat.format(walletAmount),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: walletAmount >= 0 ? Colors.green : Colors.red),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 300,
                height: 300,
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _HomeIconButton(
                        icon: Icons.arrow_downward,
                        label: l10n.homeIncoming,
                        color: Colors.green,
                        onPressed: () => _showTransactionOverlay(context, TransactionType.income)),
                    _HomeIconButton(
                        icon: Icons.arrow_upward,
                        label: l10n.homeOutgoing,
                        color: Colors.red,
                        onPressed: () => _showTransactionOverlay(context, TransactionType.outgoing)),
                    _HomeIconButton(
                        icon: Icons.receipt_long,
                        label: l10n.homeReview,
                        color: Colors.blue,
                        // On narrow screen, navigate. On wide, it's already visible.
                        onPressed: isWideScreen ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReceiptReviewScreen()))),
                    _HomeIconButton(
                        icon: Icons.import_export,
                        label: l10n.homeImportExport,
                        color: Colors.orange,
                        onPressed: () => _showImportExportDialog(context)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showImportExportDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final csvService = CsvService();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importExportTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: Text(l10n.importAction),
              onTap: () async {
                Navigator.of(ctx).pop(); // Close dialog first
                final success = await csvService.importFromCsv(provider.currentProfile!.id!);
                if (success) {
                  await provider.loadInitialData(); // Full refresh
                  SnackbarHelper.show(context, l10n.importSuccess);
                } else {
                  SnackbarHelper.show(context, l10n.importFailedCheckFormat, isError: true);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: Text(l10n.exportAction),
              onTap: () {
                // Close the first dialog...
                Navigator.of(ctx).pop();
                // ...and show the new calendar choice dialog.
                _showCalendarChoiceForExport(context);
              },
            ),
          ],
        ),
      ),
    );
  }

// Add this new private method to the HomeScreen class
  void _showCalendarChoiceForExport(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final csvService = CsvService();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.calendarPreference),
        content: const Text("Choose the calendar format for the exported date column."),
        actions: [
          TextButton(
            child: Text(l10n.gregorian),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close calendar choice dialog
              final path = await csvService.exportToCsv(
                provider.transactions,
                provider.currentProfile!.name,
                dialogTitle: l10n.selectExportLocation,
                calendarType: 'gregorian', // Pass the choice
              );
              if (path != null && context.mounted) {
                SnackbarHelper.show(context, l10n.exportSuccess(path.split('/').last).replaceAll('{path}', path));
              }
            },
          ),
          TextButton(
            child: Text(l10n.hijri),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close calendar choice dialog
              final path = await csvService.exportToCsv(
                provider.transactions,
                provider.currentProfile!.name,
                dialogTitle: l10n.selectExportLocation,
                calendarType: 'hijri', // Pass the choice
              );
              if (path != null && context.mounted) {
                SnackbarHelper.show(context, l10n.exportSuccess(path.split('/').last).replaceAll('{path}', path));
              }
            },
          ),
        ],
      ),
    );
  }

  void _showTransactionOverlay(BuildContext context, TransactionType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionOverlay(type: type),
    );
  }
}

// A helper widget for the home screen buttons
class _HomeIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _HomeIconButton({required this.icon, required this.label, required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: onPressed == null ? Colors.grey : color),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}