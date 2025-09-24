import 'package:crazzy_ai_tool/code_gen_screen.dart';
import 'package:crazzy_ai_tool/home_screen.dart';
import 'package:crazzy_ai_tool/login_screen.dart';
import 'package:crazzy_ai_tool/update_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Supabase.initialize(
  //   url: '',
  //   anonKey:
  //       '',
  // );
  runApp(
    const CrazzyDevApp(), // Wrap your app
  );
}

class CrazzyDevApp extends StatelessWidget {
  const CrazzyDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crazzy',
      theme: ThemeData(
        primaryColor: const Color(0xFFFFA000), // Orange accent
        scaffoldBackgroundColor: const Color(0xFF1C2526), // Dark background
        cardColor: const Color(0xFF2C3E50), // Card background
        textTheme: TextTheme(
          headlineMedium: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: GoogleFonts.roboto(color: Colors.white70),
          labelLarge: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFA000), // Orange buttons
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        cardTheme: const CardTheme(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF34495E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.white54),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/code-gen': (context) => const CodeGenScreen(),
        '/update': (context) => const UpdateScreen(),
      },
    );
  }
}

// Widget to handle authentication state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Check initial session
    _checkSession();
    // Listen for auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {
        _isLoggedIn = Supabase.instance.client.auth.currentSession != null;
      });
    });
  }

  Future<void> _checkSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() {
      _isLoggedIn = session != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
