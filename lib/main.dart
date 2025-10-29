import 'package:flutter/material.dart';
import 'package:miocardio_app/repos/cardio_repository.dart';
import 'package:provider/provider.dart';
import 'telas/tela_principal.dart';

void main() {
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (context) => cardioRepository()),
    ],
    child: MyApp(),)
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MioCardio',
      theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Color(0xff0C0C0C),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xff0C0C0C),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Color(0xff0C0C0C),
          )
      ),
      home: TelaPrincipal(),
    );
  }
}

