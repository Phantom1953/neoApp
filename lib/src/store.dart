import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'coin_provider.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _buyProduct(DocumentSnapshot product, CoinProvider coinProvider) async {
    final price = product['price'] as int;

    if (coinProvider.spendCoins(price)) {
      coinProvider.addPurchasedItem({
        'name': product['name'],
        'price': product['price'],
        'description': product['description'],
        'image': product['image'],
        'purchasedAt': DateTime.now().toString(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Товар "${product['name']}" куплен!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Недостаточно монет'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addProduct(CoinProvider coinProvider) async {
    final name = _nameController.text.trim();
    final description = _descController.text.trim();


    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Название и описание не могут быть пустыми'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (name.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Название должно быть не более 10 символов'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (description.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Описание должно быть не более 20 символов'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final price = int.tryParse(_priceController.text) ?? 0;

    try {
      await coinProvider.addProduct(
        name: name,
        price: price,
        description: description,
        image: image,
      );

      _nameController.clear();
      _priceController.clear();
      _descController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Товар успешно добавлен'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при добавлении товара: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddProductDialog(CoinProvider coinProvider) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить товар'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название (макс. 10 символов)',
                  ),
                  maxLength: 10,
                  buildCounter: (BuildContext context, {int? currentLength, int? maxLength, bool? isFocused}) => null,
                ),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Цена'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Описание (макс. 20 символов)',
                  ),
                  maxLength: 20,
                  buildCounter: (BuildContext context, {int? currentLength, int? maxLength, bool? isFocused}) => null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _addProduct(coinProvider);
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditProductDialog(
      CoinProvider coinProvider, DocumentSnapshot product) async {
    _nameController.text = product['name'];
    _priceController.text = product['price'].toString();
    _descController.text = product['description'];

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать товар'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название (макс. 10 символов)',
                  ),
                  maxLength: 10,
                  buildCounter: (BuildContext context, {int? currentLength, int? maxLength, bool? isFocused}) => null,
                ),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Цена'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Описание (макс. 20 символов)',
                  ),
                  maxLength: 20,
                  buildCounter: (BuildContext context, {int? currentLength, int? maxLength, bool? isFocused}) => null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final description = _descController.text.trim();


                if (name.isEmpty || description.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Название и описание не могут быть пустыми'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (name.length > 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Название должно быть не более 10 символов'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (description.length > 20) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Описание должно быть не более 20 символов'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                final price = int.tryParse(_priceController.text) ?? 0;
                await coinProvider.updateProduct(
                  productId: product.id,
                  name: name,
                  price: price,
                  description: description,
                );
                _nameController.clear();
                _priceController.clear();
                _descController.clear();
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinProvider = Provider.of<CoinProvider>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF38124B),
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset(
            'assets/images/logo2.png',
            height: 40,
          ),
        ),
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
      floatingActionButton: coinProvider.isAdmin
          ? FloatingActionButton(
        onPressed: () => _showAddProductDialog(coinProvider),
        child: const Icon(Icons.add),
      )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Нет товаров'));
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) => _buildProductCard(
                products[index], coinProvider),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(context, '/store'),
    );
  }

  Widget _buildProductCard(DocumentSnapshot product, CoinProvider coinProvider) {
    final imageBytes = base64Decode(product['image']);
    final imageProvider = MemoryImage(imageBytes);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: const Color(0xFF150F1E),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF27F39),
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              product['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              product['description'],
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            Text(
              '${product['price']} монет',
              style: const TextStyle(
                color: Color(0xFFF27F39),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),

            Container(
              height: 36,
              child: coinProvider.isAdmin
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: const Color(0xFFF27F39),
                      onPressed: () => _showEditProductDialog(coinProvider, product),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: const Color(0xFFF27F39),
                      onPressed: () => coinProvider.deleteProduct(product.id),
                    ),
                  ),
                ],
              )
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF27F39),
                  minimumSize: const Size(double.infinity, 36),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => _buyProduct(product, coinProvider),
                child: const Icon(Icons.add_shopping_cart, size: 20),
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
        borderRadius: BorderRadius.circular(16),
        color: isActive ? const Color(0xFFF27F39) : Colors.transparent,
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