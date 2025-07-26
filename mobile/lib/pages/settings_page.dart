import 'package:flutter/material.dart';
import 'package:i_cant_cook/providers/auth_provider.dart';
import 'package:i_cant_cook/providers/settings_provider.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/widgets/dialogs/personal_info_dialog.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Settings',
            style: TextStyle(color: ColorPalette.offWhite),
          ),
          backgroundColor: ColorPalette.darkgray,
          iconTheme: const IconThemeData(color: ColorPalette.offWhite),
        ),
        backgroundColor: ColorPalette.darkergray,
        body: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.person, color: ColorPalette.offWhite),
                  title: const Text("Personal Information",
                      style: TextStyle(color: ColorPalette.offWhite)),
                  onTap: () => _openPersonalInfoModal(context),
                ),
                const Divider(height: 32, color: ColorPalette.placeholdergray),
                Consumer<AuthProvider>(builder: (context, authProvider, _) {
                  return ListTile(
                    leading:
                        const Icon(Icons.logout, color: ColorPalette.offWhite),
                    title: const Text("Logout",
                        style: TextStyle(color: ColorPalette.offWhite)),
                    onTap: () => authProvider.logout().then(
                          (_) => Navigator.of(context)
                              .pushReplacementNamed('/login'),
                        ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openPersonalInfoModal(BuildContext context) async {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    await settingsProvider.fetchAndLoadPersonalInfo();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorPalette.darkgray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const PersonalInfoDialog(),
    );
  }
}
