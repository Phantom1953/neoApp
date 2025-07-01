import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'coin_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _availableImages = [
    'assets/images/LoveBot.png',
    'assets/images/SmileBot.png',
    'assets/images/NeoBot.png',
    'assets/images/HardBot.png',
    'assets/images/PerfBot.png',
    'assets/images/neon.png',
  ];

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _coinsController = TextEditingController();
  bool _isEditingUsername = false;
  bool _isEditingCoins = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _coinsController.dispose();
    super.dispose();
  }

  void _showImageSelectionDialog(BuildContext context) {
    final coinProvider = Provider.of<CoinProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF150F1E),
          title: const Text(
            'Выберите аватар',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _availableImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    coinProvider.setSelectedImage(_availableImages[index]);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF27F39),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        _availableImages[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _toggleUsernameEdit(CoinProvider coinProvider) {
    if (_isEditingUsername) {
      final newUsername = _usernameController.text.trim();
      if (newUsername.isNotEmpty && newUsername.length <= 10) {
        coinProvider.setUsername(newUsername);
        setState(() {
          _isEditingUsername = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ник должен быть от 1 до 12 символов'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      _usernameController.text = coinProvider.username;
      setState(() {
        _isEditingUsername = true;
      });
    }
  }

  void _toggleCoinsEdit(CoinProvider coinProvider) {
    if (_isEditingCoins) {
      final newCoins = int.tryParse(_coinsController.text) ?? coinProvider.coins;
      coinProvider.addCoins(newCoins - coinProvider.coins);
    } else {
      _coinsController.text = coinProvider.coins.toString();
    }
    setState(() {
      _isEditingCoins = !_isEditingCoins;
    });
  }

  void _showAdminSettings(BuildContext context) {
    final coinProvider = Provider.of<CoinProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Настройки администратора'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Режим администратора'),
                value: coinProvider.isAdmin,
                onChanged: (value) {
                  coinProvider.toggleAdminMode();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Назад'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final coinProvider = Provider.of<CoinProvider>(context, listen: false);
    await coinProvider.signOut();

    await Future.delayed(const Duration(milliseconds: 300));
    Navigator.pushReplacementNamed(context, '/auth');
  }

  Future<void> _clearPurchasedItems(CoinProvider coinProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить список покупок?'),
        content: const Text('Вы уверены, что хотите удалить все купленные товары?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await coinProvider.clearPurchasedItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Список покупок очищен')),
        );
      }
    }
  }

  Widget _buildPurchasedItemCard(Map<String, dynamic> item, int index) {
    final imageBytes = base64Decode(item['image']);
    final imageProvider = MemoryImage(imageBytes);

    return Card(
      color: const Color(0xFF150F1E),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Куплено: 1',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${item['price']} монет',
              style: const TextStyle(
                color: Color(0xFFF27F39),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinProvider = Provider.of<CoinProvider>(context);

    if (coinProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF38124B),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showAdminSettings(context),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => _signOut(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/images/logo2.png', width: 100),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFB90156),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showImageSelectionDialog(context),
              child: Container(
                width: 180,
                height: 180,
                margin: const EdgeInsets.only(top: 40),
                decoration: BoxDecoration(
                  color: const Color(0xFF150F1E),
                  borderRadius: BorderRadius.circular(90),
                  border: Border.all(
                    color: const Color(0xFFF27F39),
                    width: 3,
                  ),
                  image: coinProvider.selectedImagePath != null
                      ? DecorationImage(
                    image: AssetImage(coinProvider.selectedImagePath!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: coinProvider.selectedImagePath == null
                    ? const Icon(
                  Icons.add_a_photo,
                  size: 60,
                  color: Color(0xFFF27F39),
                )
                    : null,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _isEditingUsername
                      ? SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _usernameController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF27F39),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide.none,
                        ),
                        counterText: '',
                        hintText: 'Введите ник',
                        hintStyle: TextStyle(color: Colors.white70),
                      ),
                      maxLength: 12,
                      onSubmitted: (value) => _toggleUsernameEdit(coinProvider),
                    ),
                  )
                      : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF27F39),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      coinProvider.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isEditingUsername ? Icons.check : Icons.edit,
                          color: Colors.white,
                        ),
                        onPressed: () => _toggleUsernameEdit(coinProvider),
                      ),
                      Stack(
                        children: [
                          Image.asset(
                            'assets/images/Coin2.png',
                            width: 35,
                            height: 35,
                          ),
                          if (coinProvider.isAdmin)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => _toggleCoinsEdit(coinProvider),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isEditingCoins ? Icons.check : Icons.edit,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      _isEditingCoins
                          ? SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _coinsController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF27F39),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      )
                          : Text(
                        coinProvider.coins.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              margin: const EdgeInsets.only(top: 20, bottom: 20),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF27F39),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  const Text(
                    'Мои покупки',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (coinProvider.purchasedItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Вы еще не совершили покупок',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  else
                    Column(
                      children: coinProvider.purchasedItems
                          .asMap()
                          .entries
                          .map((entry) => _buildPurchasedItemCard(entry.value, entry.key))
                          .toList(),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _clearPurchasedItems(coinProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Очистить список',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, '/home'),
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
        icon: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}