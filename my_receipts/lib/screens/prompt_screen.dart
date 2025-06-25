import 'package:flutter/material.dart';
import 'package:my_receipts/models/profile.dart';
import 'package:my_receipts/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PromptScreen extends StatefulWidget {
  // isOverlay will be true when adding a new profile from the home screen
  final bool isOverlay;
  const PromptScreen({super.key, this.isOverlay = false});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: "Default Profile");
  final _walletController = TextEditingController(text: "0");
  String _selectedCalendar = 'gregorian';

  @override
  void dispose() {
    _nameController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final profile = Profile(
        name: _nameController.text,
        walletAmount: double.tryParse(_walletController.text) ?? 0.0,
        calendarPreference: _selectedCalendar,
      );

      Provider.of<ProfileProvider>(context, listen: false).addProfile(profile);

      if (widget.isOverlay) {
        Navigator.of(context).pop();
      }
      // If not an overlay, the AuthWrapper in main.dart will handle navigation
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
          title: Text(l10n.promptScreenTitle)
        , actions: [
        // Language switcher for the first-time user
        if (!widget.isOverlay)
          Consumer<ProfileProvider>(
            builder: (context, provider, child) => PopupMenuButton<Locale>(
              onSelected: (Locale locale) {
                provider.setLocale(locale);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
                const PopupMenuItem<Locale>(value: Locale('en'), child: Text('English')),
                const PopupMenuItem<Locale>(value: Locale('ar'), child: Text('العربية')),
              ],
              icon: const Icon(Icons.language),
            ),
          ),
      ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.profileName),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.errorFieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _walletController,
                decoration: InputDecoration(labelText: l10n.initialWallet),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return l10n.errorInvalidNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(l10n.calendarPreference,
                  style: Theme.of(context).textTheme.titleMedium),
              DropdownButton<String>(
                value: _selectedCalendar,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCalendar = newValue!;
                  });
                },
                items: <String>['gregorian', 'hijri']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                        value == 'gregorian' ? l10n.gregorian : l10n.hijri),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
