import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/job_model.dart';
import '../services/firebase_database_service.dart';

class JobProvider with ChangeNotifier {
  final List<Job> _jobs = [];
  bool _isLoading = false;
  String? _searchQuery;
  String? _filterDomain;
  String? _filterLocation;
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();
  DatabaseReference? _jobsRef;

  List<Job> get jobs => _jobs;
  List<Job> get activeJobs =>
      _jobs.where((job) => job.isActive).toList();
  bool get isLoading => _isLoading;
  String? get searchQuery => _searchQuery;
  String? get filterDomain => _filterDomain;
  String? get filterLocation => _filterLocation;

  List<Job> get filteredJobs {
    var filtered = activeJobs;

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((job) {
        return job.title.toLowerCase().contains(query) ||
            job.description.toLowerCase().contains(query) ||
            job.domain.toLowerCase().contains(query);
      }).toList();
    }

    if (_filterDomain != null && _filterDomain!.isNotEmpty) {
      filtered = filtered
          .where((job) => job.domain.toLowerCase() == _filterDomain!.toLowerCase())
          .toList();
    }

    if (_filterLocation != null && _filterLocation!.isNotEmpty) {
      filtered = filtered
          .where((job) => job.location.toLowerCase() == _filterLocation!.toLowerCase())
          .toList();
    }

    return filtered;
  }

  /// Initialize and load jobs from Firebase Realtime Database
  Future<void> loadJobs() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      // Load initial jobs
      final jobsData = await _databaseService.getJobs();
      _jobs.clear();
      
      for (var jobData in jobsData) {
        try {
          final job = Job.fromJson(jobData);
          _jobs.add(job);
        } catch (e) {
          print('Error parsing job: $e');
        }
      }

      // Set up real-time listener
      _setupRealtimeListener();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading jobs: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set up real-time listener for job updates
  void _setupRealtimeListener() {
    _jobsRef?.onDisconnect();
    _jobsRef = _databaseService.getJobsStream();
    
    _jobsRef?.onValue.listen((event) {
      if (event.snapshot.value == null) {
        _jobs.clear();
        notifyListeners();
        return;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      _jobs.clear();

      for (var entry in data.entries) {
        try {
          final jobData = Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>);
          final job = Job.fromJson(jobData);
          _jobs.add(job);
        } catch (e) {
          print('Error parsing job from real-time update: $e');
        }
      }

      notifyListeners();
    });
  }

  /// Dispose real-time listener
  @override
  void dispose() {
    _jobsRef?.onDisconnect();
    super.dispose();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterDomain(String? domain) {
    _filterDomain = domain;
    notifyListeners();
  }

  void setFilterLocation(String? location) {
    _filterLocation = location;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = null;
    _filterDomain = null;
    _filterLocation = null;
    notifyListeners();
  }

  Future<void> createJob(Job job) async {
    _isLoading = true;
    notifyListeners();

    try {
      final jobData = job.toJson();
      final jobId = await _databaseService.createJob(jobData);
      
      if (jobId != null) {
        // Job will be added via real-time listener
        // But we can also add it locally for immediate UI update
        final newJob = Job.fromJson({...jobData, 'id': jobId});
        _jobs.add(newJob);
        notifyListeners();
      } else {
        throw Exception('Failed to create job');
      }
    } catch (e) {
      print('Error creating job: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateJob(Job updatedJob) async {
    _isLoading = true;
    notifyListeners();

    try {
      final jobData = updatedJob.toJson();
      // Remove id and createdAt from update data (they shouldn't be updated)
      jobData.remove('id');
      jobData.remove('createdAt');
      jobData['updatedAt'] = DateTime.now().toIso8601String();

      final success = await _databaseService.updateJob(updatedJob.id, jobData);
      
      if (!success) {
        throw Exception('Failed to update job');
      }
      
      // Job will be updated via real-time listener
      // But we can also update locally for immediate UI update
      final index = _jobs.indexWhere((j) => j.id == updatedJob.id);
      if (index != -1) {
        _jobs[index] = updatedJob;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating job: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteJob(String jobId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _databaseService.deleteJob(jobId);
      
      if (!success) {
        throw Exception('Failed to delete job');
      }
      
      // Job will be removed via real-time listener
      // But we can also remove locally for immediate UI update
      _jobs.removeWhere((j) => j.id == jobId);
      notifyListeners();
    } catch (e) {
      print('Error deleting job: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Job? getJobById(String jobId) {
    try {
      return _jobs.firstWhere((j) => j.id == jobId);
    } catch (e) {
      return null;
    }
  }

  List<Job> getJobsByHr(String hrId) {
    return _jobs.where((j) => j.hrId == hrId).toList();
  }
}

