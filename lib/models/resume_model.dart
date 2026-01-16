class Resume {
  final String id;
  final String userId;
  final String name;
  final PersonalInfo personalInfo;
  final List<Education> education;
  final List<Experience> experience;
  final List<String> skills;
  final String? summary;
  final String templateId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Resume({
    required this.id,
    required this.userId,
    required this.name,
    required this.personalInfo,
    required this.education,
    required this.experience,
    required this.skills,
    this.summary,
    this.templateId = 'template1',
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'personalInfo': personalInfo.toJson(),
        'education': education.map((e) => e.toJson()).toList(),
        'experience': experience.map((e) => e.toJson()).toList(),
        'skills': skills,
        'summary': summary,
        'templateId': templateId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Resume.fromJson(Map<String, dynamic> json) => Resume(
        id: json['id'],
        userId: json['userId'],
        name: json['name'],
        personalInfo: PersonalInfo.fromJson(json['personalInfo']),
        education: (json['education'] as List)
            .map((e) => Education.fromJson(e))
            .toList(),
        experience: (json['experience'] as List)
            .map((e) => Experience.fromJson(e))
            .toList(),
        skills: List<String>.from(json['skills']),
        summary: json['summary'],
        templateId: json['templateId'] ?? 'template1',
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
      );
}

class PersonalInfo {
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final String? linkedIn;
  final String? portfolio;

  PersonalInfo({
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    this.linkedIn,
    this.portfolio,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        'linkedIn': linkedIn,
        'portfolio': portfolio,
      };

  factory PersonalInfo.fromJson(Map<String, dynamic> json) => PersonalInfo(
        fullName: json['fullName'],
        email: json['email'],
        phone: json['phone'],
        address: json['address'],
        linkedIn: json['linkedIn'],
        portfolio: json['portfolio'],
      );
}

class Education {
  final String degree;
  final String institution;
  final String? field;
  final String? startDate;
  final String? endDate;
  final double? gpa;

  Education({
    required this.degree,
    required this.institution,
    this.field,
    this.startDate,
    this.endDate,
    this.gpa,
  });

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'institution': institution,
        'field': field,
        'startDate': startDate,
        'endDate': endDate,
        'gpa': gpa,
      };

  factory Education.fromJson(Map<String, dynamic> json) => Education(
        degree: json['degree'],
        institution: json['institution'],
        field: json['field'],
        startDate: json['startDate'],
        endDate: json['endDate'],
        gpa: json['gpa']?.toDouble(),
      );
}

class Experience {
  final String title;
  final String company;
  final String? startDate;
  final String? endDate;
  final bool isCurrent;
  final List<String> responsibilities;

  Experience({
    required this.title,
    required this.company,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    required this.responsibilities,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'company': company,
        'startDate': startDate,
        'endDate': endDate,
        'isCurrent': isCurrent,
        'responsibilities': responsibilities,
      };

  factory Experience.fromJson(Map<String, dynamic> json) => Experience(
        title: json['title'],
        company: json['company'],
        startDate: json['startDate'],
        endDate: json['endDate'],
        isCurrent: json['isCurrent'] ?? false,
        responsibilities: List<String>.from(json['responsibilities']),
      );
}

