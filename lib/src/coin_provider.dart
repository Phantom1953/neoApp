import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CoinProvider extends ChangeNotifier {
  int _coins = 0;
  String? _selectedImagePath;
  int _bestScoreFlutter = 0;
  int _bestScoreJava = 0;
  int _bestScoreSQL = 0;
  int _bestScoreNeoflex = 0;
  String _username = "Пользователь";
  bool _isLoading = true;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _purchasedItems = [];

  CoinProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUserData();
      } else {
        _resetData();
      }
    });
  }

  int get coins => _coins;
  int get bestScoreFlutter => _bestScoreFlutter;
  int get bestScoreJava => _bestScoreJava;
  int get bestScoreSQL => _bestScoreSQL;
  int get bestScoreNeoflex => _bestScoreNeoflex;
  String? get selectedImagePath => _selectedImagePath;
  String get username => _username;
  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  List<Map<String, dynamic>> get purchasedItems => _purchasedItems;

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _coins = doc['coins'] ?? 0;
        _selectedImagePath = doc['avatar'];
        _bestScoreFlutter = doc['bestScoreFlutter'] ?? 0;
        _bestScoreJava = doc['bestScoreJava'] ?? 0;
        _bestScoreSQL = doc['bestScoreSQL'] ?? 0;
        _bestScoreNeoflex = doc['bestScoreNeoflex'] ?? 0;
        _username = doc['username'] ?? "Пользователь";
        _isAdmin = doc['isAdmin'] ?? false;

        // Load purchased items
        final purchasedItems = doc['purchasedItems'] ?? [];
        _purchasedItems = List<Map<String, dynamic>>.from(purchasedItems);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _updateUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'coins': _coins,
        if (_selectedImagePath != null) 'avatar': _selectedImagePath,
        'bestScoreFlutter': _bestScoreFlutter,
        'bestScoreJava': _bestScoreJava,
        'bestScoreSQL': _bestScoreSQL,
        'bestScoreNeoflex': _bestScoreNeoflex,
        'username': _username,
        'isAdmin': _isAdmin,
        'purchasedItems': _purchasedItems,
      });
    } catch (e) {
      debugPrint('Error updating user data: $e');
    }
  }

  Future<String> _imageToBase64(XFile image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> addProduct({
    required String name,
    required int price,
    required String description,
    required XFile image,
  }) async {
    try {
      final imageBase64 = await _imageToBase64(image);

      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'price': price,
        'description': description,
        'image': imageBase64,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct({
    required String productId,
    String? name,
    int? price,
    String? description,
    XFile? image,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (name != null) updateData['name'] = name;
      if (price != null) updateData['price'] = price;
      if (description != null) updateData['description'] = description;
      if (image != null) {
        updateData['image'] = await _imageToBase64(image);
      }

      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update(updateData);
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> clearPurchasedItems() async {
    _purchasedItems.clear();
    await _updateUserData();
    notifyListeners();
  }

  List<Map<String, dynamic>> getPurchasedItems() {
    return List.from(_purchasedItems); // Возвращаем копию списка
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  void addPurchasedItem(Map<String, dynamic> product) {
    _purchasedItems.add(product);
    _updateUserData();
    notifyListeners();
  }

  void toggleAdminMode() {
    _isAdmin = !_isAdmin;
    _updateUserData();
    notifyListeners();
  }

  void setSelectedImage(String? path) {
    _selectedImagePath = path;
    _updateUserData();
    notifyListeners();
  }

  void setUsername(String name) {
    _username = name;
    _updateUserData();
    notifyListeners();
  }

  void addCoins(int amount) {
    _coins += amount;
    _updateUserData();
    notifyListeners();
  }

  void setBestScore(String category, int score) {
    switch (category) {
      case 'Flutter':
        if (score > _bestScoreFlutter) {
          _bestScoreFlutter = score;
          _updateUserData();
          notifyListeners();
        }
        break;
      case 'Java':
        if (score > _bestScoreJava) {
          _bestScoreJava = score;
          _updateUserData();
          notifyListeners();
        }
        break;
      case 'SQL':
        if (score > _bestScoreSQL) {
          _bestScoreSQL = score;
          _updateUserData();
          notifyListeners();
        }
        break;
      case 'Neoflex':
        if (score > _bestScoreNeoflex) {
          _bestScoreNeoflex = score;
          _updateUserData();
          notifyListeners();
        }
        break;
    }
  }

  bool spendCoins(int amount) {
    if (_coins >= amount) {
      _coins -= amount;
      _updateUserData();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _resetData();
    notifyListeners();
  }

  void _resetData() {
    _coins = 0;
    _selectedImagePath = null;
    _bestScoreFlutter = 0;
    _bestScoreJava = 0;
    _bestScoreSQL = 0;
    _bestScoreNeoflex = 0;
    _username = "Пользователь";
    _isLoading = true;
    _isAdmin = false;
    _purchasedItems = [];
  }
}