import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'LoginForm.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  sqflite_ffi.sqfliteFfiInit();
  dotenv.load(fileName: '.env');

  WidgetsFlutterBinding.ensureInitialized();

  runApp(Home());
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localeResolutionCallback: (locale, supportedLocales) {
        final deviceLanguage = 'pt';
        return Locale(deviceLanguage);
      },
      supportedLocales: [
        const Locale('en'),
        const Locale('pt'),
        const Locale('es'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      title: 'Pet Affection',
      theme: ThemeData(
        primaryColor: const Color.fromRGBO(188, 170, 164, 1),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.brown),
          ),
        ),
      ),
      home: LoginForm(),
    );
  }
}
