import 'package:flutter/foundation.dart';
import '../models/interview_model.dart';

class InterviewProvider with ChangeNotifier {
  final List<InterviewSession> _sessions = [];
  InterviewSession? _currentSession;
  bool _isLoading = false;

  List<InterviewSession> get sessions => _sessions;
  InterviewSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;

  List<InterviewSession> getSessionsByCandidate(String candidateId) {
    return _sessions.where((s) => s.candidateId == candidateId).toList();
  }

  void setCurrentSession(InterviewSession? session) {
    _currentSession = session;
    notifyListeners();
  }

  Future<void> createSession(InterviewSession session) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _sessions.add(session);
    _currentSession = session;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSession(InterviewSession updatedSession) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final index = _sessions.indexWhere((s) => s.id == updatedSession.id);
    if (index != -1) {
      _sessions[index] = updatedSession;
      if (_currentSession?.id == updatedSession.id) {
        _currentSession = updatedSession;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  InterviewSession? getSessionById(String sessionId) {
    try {
      return _sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }
}

