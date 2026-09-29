import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/workspace_controller.dart';
import '../utils/app_theme.dart';
import 'app_drawer.dart';
import 'collection_screen.dart';
import 'my_previews_screen.dart';
import 'art_hunt_screen.dart';
import 'settings_screen.dart';
import 'workspace_screen.dart';
import 'shop_screen.dart';
import 'login_screen.dart';
import 'custom_camera_screen.dart';
import 'select_artwork_screen.dart';
import 'seller_dashboard.dart';
import 'register_screen.dart';

// ---------------------------------------------------------------------------
// HomeScreen — ArtSpace Preview (Screen #2)
// The main dashboard. Features a time-aware header, a dark promotional hero
// card with a CTA, a 2×2 Quick Actions grid, and a 5-tab persistent bottom
// navigation bar wired to all real screens. The notification bell opens the
// AppDrawer for side navigation.
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tracks the active tab index for the custom bottom nav bar
  int _currentIndex = 0;

  // Returns a time-appropriate greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  // Switches between real screen widgets for each tab
  Widget _buildBodyForIndex(int index) {
    switch (index) {
      case 0:
        return _HomeContent(greeting: _getGreeting());
      case 1:
        return const CollectionScreen();
      case 2:
        return const ShopScreen();
      case 3:
        return const MyPreviewsScreen();
      case 4:
        return const SettingsScreen();
      default:
        return _HomeContent(greeting: _getGreeting());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      // Drawer is the side menu (Screen #10)
      drawer: const AppDrawer(),
      extendBody: true, // Body extends behind the floating bottom nav
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _buildBodyForIndex(_currentIndex),
        ),
      ),
      bottomNavigationBar: _PremiumBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HomeContent — The body visible when Home tab (index 0) is active
// ---------------------------------------------------------------------------
class _HomeContent extends StatelessWidget {
  final String greeting;
  const _HomeContent({required this.greeting});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    final bool isLoggedIn = auth.firebaseUser != null;
    final String fullName =
        auth.firebaseUser?.displayName ??
        auth.firebaseUser?.email?.split('@').first ??
        '';
    final String firstName =
        isLoggedIn ? (fullName.isNotEmpty ? fullName.split(' ').first : 'There') : 'Guest';

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
              child: _TopHeaderBar(
                greeting: greeting,
                firstName: firstName,
                isLoggedIn: isLoggedIn,
                profileImageUrl: auth.profileImageUrl,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          if (!isLoggedIn)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryAccent),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You are browsing as a Guest. Create an account to permanently save previews and purchase artwork.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Hero promotional card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _PromotionalHeroCard(onStartCreating: () {
                // "Start Creating" → show wall selection source
                _showWallSourceSheet(context);
              }),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Section label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Top row: Wall Selection + Select Artwork
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add_a_photo_outlined,
                      title: 'Wall Drop',
                      subtitle: 'Add a photo of your wall',
                      onTap: () => _showWallSourceSheet(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.image_outlined,
                      title: 'Art Hunt',
                      subtitle: 'Choose art from your gallery',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          // isFromCamera=false: user came from catalog,
                          // so "Add to Wall" will show the source dialog.
                          builder: (_) => const ArtHuntScreen(isFromCamera: false),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Bottom row: My Collection + AI Generate Art
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.collections_bookmark_outlined,
                      title: 'My Stash',
                      subtitle: 'View your saved artworks',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CollectionScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (auth.userRole == 'seller')
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.post_add_rounded,
                        title: 'Add Your Art',
                        subtitle: 'Upload new artwork',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SellerDashboard(openAddSheet: true),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.storefront_outlined,
                        title: 'Go Creator',
                        subtitle: 'Become a Seller',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(defaultToSeller: true),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),



