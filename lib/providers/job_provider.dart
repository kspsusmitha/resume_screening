import 'package:flutter/foundation.dart';
import '../models/job_model.dart';

class JobProvider with ChangeNotifier {
  final List<Job> _jobs = [];
  bool _isLoading = false;
  String? _searchQuery;
  String? _filterDomain;
  String? _filterLocation;

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

  // Initialize with mock data
  void initializeMockData() {
    _jobs.addAll([
      Job(
        id: '1',
        title: 'Senior Flutter Developer',
        description:
            'We are looking for an experienced Flutter developer to join our mobile team. You will be responsible for developing and maintaining mobile applications.',
        requiredSkills: ['Flutter', 'Dart', 'REST APIs', 'State Management'],
        experienceLevel: 3,
        salaryRange: '\$80,000 - \$120,000',
        location: 'Remote',
        domain: 'Mobile Development',
        hrId: 'hr1',
        hrName: 'John Doe',
        applicationsCount: 5,
      ),
      Job(
        id: '2',
        title: 'UI/UX Designer',
        description:
            'Join our design team to create beautiful and intuitive user interfaces. Experience with Figma and design systems required.',
        requiredSkills: ['Figma', 'UI/UX Design', 'Prototyping', 'User Research'],
        experienceLevel: 2,
        salaryRange: '\$60,000 - \$90,000',
        location: 'New York',
        domain: 'Design',
        hrId: 'hr2',
        hrName: 'Jane Smith',
        applicationsCount: 8,
      ),
      Job(
        id: '3',
        title: 'Backend Developer',
        description:
            'We need a backend developer with experience in Node.js and databases. You will work on scalable APIs and microservices.',
        requiredSkills: ['Node.js', 'MongoDB', 'REST APIs', 'AWS'],
        experienceLevel: 4,
        salaryRange: '\$90,000 - \$130,000',
        location: 'San Francisco',
        domain: 'Backend Development',
        hrId: 'hr1',
        hrName: 'John Doe',
        applicationsCount: 12,
      ),
    ]);
    notifyListeners();
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

    await Future.delayed(const Duration(seconds: 1));

    _jobs.add(job);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateJob(Job updatedJob) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final index = _jobs.indexWhere((j) => j.id == updatedJob.id);
    if (index != -1) {
      _jobs[index] = updatedJob;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteJob(String jobId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _jobs.removeWhere((j) => j.id == jobId);
    _isLoading = false;
    notifyListeners();
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

