import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/workspace_controller.dart';
import 'controllers/collection_controller.dart';
import 'controllers/previews_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/shop_controller.dart';
import 'controllers/seller_controller.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'utils/app_theme.dart';
import 'views/splash_screen.dart';
import 'views/home_screen.dart';
import 'views/seller_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';

late List<CameraDescription> globalCameras;

// ---------------------------------------------------------------------------
// ArtSpace Preview — main.dart
// ---------------------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    globalCameras = await availableCameras();
  } catch (e) {
    debugPrint("Camera initialization failed: $e");
    globalCameras = [];
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization bypassed/failed: $e");
  }

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surfaceWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ArtSpaceApp());
}

class ArtSpaceApp extends StatelessWidget {
  const ArtSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- Singleton Services ---
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<StorageService>(create: (_) => StorageService()),

        // --- Auth Controller ---
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(),
          lazy: false,
        ),

        // --- Workspace Controller ---
        ChangeNotifierProxyProvider2<FirestoreService, StorageService,
            WorkspaceController>(
          create: (ctx) => WorkspaceController(
            firestore: ctx.read<FirestoreService>(),
            storage: ctx.read<StorageService>(),
          ),
          update: (_, firestore, storage, previous) =>
              previous ?? WorkspaceController(firestore: firestore, storage: storage),
        ),

        // --- Collection Controller ---
        ChangeNotifierProxyProvider2<FirestoreService, StorageService,
            CollectionController>(
          create: (ctx) => CollectionController(
            firestore: ctx.read<FirestoreService>(),
            storage: ctx.read<StorageService>(),
          ),
          update: (_, firestore, storage, previous) =>
              previous ?? CollectionController(firestore: firestore, storage: storage),
        ),

        // --- Previews Controller ---
        ChangeNotifierProxyProvider<FirestoreService, PreviewsController>(
          create: (ctx) =>
              PreviewsController(firestore: ctx.read<FirestoreService>()),
          update: (_, firestore, previous) =>
              previous ?? PreviewsController(firestore: firestore),
        ),

        // --- Settings Controller ---
        ChangeNotifierProxyProvider<FirestoreService, SettingsController>(
          create: (ctx) =>
              SettingsController(firestore: ctx.read<FirestoreService>()),
          update: (_, firestore, previous) =>
              previous ?? SettingsController(firestore: firestore),
        ),

        // --- Shop Controller (public marketplace) ---
        ChangeNotifierProxyProvider<FirestoreService, ShopController>(
          create: (ctx) {
            final controller = ShopController(
              firestore: ctx.read<FirestoreService>(),
            );
            controller.startListening();
            return controller;
          },
          update: (_, firestore, previous) {
            if (previous == null) {
              final controller = ShopController(firestore: firestore);
              controller.startListening();
              return controller;
            }
            return previous;
          },
        ),

        // --- Seller Controller ---
        ChangeNotifierProxyProvider2<FirestoreService, StorageService,
            SellerController>(
          create: (ctx) => SellerController(
            firestore: ctx.read<FirestoreService>(),
            storage: ctx.read<StorageService>(),
          ),
          update: (_, firestore, storage, previous) =>
              previous ?? SellerController(firestore: firestore, storage: storage),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, child) {
          AppTheme.isDarkMode = settings.theme == 'Dark';
          return MaterialApp(
            title: 'ArtSpace Preview',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: const RootRouter(),
          );
        },
      ),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF6F3EF),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF4A3424)),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Consumer<AuthController>(
            builder: (context, auth, _) {
              if (auth.userRole == 'seller') {
                return const SellerDashboard();
              }
              return const HomeScreen();
            },
          );
        }

        return const SplashScreen();
      },
    );
  }
}
