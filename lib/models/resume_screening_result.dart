class ResumeScreeningResult {
  final double matchPercentage;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final String extractedInfo;
  final String analysis;
  final String recommendation;

  ResumeScreeningResult({
    required this.matchPercentage,
    required this.matchedSkills,
    required this.missingSkills,
    required this.extractedInfo,
    required this.analysis,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() => {
        'matchPercentage': matchPercentage,
        'matchedSkills': matchedSkills,
        'missingSkills': missingSkills,
        'extractedInfo': extractedInfo,
        'analysis': analysis,
        'recommendation': recommendation,
      };

  factory ResumeScreeningResult.fromJson(Map<String, dynamic> json) =>
      ResumeScreeningResult(
        matchPercentage: json['matchPercentage']?.toDouble() ?? 0.0,
        matchedSkills: List<String>.from(json['matchedSkills'] ?? []),
        missingSkills: List<String>.from(json['missingSkills'] ?? []),
        extractedInfo: json['extractedInfo'] ?? '',
        analysis: json['analysis'] ?? '',
        recommendation: json['recommendation'] ?? '',
      );
}

