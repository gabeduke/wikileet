// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/providers/user_provider.dart';
import 'firebase_options.dart';
import 'wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(); // Add this line

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
      MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProvider()),
          ],
      child: MyApp()
      ));
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
