import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/auth_api.dart';
import 'package:i_cant_cook/models/user/user.dart';
import 'package:i_cant_cook/pages/login_page.dart';
import 'package:i_cant_cook/pages/user_profile_page.dart';
import 'package:i_cant_cook/pages/settings_page.dart';
import 'package:i_cant_cook/theme/avatars.dart';
import 'package:i_cant_cook/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class UserMenuWidget extends StatefulWidget {
  const UserMenuWidget({Key? key}) : super(key: key);

  @override
  _UserMenuWidgetState createState() => _UserMenuWidgetState();
}

class _UserMenuWidgetState extends State<UserMenuWidget> {
  late Future<User?> _currentUser;
  final AuthApi _authApi = AuthApi();

  @override
  void initState() {
    super.initState();
    _currentUser = _fetchUser();
  }

  Future<User?> _fetchUser() async {
    return await AuthApi.getUser();
  }

  void _toggleTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _currentUser,
      builder: (context, snapshot) {
        final currentUser = snapshot.data;
        if (currentUser == null) {
          return const SizedBox.shrink();
        }
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return PopupMenuButton<int>(
              onSelected: (value) async {
                if (value == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(user: currentUser),
                    ),
                  );
                } else if (value == 1) {
                  _toggleTheme();
                } else if (value == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                } else if (value == 3) {
                  await _authApi.logout();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  }
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme.of(context).colorScheme.surface,
              position: PopupMenuPosition.under,
              elevation: 8,
              shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 0,
                  child: _buildMenuItem(
                    icon: Icons.person,
                    label: "Profile",
                    context: context,
                  ),
                ),
                PopupMenuItem(
                  value: 1,
                  child: _buildMenuItem(
                    icon: themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    label: themeProvider.isDarkMode ? "Light Mode" : "Dark Mode",
                    context: context,
                  ),
                ),
                PopupMenuItem(
                  value: 2,
                  child: _buildMenuItem(
                    icon: Icons.settings,
                    label: "Settings",
                    context: context,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 3,
                  child: _buildMenuItem(
                    icon: Icons.logout,
                    label: "Logout",
                    context: context,
                    isDestructive: true,
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Avatars.getAvatarIcon(currentUser.avatar_icon),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required BuildContext context,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDestructive
                  ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}