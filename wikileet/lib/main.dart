// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/providers/user_provider.dart';
import 'package:wikileet/viewmodels/family_viewmodel.dart';
import 'package:wikileet/services/auth_service.dart';
import 'firebase_options.dart';
import 'wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Instantiate necessary services and providers
  final authService = AuthService();
  final userProvider = UserProvider();

  // Set initial userId if a user is already authenticated
  final currentUser = authService.getCurrentUser();
  if (currentUser != null) {
    userProvider.setUserId(currentUser.uid);
  }

  // Listen for auth changes and update UserProvider
  authService.listenToAuthChanges(userProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => userProvider),
        ChangeNotifierProvider(create: (_) => FamilyViewModel()),
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
      ),
      navigatorKey: navigatorKey,
      home: Wrapper(),
    );
  }
}
