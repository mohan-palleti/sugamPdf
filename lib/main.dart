import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user_info_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pdf_merge_screen.dart';
import 'screens/image_to_pdf_screen.dart';
import 'screens/camera_to_pdf_screen.dart'; 
import 'screens/pdf_viewer_screen.dart';
import 'screens/page_operations_screen.dart';
import 'screens/pdf_compress_screen.dart';
import 'screens/pdf_split_screen.dart';
import 'screens/file_manager_screen.dart';

// BLoCs
import 'blocs/pdf/pdf_bloc.dart';
import 'blocs/file/file_bloc.dart';

// Services
import 'services/pdf_service.dart';
import 'theme/app_theme_extension.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static ThemeData _buildTheme() {
    const primary = Color(0xFF2E6F40);
    const secondary = Color(0xFF68BA7F);
    const surface = Color(0xFFCFFFDC);
    const scheme = ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
    );
    final ext = AppStyles.create(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ext.primaryButton),
      snackBarTheme: ext.snackBarTheme,
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      extensions: [ext],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PdfBloc(
            pdfService: PdfService(),
          ),
        ),
        BlocProvider(
          create: (context) => FileBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'PDF Utility',
  theme: _buildTheme(),
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
          '/page_ops': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            final path = args?['pdfPath'] as String?;
            if (path == null) {
              return const Scaffold(body: Center(child: Text('No PDF path provided')));
            }
            return PageOperationsScreen(pdfPath: path);
          },
          '/compress': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            final path = args?['pdfPath'] as String?;
            if (path == null) {
              return const Scaffold(body: Center(child: Text('No PDF path provided')));
            }
            return PdfCompressScreen(pdfPath: path);
          },
          '/split': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            final path = args?['pdfPath'] as String?;
            if (path == null) {
              return const Scaffold(body: Center(child: Text('No PDF path provided')));
            }
            return PdfSplitScreen(pdfPath: path);
          },
        },
      ),
    );
  }
}

// ...existing code...
