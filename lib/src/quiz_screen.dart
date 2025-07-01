import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'coin_provider.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;
  final String quizName;
  final String category;

  const QuizScreen({
    super.key,
    required this.quizId,
    required this.quizName,
    required this.category,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Question> questions = [];
  int currentQuestionIndex = 0;
  int correctAnswersCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final doc = await _firestore.collection('quizzes').doc(widget.quizId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final questionsData = data['questions'] as List<dynamic>? ?? [];

        setState(() {
          questions = questionsData.map((q) {
            return Question(
              q['questionText'],
              List<String>.from(q['answers']),
              correctAnswerIndex: q['correctAnswerIndex'],
            );
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void nextQuestion(int selectedAnswerIndex) {
    final coinProvider = Provider.of<CoinProvider>(context, listen: false);

    if (questions[currentQuestionIndex].correctAnswerIndex == selectedAnswerIndex) {
      correctAnswersCount++;
      coinProvider.addCoins(10);
    }

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {

      coinProvider.setBestScore(widget.category, correctAnswersCount);

      // Показать сообщение о завершении квеста
      showDialog(
        context: context,
        builder: (BuildContext context) {
          String animationPath;


          if (correctAnswersCount >= (questions.length * 0.4)) {
            animationPath = 'assets/animation/fireworks.json';
          } else {
            animationPath = 'assets/animation/fail.json';
          }
          return AlertDialog(
            title: Text(correctAnswersCount >= (questions.length * 0.4) ? "Поздравляю!" : "Постарайся еще!"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Вы завершили тест!"),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(text: "Вы набрали: ", style: TextStyle(color: Colors.black)),
                      TextSpan(text: "$correctAnswersCount", style: const TextStyle(color: Colors.black)),
                      const TextSpan(text: " из ", style: TextStyle(color: Colors.black)),
                      TextSpan(text: "${questions.length}", style: const TextStyle(color: Colors.black)),
                      const TextSpan(text: " баллов и заработали ", style: TextStyle(color: Colors.black)),
                      TextSpan(text: "${correctAnswersCount*10}", style: const TextStyle(color: Colors.black)),
                      const TextSpan(text: " монет.", style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                Container(
                  child: Lottie.asset(animationPath),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacementNamed(context, '/quest');
                },
                child: const Text("На главную"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFB90156),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Загрузка вопросов...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFB90156),
        body: Center(
          child: Text(
            'В этом тесте пока нет вопросов',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF38124B),
        title: Text(widget.quizName),
        titleTextStyle: const TextStyle(color: Color(0xFFF27F39), fontSize: 20),
      ),
      backgroundColor: const Color(0xFFB90156),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              questions[currentQuestionIndex].questionText,
              style: const TextStyle(fontSize: 24, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                itemCount: questions[currentQuestionIndex].answers.length,
                itemBuilder: (context, index) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF27F39),
                      foregroundColor: const Color(0xFF38124B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                    onPressed: () => nextQuestion(index),
                    child: Text(
                      questions[currentQuestionIndex].answers[index],
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      maxLines: 4,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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

class Question {
  final String questionText;
  final List<String> answers;
  final int correctAnswerIndex;

  Question(this.questionText, this.answers, {required this.correctAnswerIndex});
}