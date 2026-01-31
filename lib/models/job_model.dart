class Job {
  final String id;
  final String title;
  final String description;
  final List<String> requiredSkills;
  final int experienceLevel; // years
  final String? salaryRange;
  final String location;
  final String domain;
  final String hrId; // HR who posted
  final String hrName;
  final DateTime postedDate;
  final DateTime? deadline;
  final bool isActive;
  final int applicationsCount;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredSkills,
    required this.experienceLevel,
    this.salaryRange,
    required this.location,
    required this.domain,
    required this.hrId,
    required this.hrName,
    DateTime? postedDate,
    this.deadline,
    this.isActive = true,
    this.applicationsCount = 0,
  }) : postedDate = postedDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'requiredSkills': requiredSkills,
        'experienceLevel': experienceLevel,
        'salaryRange': salaryRange,
        'location': location,
        'domain': domain,
        'hrId': hrId,
        'hrName': hrName,
        'postedDate': postedDate.toIso8601String(),
        'createdAt': postedDate.toIso8601String(), // For Firebase compatibility
        'deadline': deadline?.toIso8601String(),
        'isActive': isActive,
        'applicationsCount': applicationsCount,
      };

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        requiredSkills: json['requiredSkills'] != null
            ? List<String>.from(json['requiredSkills'])
            : [],
        experienceLevel: json['experienceLevel'] ?? 0,
        salaryRange: json['salaryRange'],
        location: json['location'] ?? '',
        domain: json['domain'] ?? '',
        hrId: json['hrId'] ?? '',
        hrName: json['hrName'] ?? '',
        postedDate: json['postedDate'] != null
            ? DateTime.parse(json['postedDate'])
            : (json['createdAt'] != null
                ? DateTime.parse(json['createdAt'])
                : DateTime.now()),
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'])
            : null,
        isActive: json['isActive'] ?? true,
        applicationsCount: json['applicationsCount'] ?? 0,
      );

  Job copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? requiredSkills,
    int? experienceLevel,
    String? salaryRange,
    String? location,
    String? domain,
    String? hrId,
    String? hrName,
    DateTime? postedDate,
    DateTime? deadline,
    bool? isActive,
    int? applicationsCount,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      salaryRange: salaryRange ?? this.salaryRange,
      location: location ?? this.location,
      domain: domain ?? this.domain,
      hrId: hrId ?? this.hrId,
      hrName: hrName ?? this.hrName,
      postedDate: postedDate ?? this.postedDate,
      deadline: deadline ?? this.deadline,
      isActive: isActive ?? this.isActive,
      applicationsCount: applicationsCount ?? this.applicationsCount,
    );
  }
}

