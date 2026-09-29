import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_theme.dart';
import 'seller_dashboard.dart';
import 'collection_screen.dart';
import 'my_previews_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'shop_screen.dart';
import 'help_support_screen.dart';

// ---------------------------------------------------------------------------
// AppDrawer — ArtSpace Preview (Screen #10)
// Side navigation drawer matching the design image:
// Shows user profile at the top, then 8 navigation items, and a sign-out.
// Opens via Navigator.push or Scaffold.drawer.
// ---------------------------------------------------------------------------

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final bool isLoggedIn = auth.firebaseUser != null;
    final String fullName = auth.firebaseUser?.displayName ??
        auth.firebaseUser?.email?.split('@').first ??
        'User';
    final String email = auth.firebaseUser?.email ?? '';

    return Drawer(
      backgroundColor: AppTheme.backgroundBeige,
      width: MediaQuery.of(context).size.width * 0.78,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- User Profile Header ---
            _buildProfileHeader(context, auth.profileImageUrl, fullName, email, isLoggedIn),

            const SizedBox(height: 8),

            const Divider(color: Color(0xFFEFECE6), thickness: 1),

            // --- Navigation Items ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),

                  if (auth.userRole == 'seller') ...[
                    _DrawerItem(
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard,
                      label: 'Seller Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SellerDashboard()),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],

                  _DrawerItem(
                    icon: Icons.collections_outlined,
                    activeIcon: Icons.collections,
                    label: 'My Collection',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CollectionScreen()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.photo_library_outlined,
                    activeIcon: Icons.photo_library,
                    label: 'My Previews',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyPreviewsScreen()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.storefront_outlined,
                    activeIcon: Icons.storefront,
                    label: 'Shop Artworks',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShopScreen()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.favorite_outline_rounded,
                    activeIcon: Icons.favorite,
                    label: 'Favorites',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CollectionScreen(showOnlyFavorites: true),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    activeIcon: Icons.help,
                    label: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    activeIcon: Icons.info,
                    label: 'About Us',
                    onTap: () {
                      Navigator.pop(context);
                      showAboutDialog(
                        context: context,
                        applicationName: 'ArtSpace Preview',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            '© 2024 ArtSpace. All rights reserved.',
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFFEFECE6), thickness: 1),

            // --- Sign Out at the bottom ---
            if (isLoggedIn)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: _DrawerItem(
                  icon: Icons.logout_rounded,
                  activeIcon: Icons.logout,
                  label: 'Sign Out',
                  onTap: () async {
                    Navigator.pop(context); // Close drawer
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String? profileImageUrl, String name, String email, bool isLoggedIn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          // Profile avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryAccent.withOpacity(0.2),
                width: 2,
              ),
              image: profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(profileImageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profileImageUrl == null
                ? Icon(Icons.person_outline, color: AppTheme.primaryAccent, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (isLoggedIn)
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Notification bell in header
          Icon(Icons.notifications_outlined,
              color: AppTheme.textMuted, size: 22),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DrawerItem — individual menu row in the drawer
// ---------------------------------------------------------------------------
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryAccent, size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
