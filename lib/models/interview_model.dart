class InterviewSession {
  final String id;
  final String candidateId;
  final String jobId;
  final String domain;
  final List<QuestionAnswer> questions;
  final double? overallScore;
  final String? feedback;
  final DateTime createdAt;

  InterviewSession({
    required this.id,
    required this.candidateId,
    required this.jobId,
    required this.domain,
    required this.questions,
    this.overallScore,
    this.feedback,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'candidateId': candidateId,
        'jobId': jobId,
        'domain': domain,
        'questions': questions.map((q) => q.toJson()).toList(),
        'overallScore': overallScore,
        'feedback': feedback,
        'createdAt': createdAt.toIso8601String(),
      };

  factory InterviewSession.fromJson(Map<String, dynamic> json) =>
      InterviewSession(
        id: json['id'],
        candidateId: json['candidateId'],
        jobId: json['jobId'],
        domain: json['domain'],
        questions: (json['questions'] as List)
            .map((q) => QuestionAnswer.fromJson(q))
            .toList(),
        overallScore: json['overallScore']?.toDouble(),
        feedback: json['feedback'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class QuestionAnswer {
  final String question;
  final String? answer;
  final double? score;
  final String? feedback;
  final List<String>? strengths;
  final List<String>? improvements;

  QuestionAnswer({
    required this.question,
    this.answer,
    this.score,
    this.feedback,
    this.strengths,
    this.improvements,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
        'score': score,
        'feedback': feedback,
        'strengths': strengths,
        'improvements': improvements,
      };

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) =>
      QuestionAnswer(
        question: json['question'],
        answer: json['answer'],
        score: json['score']?.toDouble(),
        feedback: json['feedback'],
        strengths: json['strengths'] != null
            ? List<String>.from(json['strengths'])
            : null,
        improvements: json['improvements'] != null
            ? List<String>.from(json['improvements'])
            : null,
      );
}

