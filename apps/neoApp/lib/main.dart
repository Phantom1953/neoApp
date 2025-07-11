import 'package:flutter/material.dart';
import 'package:flutter_app/src/auth_screen.dart';
import 'package:flutter_app/src/login_screen.dart';
import 'package:flutter_app/src/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/home.dart';
import 'src/history.dart';
import 'src/quest.dart';
import 'src/store.dart';
import 'src/quiz_screen.dart';
import 'src/coin_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CoinProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Мое приложение',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/history': (context) => const HistoryScreen(),
        '/quest': (context) => const QuestScreen(),
        '/store': (context) => const StoreScreen(),
        '/quiz': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return QuizScreen(
            quizId: args['quizId'],
            quizName: args['quizName'],
            category: args['category'],
          );
        },
      },
    );
  }
}