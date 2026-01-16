enum UserRole { hr, candidate, admin }

enum ApplicationStatus {
  applied,
  shortlisted,
  interviewScheduled,
  rejected,
  accepted
}

enum CandidateCategory { fresher, experienced, highPotential, reEvaluate }

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? phone;
  final String? company; // For HR users
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.company,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role.toString().split('.').last,
        'phone': phone,
        'company': company,
        'createdAt': createdAt.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        email: json['email'],
        name: json['name'],
        role: UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == json['role'],
        ),
        phone: json['phone'],
        company: json['company'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

