import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:signalai/view/home_screen.dart';
import 'package:signalai/view/onboarding.dart';
import 'package:uuid/uuid.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(MyApp(seenOnboarding: seenOnboarding));

}

class MyApp extends StatelessWidget {

  const MyApp({Key? key, required this.seenOnboarding}) : super(key: key);

  final bool seenOnboarding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Chart',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: seenOnboarding ? const HomeScreen() : const OnboardingScreen(),
    );
  }

}
