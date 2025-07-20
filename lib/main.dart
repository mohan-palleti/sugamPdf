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

  static final ThemeData globalTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: Color(0xFF2E6F40),     // Dark green
      secondary: Color(0xFF68BA7F),    // Medium green
      surface: Color(0xFFCFFFDC),      // Light mint
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF2E6F40),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF68BA7F),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFFCFFFDC),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Utility',
      theme: globalTheme,
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
