import 'package:flutter/material.dart';

class ImageProvider extends ChangeNotifier {
  String? _selectedImagePath;

  String? get selectedImagePath => _selectedImagePath;

  void selectImage(String path) {
    _selectedImagePath = path;
    notifyListeners();
  }

  void clearSelection() {
    _selectedImagePath = null;
    notifyListeners();
  }
}