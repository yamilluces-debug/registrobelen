import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/inicio/inicio_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RegistroBelenApp());
}

class RegistroBelenApp extends StatelessWidget {
  const RegistroBelenApp({super.key});

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF168A55);
    const fondo = Color(0xFFF6FAF8);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Registro Belén',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: verde,
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: fondo,

        appBarTheme: const AppBarTheme(
          backgroundColor: verde,
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),

        inputDecorationTheme:
            InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: verde,
              width: 2,
            ),
          ),

          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),

        elevatedButtonTheme:
            ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: verde,
            foregroundColor: Colors.white,
            minimumSize:
                const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),
        ),

        filledButtonTheme:
            FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: verde,
            foregroundColor: Colors.white,
            minimumSize:
                const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),
        ),

        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(
          backgroundColor: verde,
          foregroundColor: Colors.white,
        ),

       navigationBarTheme:
    NavigationBarThemeData(
  indicatorColor:
      verde.withValues(alpha: 0.15),
),

        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
        ),
      ),

      home: const InicioScreen(),
    );
  }
}