import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'coin_provider.dart';
import 'quiz_screen.dart';

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coinProvider = Provider.of<CoinProvider>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF38124B),
        automaticallyImplyLeading: false,
        leadingWidth: 120,
        title: const Text('Выберите категорию'),
        titleTextStyle: const TextStyle(color: Color(0xFFF27F39), fontSize: 20),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Image.asset('assets/images/Coin1.png', width: 24, height: 24),
                const SizedBox(width: 8),
                Text(
                  coinProvider.coins.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFB90156),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCategoryButton(context, 'Flutter', 'assets/images/flutter.png'),
            _buildCategoryButton(context, 'Java', 'assets/images/java.png'),
            _buildCategoryButton(context, 'SQL', 'assets/images/data.png'),
            _buildCategoryButton(context, 'Neoflex', 'assets/images/history.png'),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, '/quest'),
    );
  }

  Widget _buildCategoryButton(BuildContext context, String category, String imagePath) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizListScreen(category: category),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF38124B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF27F39),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BottomAppBar _buildBottomNavBar(BuildContext context, String activeRoute) {
    return BottomAppBar(
      height: 70,
      color: const Color(0xFF38124B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(context, Icons.history_edu_sharp, '/history', activeRoute == '/history'),
          _buildNavButton(context, Icons.question_mark_outlined, '/quest', activeRoute == '/quest'),
          _buildNavButton(context, Icons.shopping_cart, '/store', activeRoute == '/store'),
          _buildNavButton(context, Icons.account_box_outlined, '/home', activeRoute == '/home'),
        ],
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, IconData icon, String route, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8),
        color: isActive ? const Color(0xFFF27F39) : const Color(0xFF38124B),
      ),
      child: IconButton(
        onPressed: () {
          if (!isActive) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class QuizListScreen extends StatefulWidget {
  final String category;

  const QuizListScreen({super.key, required this.category});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _quizNameController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _answerControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctAnswerIndex = 0;
  String? _currentEditingQuizId;

  @override
  void dispose() {
    _quizNameController.dispose();
    _questionController.dispose();
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _addNewQuiz() async {
    if (_quizNameController.text.isEmpty) return;

    try {
      final newQuizRef = await _firestore.collection('quizzes').add({
        'category': widget.category,
        'name': _quizNameController.text,
        'questions': [],
        'createdAt': FieldValue.serverTimestamp(),
      });


      setState(() {
        _currentEditingQuizId = newQuizRef.id;
      });

      _quizNameController.clear();
      Navigator.of(context).pop();
      _showAddQuestionDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при создании теста: $e')),
      );
    }
  }

  Future<void> _addQuestionToQuiz() async {
    if (_questionController.text.isEmpty ||
        _answerControllers.any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    try {
      final newQuestion = {
        'questionText': _questionController.text,
        'answers': _answerControllers.map((c) => c.text).toList(),
        'correctAnswerIndex': _correctAnswerIndex,
      };

      await _firestore.collection('quizzes').doc(_currentEditingQuizId).update({
        'questions': FieldValue.arrayUnion([newQuestion]),
      });


      _questionController.clear();
      for (var controller in _answerControllers) {
        controller.clear();
      }
      _correctAnswerIndex = 0;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вопрос добавлен!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении вопроса: $e')),
      );
    }
  }

  void _showAddQuizDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Создать новый тест'),
          content: TextField(
            controller: _quizNameController,
            decoration: const InputDecoration(
              labelText: 'Название теста',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: _addNewQuiz,
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  void _showAddQuestionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Добавить вопрос'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _questionController,
                      decoration: const InputDecoration(
                        labelText: 'Текст вопроса',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._answerControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: 'Ответ ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            Radio<int>(
                              value: index,
                              groupValue: _correctAnswerIndex,
                              onChanged: (value) {
                                setState(() {
                                  _correctAnswerIndex = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () async {
                    await _addQuestionToQuiz();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQuizOptions(BuildContext context, String quizId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Опции теста'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Добавить вопрос'),
                onTap: () {
                  Navigator.of(context).pop();
                  _currentEditingQuizId = quizId;
                  _showAddQuestionDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Удалить тест'),
                onTap: () async {
                  try {
                    await _firestore.collection('quizzes').doc(quizId).delete();
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка при удалении: $e')),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinProvider = Provider.of<CoinProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF38124B),
        leadingWidth: 120,
        title: Text('Тесты: ${widget.category}'),
        titleTextStyle: const TextStyle(color: Color(0xFFF27F39), fontSize: 20),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Image.asset('assets/images/Coin1.png', width: 24, height: 24),
                const SizedBox(width: 8),
                Text(
                  coinProvider.coins.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFB90156),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('quizzes')
            .where('category', isEqualTo: widget.category)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Нет доступных тестов',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }


          final docs = snapshot.data!.docs;
          docs.sort((a, b) =>
              (a['createdAt'] ?? Timestamp(0, 0))
                  .compareTo(b['createdAt'] ?? Timestamp(0, 0)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final quiz = docs[index];
              return Card(
                color: const Color(0xFF38124B),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    quiz['name'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Вопросов: ${(quiz['questions'] as List).length}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (coinProvider.isAdmin)
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () => _showQuizOptions(context, quiz.id),
                        ),
                      const Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/quiz',
                      arguments: {
                        'quizId': quiz.id,
                        'quizName': quiz['name'],
                        'category': widget.category,
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: coinProvider.isAdmin
          ? FloatingActionButton(
        onPressed: _showAddQuizDialog,
        backgroundColor: const Color(0xFFF27F39),
        child: const Icon(Icons.add),
      )
          : null,
      bottomNavigationBar: _buildBottomNavBar(context, '/quest'),
    );
  }

  BottomAppBar _buildBottomNavBar(BuildContext context, String activeRoute) {
    return BottomAppBar(
      height: 70,
      color: const Color(0xFF38124B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(Icons.history_edu_sharp, '/history', activeRoute == '/history'),
          _buildNavButton(Icons.question_mark_outlined, '/quest', activeRoute == '/quest'),
          _buildNavButton(Icons.shopping_cart, '/store', activeRoute == '/store'),
          _buildNavButton(Icons.account_box_outlined, '/home', activeRoute == '/home'),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String route, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8),
        color: isActive ? const Color(0xFFF27F39) : const Color(0xFF38124B),
      ),
      child: IconButton(
        onPressed: () {
          if (!isActive) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}