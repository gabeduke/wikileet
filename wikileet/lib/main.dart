// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/providers/user_provider.dart';
import 'package:wikileet/services/auth_service.dart'; // Import AuthService
import 'package:wikileet/services/navigation_service.dart';
import 'firebase_options.dart';
import 'wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Instantiate AuthService
  final authService = AuthService();
  final navigationService = NavigationService();

  // Instantiate UserProvider
  final userProvider = UserProvider();

  // Check for an existing authenticated user and set userId
  final currentUser = authService.getCurrentUser();
  if (currentUser != null) {
    userProvider.setUserId(currentUser.uid);
  }

  // Start listening for auth state changes
  authService.listenToAuthChanges(userProvider);
  navigationService.listenToAuthChanges(userProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => userProvider),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gift List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Define text themes, button themes, etc.
      ),
      home: Wrapper(),
      navigatorKey: navigatorKey,
    );
  }
}
