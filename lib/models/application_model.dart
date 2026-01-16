import 'user_model.dart';

class Application {
  final String id;
  final String jobId;
  final String candidateId;
  final String candidateName;
  final String candidateEmail;
  final String? resumePath;
  final String? resumeText;
  final String? videoResumePath;
  final ApplicationStatus status;
  final CandidateCategory? category;
  final double? matchPercentage;
  final List<String>? missingSkills;
  final String? notes;
  final DateTime appliedDate;
  final DateTime? updatedDate;

  Application({
    required this.id,
    required this.jobId,
    required this.candidateId,
    required this.candidateName,
    required this.candidateEmail,
    this.resumePath,
    this.resumeText,
    this.videoResumePath,
    this.status = ApplicationStatus.applied,
    this.category,
    this.matchPercentage,
    this.missingSkills,
    this.notes,
    DateTime? appliedDate,
    this.updatedDate,
  }) : appliedDate = appliedDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'candidateId': candidateId,
        'candidateName': candidateName,
        'candidateEmail': candidateEmail,
        'resumePath': resumePath,
        'resumeText': resumeText,
        'videoResumePath': videoResumePath,
        'status': status.toString().split('.').last,
        'category': category?.toString().split('.').last,
        'matchPercentage': matchPercentage,
        'missingSkills': missingSkills,
        'notes': notes,
        'appliedDate': appliedDate.toIso8601String(),
        'updatedDate': updatedDate?.toIso8601String(),
      };

  factory Application.fromJson(Map<String, dynamic> json) => Application(
        id: json['id'],
        jobId: json['jobId'],
        candidateId: json['candidateId'],
        candidateName: json['candidateName'],
        candidateEmail: json['candidateEmail'],
        resumePath: json['resumePath'],
        resumeText: json['resumeText'],
        videoResumePath: json['videoResumePath'],
        status: ApplicationStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status'],
        ),
        category: json['category'] != null
            ? CandidateCategory.values.firstWhere(
                (e) => e.toString().split('.').last == json['category'],
              )
            : null,
        matchPercentage: json['matchPercentage']?.toDouble(),
        missingSkills: json['missingSkills'] != null
            ? List<String>.from(json['missingSkills'])
            : null,
        notes: json['notes'],
        appliedDate: DateTime.parse(json['appliedDate']),
        updatedDate: json['updatedDate'] != null
            ? DateTime.parse(json['updatedDate'])
            : null,
      );

  Application copyWith({
    String? id,
    String? jobId,
    String? candidateId,
    String? candidateName,
    String? candidateEmail,
    String? resumePath,
    String? resumeText,
    String? videoResumePath,
    ApplicationStatus? status,
    CandidateCategory? category,
    double? matchPercentage,
    List<String>? missingSkills,
    String? notes,
    DateTime? appliedDate,
    DateTime? updatedDate,
  }) {
    return Application(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      candidateId: candidateId ?? this.candidateId,
      candidateName: candidateName ?? this.candidateName,
      candidateEmail: candidateEmail ?? this.candidateEmail,
      resumePath: resumePath ?? this.resumePath,
      resumeText: resumeText ?? this.resumeText,
      videoResumePath: videoResumePath ?? this.videoResumePath,
      status: status ?? this.status,
      category: category ?? this.category,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      missingSkills: missingSkills ?? this.missingSkills,
      notes: notes ?? this.notes,
      appliedDate: appliedDate ?? this.appliedDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }
}

