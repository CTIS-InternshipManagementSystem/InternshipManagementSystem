import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteBilkentIds = {};
  final Map<String, Map<String, dynamic>> _favoriteStudents = {};
  bool _isLoading = true;

  Set<String> get favoriteBilkentIds => _favoriteBilkentIds;
  Map<String, Map<String, dynamic>> get favoriteStudents => _favoriteStudents;
  bool get isLoading => _isLoading;

  FavoritesProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteData = prefs.getString('favorite_students');
      
      if (favoriteData != null) {
        final Map<String, dynamic> decoded = json.decode(favoriteData);
        
        // Clear existing data before loading
        _favoriteBilkentIds.clear();
        _favoriteStudents.clear();
        
        // Convert the decoded map to our _favoriteStudents map
        decoded.forEach((key, value) {
          _favoriteBilkentIds.add(key);
          if (value is Map<String, dynamic>) {
            _favoriteStudents[key] = value;
          } else {
            _favoriteStudents[key] = Map<String, dynamic>.from(value as Map);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = json.encode(_favoriteStudents);
      await prefs.setString('favorite_students', encodedData);
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  bool isFavorite(String bilkentId) {
    return _favoriteBilkentIds.contains(bilkentId);
  }

  // Create a proper deep copy of nested maps to avoid reference issues
  Map<String, dynamic> _createDeepCopy(Map<String, dynamic> original) {
    Map<String, dynamic> copy = {};
    
    original.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        copy[key] = _createDeepCopy(value);
      } else if (value is Map) {
        copy[key] = Map<String, dynamic>.from(value);
      } else if (value is List) {
        copy[key] = List.from(value);
      } else {
        copy[key] = value;
      }
    });
    
    return copy;
  }

  void toggleFavorite(Map<String, dynamic> student) {
    final String bilkentId = student['bilkentId']?.toString() ?? '';
    if (bilkentId.isEmpty) {
      debugPrint('Error: Student has no Bilkent ID');
      return;
    }

    try {
      // Ensure we're working with a clean copy of student data
      final Map<String, dynamic> cleanStudentData = {
        'bilkentId': bilkentId,
        'name': student['name']?.toString() ?? '',
        'email': student['email']?.toString() ?? '',
        'course': student['course'] is Map 
          ? Map<String, dynamic>.from(student['course'] as Map)
          : {'courseId': '', 'year': '', 'semester': '', 'code': ''},
        'companyEvaluationUploaded': student['companyEvaluationUploaded'] ?? false,
      };

      if (_favoriteBilkentIds.contains(bilkentId)) {
        _favoriteBilkentIds.remove(bilkentId);
        _favoriteStudents.remove(bilkentId);
      } else {
        _favoriteBilkentIds.add(bilkentId);
        // Create a proper deep copy to avoid reference issues
        _favoriteStudents[bilkentId] = _createDeepCopy(cleanStudentData);
      }
      
      _saveFavorites();
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }
  
  // Add a student directly to favorites without toggle
  void addToFavorites(Map<String, dynamic> student) {
    final String bilkentId = student['bilkentId']?.toString() ?? '';
    if (bilkentId.isEmpty) {
      debugPrint('Error: Student has no Bilkent ID');
      return;
    }
    
    if (!_favoriteBilkentIds.contains(bilkentId)) {
      _favoriteBilkentIds.add(bilkentId);
      _favoriteStudents[bilkentId] = _createDeepCopy(student);
      _saveFavorites();
      notifyListeners();
    }
  }
  
  // Remove a student directly from favorites without toggle
  void removeFromFavorites(String bilkentId) {
    if (_favoriteBilkentIds.contains(bilkentId)) {
      _favoriteBilkentIds.remove(bilkentId);
      _favoriteStudents.remove(bilkentId);
      _saveFavorites();
      notifyListeners();
    }
  }
}