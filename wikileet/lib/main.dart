// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final authService = AuthService();
        final userProvider = UserProvider();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // If there’s an authenticated user, set their userId
          final currentUser = authService.getCurrentUser();
          if (currentUser != null) {
            userProvider.setUserId(currentUser.uid);
          }
        }

        authService.listenToAuthChanges(userProvider);

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => userProvider),
            ChangeNotifierProvider(create: (_) => FamilyViewModel()),
          ],
          child: MyApp(),
        );
      },
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
