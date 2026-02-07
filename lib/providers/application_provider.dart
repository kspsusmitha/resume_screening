import 'package:flutter/foundation.dart';
import '../models/application_model.dart';
import '../models/user_model.dart';
import '../services/firebase_database_service.dart';
import '../providers/notification_provider.dart';

class ApplicationProvider with ChangeNotifier {
  final List<Application> _applications = [];
  bool _isLoading = false;
  NotificationProvider? _notificationProvider;

  void update(NotificationProvider notificationProvider) {
    _notificationProvider = notificationProvider;
  }

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

  bool hasAppliedForJob(String jobId, String candidateId) {
    return _applications.any(
      (app) => app.jobId == jobId && app.candidateId == candidateId,
    );
  }

  Future<void> createApplication(Application application) async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseService = FirebaseDatabaseService();
      final appId = await firebaseService.createApplication(
        application.toJson(),
      );

      if (appId != null) {
        // Update the local model with the generated ID (though it might already match)
        // ideally we rely on the load, but we can optimistically add it
        _applications.add(application.copyWith(id: appId));

        // Notify candidate (optional: usually immediate feedback is enough, but notification is good)
        await _notificationProvider?.sendNotification(
          userId: application.candidateId,
          title: 'Application Received',
          message: 'Your application has been received successfully.',
          type: 'application_received',
          relatedId: appId,
        );
      }
    } catch (e) {
      print('Error creating application: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseService = FirebaseDatabaseService();
      await firebaseService.updateApplication(applicationId, {
        'status': status.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        final app = _applications[index];
        _applications[index] = app.copyWith(
          status: status,
          updatedDate: DateTime.now(),
        );

        // Notify candidate
        String message =
            'Your application status has been updated to: ${status.toString().split('.').last.toUpperCase()}';
        if (status == ApplicationStatus.accepted) {
          message = 'Congratulations! Your application has been accepted.';
        } else if (status == ApplicationStatus.rejected) {
          message = 'Update on your application.';
        }

        await _notificationProvider?.sendNotification(
          userId: app.candidateId,
          title: 'Application Update',
          message: message,
          type: 'status_update',
          relatedId: applicationId,
        );
      }
    } catch (e) {
      print('Error updating status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateApplicationCategory(
    String applicationId,
    CandidateCategory category,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseService = FirebaseDatabaseService();
      await firebaseService.updateApplication(applicationId, {
        'category': category.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        _applications[index] = _applications[index].copyWith(
          category: category,
          updatedDate: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error updating category: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateApplicationMatchScore(
    String applicationId,
    double matchPercentage,
    List<String> missingSkills,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseService = FirebaseDatabaseService();
      await firebaseService.updateApplication(applicationId, {
        'matchPercentage': matchPercentage,
        'missingSkills': missingSkills,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        _applications[index] = _applications[index].copyWith(
          matchPercentage: matchPercentage,
          missingSkills: missingSkills,
          updatedDate: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error updating match score: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

    try {
      final firebaseService = FirebaseDatabaseService();
      await firebaseService.updateApplication(applicationId, {
        'status': ApplicationStatus.interviewScheduled
            .toString()
            .split('.')
            .last,
        'interviewDate': interviewDate.toIso8601String(),
        'interviewTime': interviewTime,
        'interviewerName': interviewerName,
        'interviewLocation': interviewLocation,
        'interviewNotes': interviewNotes,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        final app = _applications[index];
        _applications[index] = app.copyWith(
          status: ApplicationStatus.interviewScheduled,
          interviewDate: interviewDate,
          interviewTime: interviewTime,
          interviewerName: interviewerName,
          interviewLocation: interviewLocation,
          interviewNotes: interviewNotes,
          updatedDate: DateTime.now(),
        );

        // Notify candidate
        await _notificationProvider?.sendNotification(
          userId: app.candidateId,
          title: 'Interview Scheduled',
          message:
              'An interview has been scheduled. Check details in your application.',
          type: 'interview_scheduled',
          relatedId: applicationId,
        );
      }
    } catch (e) {
      print('Error scheduling interview: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
