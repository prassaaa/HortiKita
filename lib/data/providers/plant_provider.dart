import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../repositories/plant_repository.dart';

class PlantProvider with ChangeNotifier {
  final PlantRepository _plantRepository = PlantRepository();
  
  List<Plant> _plants = [];
  List<Plant> _searchResults = [];
  bool _isLoading = false;
  String _error = '';
  String _selectedCategory = 'Semua';
  
  // Getters
  List<Plant> get plants => _plants;
  List<Plant> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get selectedCategory => _selectedCategory;
  
  // Menyetel kategori yang dipilih
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
    
    if (category == 'Semua') {
      fetchAllPlants();
    } else {
      fetchPlantsByCategory(category);
    }
  }
  
  // Mendapatkan semua tanaman
  Future<void> fetchAllPlants() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      _plants = await _plantRepository.getAllPlants();
    } catch (e) {
      _error = e.toString();
      _plants = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Mendapatkan tanaman berdasarkan kategori
  Future<void> fetchPlantsByCategory(String category) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      _plants = await _plantRepository.getPlantsByCategory(category);
    } catch (e) {
      _error = e.toString();
      _plants = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Mencari tanaman
  Future<void> searchPlants(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      _searchResults = await _plantRepository.searchPlants(query);
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Menambahkan data sampel
  Future<void> addSamplePlants() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      await _plantRepository.addSamplePlants();
      await fetchAllPlants();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menghapus tanaman berdasarkan ID
  Future<void> deletePlant(String plantId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      await _plantRepository.deletePlant(plantId);
      
      // Refresh daftar tanaman setelah penghapusan
      if (_selectedCategory == 'Semua') {
        await fetchAllPlants();
      } else {
        await fetchPlantsByCategory(_selectedCategory);
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}