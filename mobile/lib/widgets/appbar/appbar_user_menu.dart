import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/auth_api.dart';
import 'package:i_cant_cook/models/user/user.dart';
import 'package:i_cant_cook/pages/user_profile_page.dart';
import 'package:i_cant_cook/theme/avatars.dart';
import 'package:i_cant_cook/theme/colors.dart';

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _currentUser,
      builder: (context, snapshot) {
        final currentUser = snapshot.data;
        if (currentUser == null) {
          return const SizedBox.shrink();
        }
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
              await _authApi.logout();
              if (mounted) {
                Navigator.pop(context);
              }
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: ColorPalette.offBlack,
          position: PopupMenuPosition.under,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 0,
              child: Row(
                children: [
                  Icon(Icons.person, color: ColorPalette.offWhite),
                  SizedBox(width: 8),
                  Text("Profile",
                      style: TextStyle(color: ColorPalette.offWhite)),
                ],
              ),
            ),
            const PopupMenuDivider(), // Divider
            PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  Icon(Icons.logout, color: ColorPalette.offWhite),
                  SizedBox(width: 8),
                  Text("Logout",
                      style: TextStyle(color: ColorPalette.offWhite)),
                ],
              ),
            ),
          ],
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: CircleAvatar(
              backgroundColor: ColorPalette.lightgray,
              child: Avatars.getAvatarIcon(currentUser.avatar_icon),
            ),
          ),
        );
      },
    );
  }
}
