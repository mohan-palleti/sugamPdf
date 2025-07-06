import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user_info_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pdf_merge_screen.dart';
import 'screens/image_to_pdf_screen.dart';
import 'screens/camera_to_pdf_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'screens/file_manager_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Utility',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/user-info': (context) => const UserInfoScreen(),
        '/home': (context) => const HomeScreen(),
        '/pdf-merge': (context) => const PdfMergeScreen(),
        '/image-to-pdf': (context) => const ImageToPdfScreen(),
        '/camera-to-pdf': (context) => const CameraToPdfScreen(),
        '/pdf-viewer': (context) => const PdfViewerScreen(),
        '/file-manager': (context) => const FileManagerScreen(),
      },
    );
  }
}

// ...existing code...
