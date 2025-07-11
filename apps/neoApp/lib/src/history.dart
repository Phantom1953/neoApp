import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'coin_provider.dart';


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final coins = Provider.of<CoinProvider>(context).coins;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF38124B),
        leadingWidth: 400,
        leading: Row(
          children: [
            Image.asset('assets/images/Coin1.png'),
            Padding(
              padding: const EdgeInsets.all(5),
              child: Text(
                coins.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          Align(
            alignment: Alignment.centerLeft,
            child: Image.asset('assets/images/logo2.png'),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFB90156),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                'Наша компания',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),


              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0), // Задайте радиус закругления
                  child: Image.asset(
                    'assets/images/NeoFlex.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),


              _buildInfoBlock(
                title: 'Neoflex',
                content: 'Neoflex разрабатывает ИТ-платформы для цифровой '
                    'трансформации бизнеса, помогая клиентам достигать '
                    'конкурентных преимуществ. Компания специализируется на заказной '
                    'разработке программного обеспечения и внедрении сложных '
                    'информационных систем, работая с ведущими компаниями и '
                    'банками России.',
              ),
              const SizedBox(height: 16),

              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.asset(
                    'assets/images/People.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildInfoBlock(
                title: 'NeoEdu',
                content: 'Neoflex предлагает пройти обучение в своем учебном центре по '
                    'различным направлениям в сфере информационных технологий. Компания'
                    'предоставляем качественные образовательные программы, '
                    'которые помогут вам развить необходимые навыки и знания. По '
                    'окончании обучения у вас будет возможность трудоустройства. '
                    'Начни свою карьеру в динамично развивающейся области!',
              ),
              const SizedBox(height: 16),

              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.asset(
                    'assets/images/Static.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildInfoBlock(
                title: 'Миссия',
                content: 'Мы способствуем развитию финансового сектора российской '
                    'экономики, содействуя нашим клиентам в совершенствовании '
                    'технологий банковской и финансовой деятельности за счет внедрения '
                    'инновационных IT-решений. Присоединяйся и стань частью будущего '
                    'цифровых технологий!',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, '/history'),
    );
  }
  Widget _buildInfoBlock({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF27F39),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
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
        borderRadius: BorderRadius.circular(16),
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