          // Extra bottom padding so cards clear the floating nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // Shows a sheet to choose between Camera or Gallery for the wall photo
  void _showWallSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD7CCC8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      color: AppTheme.primaryAccent, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Wall Drop',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'How would you like to add your wall photo?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            const Divider(height: 1, indent: 24, endIndent: 24,
                color: Color(0xFFEFEBE9)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.camera_alt_rounded,
                    color: AppTheme.primaryAccent, size: 22),
              ),
              title: Text('Live AR Preview',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                      fontSize: 15)),
              subtitle: Text('Open camera and capture your wall',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted),
              onTap: () {
                Navigator.pop(ctx);
                _handleWallCapture(context, isCamera: true);
              },
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.photo_library_rounded,
                    color: AppTheme.primaryAccent, size: 22),
              ),
              title: Text('Choose from Gallery',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                      fontSize: 15)),
              subtitle: Text('Pick an existing photo from your device',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted),
              onTap: () {
                Navigator.pop(ctx);
                _handleWallCapture(context, isCamera: false);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Orchestrates the capture/pick process and navigates to Workspace
  Future<void> _handleWallCapture(BuildContext context, {required bool isCamera}) async {
    final workspaceCtrl = context.read<WorkspaceController>();
    
    if (isCamera) {
      workspaceCtrl.clearArtworkSelection();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CustomCameraScreen(originSource: 'wall_drop'),
        ),
      );
    } else {
      final success = await workspaceCtrl.pickWallFromGallery();
      if (!context.mounted) return;

      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            // isFromCamera=true: wall was already picked from gallery,
            // so "Add to Wall" skips the source dialog and goes straight to Workspace.
            builder: (_) => SelectArtworkScreen(isFromCamera: true),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access gallery. Please check permissions.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// _TopHeaderBar — Profile avatar, greeting, and notification bell
// ---------------------------------------------------------------------------
class _TopHeaderBar extends StatelessWidget {
  final String greeting;
  final String firstName;
  final bool isLoggedIn;
  final String? profileImageUrl;

  const _TopHeaderBar({
    required this.greeting,
    required this.firstName,
    this.isLoggedIn = true,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    void handleTap() {
      if (isLoggedIn) {
        Scaffold.of(context).openDrawer();
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile avatar — tapping opens the drawer
        GestureDetector(
          onTap: handleTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryAccent.withValues(alpha: 0.2),
                width: 1.5,
              ),
              image: profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profileImageUrl == null
                ? Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryAccent,
                    size: 26,
                  )
                : null,
          ),
        ),

        const SizedBox(width: 14),

        // Greeting and name
        Expanded(
          child: GestureDetector(
            onTap: handleTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 13, letterSpacing: 0.2),
                ),
                Text(
                  firstName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // Notification bell with red badge dot
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                shape: BoxShape.circle,
                boxShadow: AppTheme.premiumShadow,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.notifications_none_outlined,
                  color: AppTheme.textDark,
                  size: 22,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.backgroundBeige,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _PromotionalHeroCard — Dark hero banner with tagline and Start Creating CTA
// ---------------------------------------------------------------------------
class _PromotionalHeroCard extends StatefulWidget {
  final VoidCallback onStartCreating;
  const _PromotionalHeroCard({required this.onStartCreating});

  @override
  State<_PromotionalHeroCard> createState() => _PromotionalHeroCardState();
}

class _PromotionalHeroCardState extends State<_PromotionalHeroCard> {
  int _currentImageIndex = 0;
  late final PageController _pageController;
  final List<String> _images = [
    'assets/images/Home_banner.jpg',
    'assets/images/Home_banner2.jpg',
    'assets/images/Home_banner3.jpg',
    'assets/images/Home_banner4.jpg',
  ];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_currentImageIndex + 1) % _images.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 210),
      decoration: BoxDecoration(
        borderRadius: AppTheme.defaultRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38322B).withValues(alpha: 0.30),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppTheme.defaultRadius,
        child: Stack(
          children: [
            // ── Smooth PageView carousel ─────────────────────────────────────
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (index) =>
                    setState(() => _currentImageIndex = index),
                itemBuilder: (_, index) => Image.asset(
                  _images[index],
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.45),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),

            // ── Bottom gradient scrim for text legibility ─────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.50),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
            ),

            // ── Decorative glow circle (top-right) ────────────────────────────
            Positioned(
              top: -40, right: -40,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // ── Card content ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),

                  // Hero headline
                  const Text(
                    'Visualize your artwork before you place it.\nPreview artwork directly on your wall.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CTA button — glassmorphic style
                  GestureDetector(
                    onTap: widget.onStartCreating,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start Creating',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward,
                              color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Animated page indicator dots ──────────────────────────
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_images.length, (i) {
                      final bool active = i == _currentImageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// _QuickActionCard — Cards in the 2x2 Quick Actions grid
// ---------------------------------------------------------------------------
class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0), // subtle lift
        child: Material(
          color: AppTheme.surfaceWhite,
          borderRadius: AppTheme.defaultRadius,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppTheme.defaultRadius,
            splashColor: AppTheme.primaryAccent.withValues(alpha: 0.06),
            child: Container(
              constraints: const BoxConstraints(minHeight: 140),
              decoration: BoxDecoration(
                borderRadius: AppTheme.defaultRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isHovered ? 0.16 : 0.08),
                    blurRadius: _isHovered ? 24 : 14,
                    offset: Offset(0, _isHovered ? 10 : 6),
                  ),
                ],
                color: AppTheme.surfaceWhite,
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with tinted bg
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.brown[50],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: Colors.brown[800], size: 22),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.title,
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PremiumBottomNavBar — 5-tab custom navigation with animated indicator
// ---------------------------------------------------------------------------
class _PremiumBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PremiumBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(
        icon: Icons.collections_outlined,
        activeIcon: Icons.collections,
        label: 'Collection'),
    _NavItem(
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        label: 'Shop'),
    _NavItem(
        icon: Icons.photo_library_outlined,
        activeIcon: Icons.photo_library,
        label: 'Previews'),
    _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: AppTheme.textDark.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final bool isActive = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Active indicator line at top
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          width: isActive ? 24 : 0,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Nav icon with filled/outlined swap animation
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            key: ValueKey<bool>(isActive),
                            size: 22,
                            color: isActive
                                ? AppTheme.primaryAccent
                                : AppTheme.textMuted,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Label with animated weight/color
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isActive
                                ? AppTheme.primaryAccent
                                : AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ArtworkPreviewItem extends StatelessWidget {
  final String imagePath;
  const _ArtworkPreviewItem({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkspaceScreen(
              artworkAssetPath: imagePath,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

// Data holder for nav bar items
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

