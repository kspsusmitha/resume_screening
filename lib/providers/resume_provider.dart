import 'package:flutter/foundation.dart';
import '../models/resume_model.dart';

class ResumeProvider with ChangeNotifier {
  final List<Resume> _resumes = [];
  Resume? _currentResume;
  bool _isLoading = false;

  List<Resume> get resumes => _resumes;
  Resume? get currentResume => _currentResume;
  bool get isLoading => _isLoading;

  List<Resume> getResumesByUser(String userId) {
    return _resumes.where((r) => r.userId == userId).toList();
  }

  void setCurrentResume(Resume? resume) {
    _currentResume = resume;
    notifyListeners();
  }

  Future<void> createResume(Resume resume) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _resumes.add(resume);
    _currentResume = resume;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateResume(Resume updatedResume) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final index = _resumes.indexWhere((r) => r.id == updatedResume.id);
    if (index != -1) {
      _resumes[index] = updatedResume;
      if (_currentResume?.id == updatedResume.id) {
        _currentResume = updatedResume;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteResume(String resumeId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _resumes.removeWhere((r) => r.id == resumeId);
    if (_currentResume?.id == resumeId) {
      _currentResume = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Resume? getResumeById(String resumeId) {
    try {
      return _resumes.firstWhere((r) => r.id == resumeId);
    } catch (e) {
      return null;
    }
  }
}

