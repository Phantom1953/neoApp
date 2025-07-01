import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'history.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedAvatar;
  final List<String> _avatars = [
    'assets/images/LoveBot.png',
    'assets/images/SmileBot.png',
    'assets/images/NeoBot.png',
    'assets/images/HardBot.png',
    'assets/images/PerfBot.png',
    'assets/images/neon.png',
  ];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAvatar == null) {
      setState(() {
        _errorMessage = 'Выберите аватар';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'username': _usernameController.text.trim(),
        'avatar': _selectedAvatar,
        'coins': 1500,
        'bestScoreFlutter': 0,
        'bestScoreJava': 0,
        'bestScoreSQL': 0,
        'bestScoreNeoflex': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HistoryScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectAvatar(String avatar) {
    setState(() {
      _selectedAvatar = avatar;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB90156),
      appBar: AppBar(
        backgroundColor: const Color(0xFF38124B),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF150F1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Регистрация',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 20),


                  const Text(
                    'Выберите аватар:',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _avatars.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _selectAvatar(_avatars[index]),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedAvatar == _avatars[index]
                                    ? const Color(0xFFF27F39)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Image.asset(_avatars[index]),
                          ),
                        );
                      },
                    ),
                  ),

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Имя пользователя',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите имя пользователя';
                      }
                      if (value.length < 3) {
                        return 'Имя должно быть не менее 3 символов';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                        return 'Используйте только английские буквы и цифры';
                      }
                      return null;
                    },
                  ),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Введите корректный email';
                      }
                      return null;
                    },
                  ),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      if (value.length < 8) {
                        return 'Пароль должен быть не менее 8 символов';
                      }
                      return null;
                    },
                  ),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Подтвердите пароль',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Подтвердите пароль';
                      }
                      if (value != _passwordController.text) {
                        return 'Пароли не совпадают';
                      }
                      return null;
                    },
                  ),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF27F39),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Зарегистрироваться'),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Уже есть аккаунт? Войти',
                      style: TextStyle(color: Color(0xFFF27F39)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}