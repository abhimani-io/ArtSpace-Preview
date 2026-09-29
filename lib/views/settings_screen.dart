import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

// ---------------------------------------------------------------------------
// SettingsScreen — ArtSpace Preview (Screen #9)
// Lets users configure: App Theme, Language, Notifications, and view
// informational items (Privacy Policy, Terms, Rate Us, About).
// Settings are persisted to Firestore via SettingsController.
// ---------------------------------------------------------------------------

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Start streaming user settings from Firestore
    context.read<SettingsController>().startListening();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- Page Header ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textDark),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // --- Profile Header ---
            SliverToBoxAdapter(
              child: _buildProfileSection(context, auth),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // --- Preferences Group ---
            SliverToBoxAdapter(
              child: _buildSection(
                children: [
                  // App Theme selector
                  _buildNavigationTile(
                    icon: Icons.palette_outlined,
                    title: 'App Theme',
                    trailing: Text(
                      settings.theme,
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textMuted),
                    ),
                    onTap: () => _showThemePicker(context, settings),
                  ),
                  _buildDivider(),

                  // Language selector
                  _buildNavigationTile(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    trailing: Text(
                      settings.language,
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textMuted),
                    ),
                    onTap: () => _showLanguagePicker(context, settings),
                  ),
                  _buildDivider(),

                  // Notifications toggle
                  _buildSwitchTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    value: settings.notifications,
                    onChanged: (val) => settings.setNotifications(val),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // --- Legal + Info Group ---
            SliverToBoxAdapter(
              child: _buildSection(
                children: [
                  _buildNavigationTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Privacy Policy',
                    onTap: () => _showPrivacyDialog(context),
                  ),
                  _buildDivider(),
                  _buildNavigationTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () => _showTermsDialog(context),
                  ),
                  _buildDivider(),
                  _buildNavigationTile(
                    icon: Icons.star_outline_rounded,
                    title: 'Rate Us',
                    onTap: _requestReview,
                  ),
                  _buildDivider(),
                  _buildNavigationTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About App',
                    trailing: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textMuted),
                    ),
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // --- Sign Out ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () => _confirmSignOut(context, auth),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: AppTheme.smallRadius,
                      border: Border.all(
                          color: Colors.red.shade100, width: 1),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Profile Section
  // -------------------------------------------------------------------------
  Widget _buildProfileSection(BuildContext context, AuthController auth) {
    if (!auth.isAuthenticated) return const SizedBox.shrink();
    
    final fullName = auth.firebaseUser?.displayName ??
        auth.firebaseUser?.email?.split('@').first ??
        'User';
    final email = auth.firebaseUser?.email ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _pickAndUploadImage(auth),
            child: Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryAccent.withOpacity(0.2),
                      width: 2,
                    ),
                    image: auth.profileImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(auth.profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: auth.profileImageUrl == null
                      ? Icon(Icons.person_outline, color: AppTheme.primaryAccent, size: 36)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(AuthController auth) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final success = await auth.uploadAndUpdateProfileImage(bytes);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(auth.errorMessage ?? 'Failed to update profile picture.')),
          );
          auth.clearError();
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // Section wrapper with card styling
  // -------------------------------------------------------------------------
  Widget _buildSection({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: AppTheme.surfaceWhite,
        borderRadius: AppTheme.smallRadius,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppTheme.smallRadius,
            boxShadow: AppTheme.premiumShadow,
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  // Standard tappable row with icon, title, and optional trailing widget
  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.primaryAccent, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textDark,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) trailing,
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
        ],
      ),
    );
  }

  // Toggle row for boolean settings (Notifications)
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryAccent, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textDark,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryAccent,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 56,
    );
  }

  // -------------------------------------------------------------------------
  // Dialogs and pickers
  // -------------------------------------------------------------------------

  void _showThemePicker(BuildContext context, SettingsController settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text('App Theme',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16,
                    color: AppTheme.textDark)),
            const SizedBox(height: 12),
            ...['Light', 'Dark'].map(
              (theme) => ListTile(
                title: Text(theme),
                trailing: settings.theme == theme
                    ? Icon(Icons.check, color: AppTheme.primaryAccent)
                    : null,
                onTap: () {
                  settings.setTheme(theme);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsController settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text('Language',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16,
                    color: AppTheme.textDark)),
            const SizedBox(height: 12),
            ...['English', 'Spanish', 'French', 'German'].map(
              (lang) => ListTile(
                title: Text(lang),
                trailing: settings.language == lang
                    ? Icon(Icons.check, color: AppTheme.primaryAccent)
                    : null,
                onTap: () {
                  settings.setLanguage(lang);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'ArtSpace Preview',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 ArtSpace. All rights reserved.',
    );
  }

  void _confirmSignOut(BuildContext context, AuthController auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: TextStyle(color: AppTheme.textDark)),
        content: Text('Are you sure you want to sign out?',
            style: TextStyle(color: AppTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Terms of Service',
            style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              '''Welcome to ArtSpace! By using our app, you agree to the following terms:

1. Account Registration
- You must provide accurate information when creating an account.
- Users are responsible for maintaining the confidentiality of their passwords.

2. For Art Sellers (Artists)
- Sellers must own the copyright or have full permission to sell the artworks they upload.
- ArtSpace reserves the right to remove any artwork that violates copyright laws or community guidelines.

3. For Buyers
- All purchases made through ArtSpace are final once confirmed.
- Buyers are responsible for providing correct delivery and shipping details.

4. Intellectual Property
- All images, designs, and content uploaded by artists remain their intellectual property. Buyers purchase the physical art or usage rights, not the copyright itself.

5. Limitation of Liability
- ArtSpace acts as a platform to connect buyers and sellers. We are not liable for direct disputes regarding shipping delays or physical damages caused by third-party couriers.

6. Changes to Terms
- We may update these terms from time to time. Continued use of the app implies acceptance of the updated terms.

If you have any questions, contact us at: support@artspace.com''',
              style: TextStyle(color: AppTheme.textMuted, height: 1.4, fontSize: 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Privacy Policy',
            style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              '''Privacy Policy for ArtSpace

Effective Date: June 28, 2026

At ArtSpace, we take your privacy seriously. This Privacy Policy explains how we collect, use, and protect your personal information.

1. Information We Collect
- Personal Data: When you register, we collect your Full Name, Email Address, and Account Role (User or Seller).
- Transaction Data: For buyers and sellers, we keep track of order histories and shop listings created within the app.

2. How We Use Your Information
- To create and manage your secure account via Firebase Authentication.
- To store and display your profile details, art listings, and dashboard data using Firebase Firestore.
- To improve our app experience and communicate critical updates or support.

3. Data Security & Storage
- Your credentials (passwords) are securely encrypted and managed globally by Google Firebase. ArtSpace administrators cannot see your actual password.
- We implement industry-standard security measures to prevent unauthorized access or disclosure of your personal details.

4. Third-Party Services
- We use Google Firebase Services to host our backend database and authentication. These services comply with global privacy standards.
- We do not sell, rent, or trade your personal information to third-party marketing companies.

5. Your Rights
- You can update your profile name and security settings at any time directly from the Settings screen.
- If you wish to permanently delete your account and data, you can submit a request to our support team.

Contact Us: privacy@artspace.com''',
              style: TextStyle(color: AppTheme.textMuted, height: 1.4, fontSize: 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _requestReview() async {
    final InAppReview inAppReview = InAppReview.instance;
    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        // Fallback for iOS (replace 'YOUR_APP_STORE_ID' with your actual Apple App ID when published)
        await inAppReview.openStoreListing(appStoreId: 'YOUR_APP_STORE_ID');
      }
    } catch (e) {
      debugPrint("Error launching in-app review: \$e");
    }
  }
}
