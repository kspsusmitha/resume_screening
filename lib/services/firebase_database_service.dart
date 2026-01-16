import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class FirebaseDatabaseService {
  static final FirebaseDatabaseService _instance = FirebaseDatabaseService._internal();
  factory FirebaseDatabaseService() => _instance;
  FirebaseDatabaseService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Helper method to get the correct branch path based on role
  String _getUserBranch(UserRole role) {
    switch (role) {
      case UserRole.hr:
        return 'hr';
      case UserRole.candidate:
        return 'candidates';
      case UserRole.admin:
        return 'users'; // Admin stays in users branch
    }
  }

  // User operations
  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? company,
  }) async {
    try {
      // Determine the correct branch based on role
      final branch = _getUserBranch(role);
      
      // Check if user already exists in the appropriate branch
      final emailSnapshot = await _database
          .child(branch)
          .orderByChild('email')
          .equalTo(email)
          .once();

      if (emailSnapshot.snapshot.value != null) {
        return 'Email already registered';
      }

      // Also check in other branches to ensure email uniqueness across all roles
      if (role == UserRole.hr) {
        final candidateCheck = await _database
            .child('candidates')
            .orderByChild('email')
            .equalTo(email)
            .once();
        if (candidateCheck.snapshot.value != null) {
          return 'Email already registered';
        }
      } else if (role == UserRole.candidate) {
        final hrCheck = await _database
            .child('hr')
            .orderByChild('email')
            .equalTo(email)
            .once();
        if (hrCheck.snapshot.value != null) {
          return 'Email already registered';
        }
      }

      // Create new user in the appropriate branch
      final userId = _database.child(branch).push().key!;
      final userData = {
        'id': userId,
        'email': email,
        'password': password, // In production, hash this password
        'name': name,
        'role': role.toString().split('.').last,
        'phone': phone ?? '',
        'company': company ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _database.child(branch).child(userId).set(userData);
      return null; // Success
    } catch (e) {
      return 'Registration failed: ${e.toString()}';
    }
  }

  Future<User?> loginUser(String email, String password, UserRole role) async {
    try {
      // Determine the correct branch based on role
      final branch = _getUserBranch(role);
      
      // Query the appropriate branch
      final snapshot = await _database
          .child(branch)
          .orderByChild('email')
          .equalTo(email)
          .once();

      if (snapshot.snapshot.value == null) {
        return null;
      }

      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      final userEntry = data.values.first as Map<dynamic, dynamic>;
      
      // Check password
      if (userEntry['password'] != password) {
        return null;
      }

      // Verify role matches (extra safety check)
      final userRole = UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == userEntry['role'],
      );
      
      if (userRole != role) {
        return null;
      }

      return User.fromJson(Map<String, dynamic>.from(userEntry));
    } catch (e) {
      return null;
    }
  }

  Future<User?> loginAdmin(String email, String password) async {
    try {
      // Admin credentials are predefined
      // In production, store these securely or use environment variables
      const adminEmail = 'admin@resumescreening.com';
      const adminPassword = 'admin123'; // Change this in production

      if (email == adminEmail && password == adminPassword) {
        // Admin stays in 'users' branch
        // Check if admin user exists in database, if not create it
        final adminSnapshot = await _database
            .child('users')
            .orderByChild('email')
            .equalTo(adminEmail)
            .once();

        if (adminSnapshot.snapshot.value == null) {
          // Create admin user in 'users' branch
          final adminId = _database.child('users').push().key!;
          final adminData = {
            'id': adminId,
            'email': adminEmail,
            'password': adminPassword,
            'name': 'System Admin',
            'role': 'admin',
            'phone': '',
            'company': '',
            'createdAt': DateTime.now().toIso8601String(),
          };
          await _database.child('users').child(adminId).set(adminData);
          
          return User.fromJson(Map<String, dynamic>.from(adminData));
        } else {
          final data = adminSnapshot.snapshot.value as Map<dynamic, dynamic>;
          final adminEntry = data.values.first as Map<dynamic, dynamic>;
          return User.fromJson(Map<String, dynamic>.from(adminEntry));
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<User?> getUserById(String userId, UserRole role) async {
    try {
      // Determine the correct branch based on role
      final branch = _getUserBranch(role);
      
      final snapshot = await _database.child(branch).child(userId).once();
      if (snapshot.snapshot.value == null) {
        return null;
      }
      final data = Map<String, dynamic>.from(
        snapshot.snapshot.value as Map<dynamic, dynamic>,
      );
      return User.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // Get user by ID without knowing role (searches all branches)
  Future<User?> getUserByIdAnyBranch(String userId) async {
    try {
      // Try HR branch first
      var snapshot = await _database.child('hr').child(userId).once();
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(
          snapshot.snapshot.value as Map<dynamic, dynamic>,
        );
        return User.fromJson(data);
      }

      // Try Candidates branch
      snapshot = await _database.child('candidates').child(userId).once();
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(
          snapshot.snapshot.value as Map<dynamic, dynamic>,
        );
        return User.fromJson(data);
      }

      // Try Users branch (for admin)
      snapshot = await _database.child('users').child(userId).once();
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(
          snapshot.snapshot.value as Map<dynamic, dynamic>,
        );
        return User.fromJson(data);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Get all HR users
  Future<List<User>> getAllHRs() async {
    try {
      final snapshot = await _database.child('hr').once();
      if (snapshot.snapshot.value == null) {
        return [];
      }
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((entry) {
        final userData = Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>);
        return User.fromJson(userData);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get all Candidates
  Future<List<User>> getAllCandidates() async {
    try {
      final snapshot = await _database.child('candidates').once();
      if (snapshot.snapshot.value == null) {
        return [];
      }
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((entry) {
        final userData = Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>);
        return User.fromJson(userData);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Update user data (works with any branch)
  Future<bool> updateUser(String userId, UserRole role, Map<String, dynamic> updates) async {
    try {
      final branch = _getUserBranch(role);
      await _database.child(branch).child(userId).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete user (works with any branch)
  Future<bool> deleteUser(String userId, UserRole role) async {
    try {
      final branch = _getUserBranch(role);
      await _database.child(branch).child(userId).remove();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Job operations
  Future<String?> createJob(Map<String, dynamic> jobData) async {
    try {
      final jobId = _database.child('jobs').push().key!;
      jobData['id'] = jobId;
      jobData['createdAt'] = DateTime.now().toIso8601String();
      await _database.child('jobs').child(jobId).set(jobData);
      return jobId;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getJobs() async {
    try {
      final snapshot = await _database.child('jobs').once();
      if (snapshot.snapshot.value == null) {
        return [];
      }
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((entry) {
        final jobData = Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>);
        return jobData;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getJobById(String jobId) async {
    try {
      final snapshot = await _database.child('jobs').child(jobId).once();
      if (snapshot.snapshot.value == null) {
        return null;
      }
      return Map<String, dynamic>.from(
        snapshot.snapshot.value as Map<dynamic, dynamic>,
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateJob(String jobId, Map<String, dynamic> updates) async {
    try {
      await _database.child('jobs').child(jobId).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteJob(String jobId) async {
    try {
      await _database.child('jobs').child(jobId).remove();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Application operations
  Future<String?> createApplication(Map<String, dynamic> applicationData) async {
    try {
      final appId = _database.child('applications').push().key!;
      applicationData['id'] = appId;
      applicationData['createdAt'] = DateTime.now().toIso8601String();
      applicationData['status'] = 'applied';
      await _database.child('applications').child(appId).set(applicationData);
      return appId;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getApplications({String? jobId, String? candidateId}) async {
    try {
      Query query = _database.child('applications');
      
      if (jobId != null) {
        query = query.orderByChild('jobId').equalTo(jobId);
      } else if (candidateId != null) {
        query = query.orderByChild('candidateId').equalTo(candidateId);
      }
      
      final snapshot = await query.once();
      if (snapshot.snapshot.value == null) {
        return [];
      }
      
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((entry) {
        return Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateApplication(String applicationId, Map<String, dynamic> updates) async {
    try {
      await _database.child('applications').child(applicationId).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Resume operations
  Future<String?> saveResume(String userId, Map<String, dynamic> resumeData) async {
    try {
      final resumeId = _database.child('resumes').push().key!;
      resumeData['id'] = resumeId;
      resumeData['userId'] = userId;
      resumeData['createdAt'] = DateTime.now().toIso8601String();
      await _database.child('resumes').child(resumeId).set(resumeData);
      return resumeId;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getResumes(String userId) async {
    try {
      final snapshot = await _database
          .child('resumes')
          .orderByChild('userId')
          .equalTo(userId)
          .once();
      
      if (snapshot.snapshot.value == null) {
        return [];
      }
      
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((entry) {
        return Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Real-time listeners
  DatabaseReference getJobsStream() {
    return _database.child('jobs');
  }

  Query getApplicationsStream({String? jobId}) {
    if (jobId != null) {
      return _database.child('applications').orderByChild('jobId').equalTo(jobId);
    }
    return _database.child('applications');
  }
}
