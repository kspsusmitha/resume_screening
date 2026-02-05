import 'package:flutter/foundation.dart';
import '../models/application_model.dart';
import '../models/user_model.dart';
import '../services/firebase_database_service.dart';

class ApplicationProvider with ChangeNotifier {
  final List<Application> _applications = [];
  bool _isLoading = false;

  List<Application> get applications => _applications;
  bool get isLoading => _isLoading;

  List<Application> getApplicationsByJob(String jobId) {
    return _applications.where((a) => a.jobId == jobId).toList();
  }

  Future<void> loadApplications() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseService = FirebaseDatabaseService(); // Get instance
      final appsData = await firebaseService.getApplications();
      _applications.clear();
      for (var data in appsData) {
        try {
          _applications.add(Application.fromJson(data));
        } catch (e) {
          print('Error parsing application: $e');
        }
      }
    } catch (e) {
      print('Error loading applications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Application> getApplicationsByCandidate(String candidateId) {
    return _applications.where((a) => a.candidateId == candidateId).toList();
  }

  Future<void> createApplication(Application application) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _applications.add(application);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index != -1) {
      _applications[index] = _applications[index].copyWith(
        status: status,
        updatedDate: DateTime.now(),
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateApplicationCategory(
    String applicationId,
    CandidateCategory category,
  ) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index != -1) {
      _applications[index] = _applications[index].copyWith(
        category: category,
        updatedDate: DateTime.now(),
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateApplicationMatchScore(
    String applicationId,
    double matchPercentage,
    List<String> missingSkills,
  ) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index != -1) {
      _applications[index] = _applications[index].copyWith(
        matchPercentage: matchPercentage,
        missingSkills: missingSkills,
        updatedDate: DateTime.now(),
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Application? getApplicationById(String applicationId) {
    try {
      return _applications.firstWhere((a) => a.id == applicationId);
    } catch (e) {
      return null;
    }
  }

  Future<void> scheduleInterview({
    required String applicationId,
    required DateTime interviewDate,
    required String interviewTime,
    required String interviewerName,
    required String interviewLocation,
    String? interviewNotes,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index != -1) {
      _applications[index] = _applications[index].copyWith(
        status: ApplicationStatus.interviewScheduled,
        interviewDate: interviewDate,
        interviewTime: interviewTime,
        interviewerName: interviewerName,
        interviewLocation: interviewLocation,
        interviewNotes: interviewNotes,
        updatedDate: DateTime.now(),
      );
    }

    _isLoading = false;
    notifyListeners();
  }
}
