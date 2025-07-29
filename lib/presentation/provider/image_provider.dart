
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../secrets/api_key.dart';

// Enhanced state management enums
enum AppState {
  initial,
  pickingImage,
  imageSelected,
  removingBackground,
  backgroundRemoved,
  error,
  saving,
  saved
}

enum LoadingType {
  none,
  pickingImage,
  removingBackground,
  savingToGallery,
  sharing
}

class ImageHandleProvider extends ChangeNotifier {
  File? _originalImage;
  File? _processedImage;
  AppState _appState = AppState.initial;
  LoadingType _loadingType = LoadingType.none;
  String? _error;
  double _processingProgress = 0.0;

  // Getters
  File? get originalImage => _originalImage;
  File? get processedImage => _processedImage;
  AppState get appState => _appState;
  LoadingType get loadingType => _loadingType;
  String? get error => _error;
  double get processingProgress => _processingProgress;
  
  // Convenience getters for UI
  bool get isLoading => _loadingType != LoadingType.none;
  bool get hasOriginalImage => _originalImage != null;
  bool get hasProcessedImage => _processedImage != null;
  bool get canRemoveBackground => hasOriginalImage && !isLoading;
  bool get canSaveImage => hasProcessedImage && !isLoading;


  // Enhanced image picking with better state management
  Future<void> pickImage() async {
    _setLoadingState(LoadingType.pickingImage, AppState.pickingImage);
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (pickedFile != null) {
        _originalImage = File(pickedFile.path);
        _processedImage = null;
        _error = null;
        _appState = AppState.imageSelected;
      } else {
        _appState = AppState.initial;
      }
    } catch (e) {
      _setError('Failed to pick image: $e');
    } finally {
      _loadingType = LoadingType.none;
      notifyListeners();
    }
  }

  // Enhanced background removal with progress tracking
  Future<void> removeBackground() async {
    if (_originalImage == null) return;

    _setLoadingState(LoadingType.removingBackground, AppState.removingBackground);
    _processingProgress = 0.0;
    
    try {
      // Simulate progress updates
      _updateProgress(0.1);
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.remove.bg/v1.0/removebg'),
      );
      request.headers['X-Api-Key'] = Apikey().key;
      request.files.add(await http.MultipartFile.fromPath('image_file', _originalImage!.path));
      request.fields['size'] = 'auto';
      
      _updateProgress(0.3);
      
      final response = await request.send();
      
      _updateProgress(0.6);

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        
        _updateProgress(0.8);
        
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/no_bg_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        _processedImage = file;
        _appState = AppState.backgroundRemoved;
        _updateProgress(1.0);
        
        // Small delay to show completion
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        throw Exception('API Error: Status code ${response.statusCode}');
      }
    } catch (e) {
      _setError('Failed to remove background: $e');
    } finally {
      _loadingType = LoadingType.none;
      _processingProgress = 0.0;
      notifyListeners();
    }
  }

  // Enhanced save to gallery with permission handling
  Future<bool> saveToGallery() async {
    if (_processedImage == null) return false;
    
    _setLoadingState(LoadingType.savingToGallery, AppState.saving);
    
    try {
      // This will be handled in the UI layer for better UX
      return true;
    } catch (e) {
      _setError('Failed to save image: $e');
      return false;
    } finally {
      _loadingType = LoadingType.none;
      notifyListeners();
    }
  }

  // Enhanced sharing functionality
  Future<void> shareImage() async {
    if (_processedImage == null) return;
    
    _setLoadingState(LoadingType.sharing, _appState);
    
    try {
      // Sharing logic will be handled in UI
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate processing
    } catch (e) {
      _setError('Failed to share image: $e');
    } finally {
      _loadingType = LoadingType.none;
      notifyListeners();
    }
  }

  // Helper methods for state management
  void _setLoadingState(LoadingType loadingType, AppState appState) {
    _loadingType = loadingType;
    _appState = appState;
    _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _appState = AppState.error;
    _loadingType = LoadingType.none;
  }

  void _updateProgress(double progress) {
    _processingProgress = progress;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    if (_appState == AppState.error) {
      _appState = hasProcessedImage ? AppState.backgroundRemoved : 
                  hasOriginalImage ? AppState.imageSelected : AppState.initial;
    }
    notifyListeners();
  }

  void reset() {
    _originalImage = null;
    _processedImage = null;
    _error = null;
    _loadingType = LoadingType.none;
    _appState = AppState.initial;
    _processingProgress = 0.0;
    notifyListeners();
  }
}
