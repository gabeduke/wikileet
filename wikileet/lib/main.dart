// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/providers/user_provider.dart';
import 'package:wikileet/providers/family_group_provider.dart';
import 'package:wikileet/providers/gift_provider.dart';
import 'package:wikileet/viewmodels/family_viewmodel.dart';
import 'package:wikileet/services/auth_service.dart';
import 'firebase_options.dart';
import 'wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('App starting...');
  
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('Firebase initialized successfully');
    runApp(const AppRoot());
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Show error screen if Firebase fails to initialize
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing app: $e'),
        ),
      ),
    ));
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _authService = AuthService();
  final _userProvider = UserProvider();
  final _familyViewModel = FamilyViewModel();
  final _familyGroupProvider = FamilyGroupProvider();
  final _giftProvider = GiftProvider();

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  void _initializeProviders() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      print('Auth state changed - user: ${user?.uid}');
      if (user != null) {
        _userProvider.setUserId(user.uid);
        _familyGroupProvider.initializeStream(user.uid);
        _familyViewModel.getUserFamilyGroup(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Building AppRoot');

    return MultiProvider(
      providers: [
        Provider.value(value: _authService),
        ChangeNotifierProvider.value(value: _userProvider),
        ChangeNotifierProvider.value(value: _familyViewModel),
        ChangeNotifierProvider.value(value: _familyGroupProvider),
        ChangeNotifierProvider.value(value: _giftProvider),
      ],
      child: MaterialApp(
        title: 'Gift List App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        navigatorKey: navigatorKey,
        home: const Wrapper(),
      ),
    );
  }
}
