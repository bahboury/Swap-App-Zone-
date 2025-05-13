// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:swap_app/core/injection_container.dart' as di;
import 'package:swap_app/firebase_options.dart';
import 'package:swap_app/app.dart'; // Import your new app.dart file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Dependency Injection
  await di.init();

  runApp(const MyApp()); // Run your new MyApp widget
}
