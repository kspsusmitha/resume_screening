import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/resume_screening_result.dart';
import '../models/interview_model.dart' show QuestionAnswer;

class AIService {
  static const String _apiKey = 'AIzaSyChcxUCymMoKzf9ckJNJMRgw_oAlTPnYCs';
  static const String _modelName = 'gemini-flash-lite-latest';

  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(model: _modelName, apiKey: _apiKey);
  }

  Future<String> generateText(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? '';
    } catch (e) {
      throw Exception('AI Service Error: $e');
    }
  }

  Future<ResumeScreeningResult> screenResume({
    required String resumeText,
    required String jobDescription,
    required List<String> requiredSkills,
  }) async {
    try {
      final prompt =
          '''
Analyze the following resume and job description, then provide a detailed screening result in JSON format.

Resume:
$resumeText

Job Description:
$jobDescription

Required Skills: ${requiredSkills.join(', ')}

Please provide a JSON response with the following structure:
{
  "matchPercentage": <number between 0-100>,
  "matchedSkills": [<array of skills found in resume>],
  "missingSkills": [<array of required skills not found in resume>],
  "extractedInfo": "<summary of candidate's education, experience, and key qualifications>",
  "analysis": "<detailed analysis of how well the resume matches the job requirements>",
  "recommendation": "<recommendation: SHORTLIST, REJECT, or REVIEW>"
}

Only return the JSON, no additional text.
''';

      final response = await generateText(prompt);

      // Try to extract JSON from response
      String jsonStr = response.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      final jsonData = json.decode(jsonStr) as Map<String, dynamic>;

      return ResumeScreeningResult.fromJson(jsonData);
    } catch (e) {
      // Fallback result if parsing fails
      return ResumeScreeningResult(
        matchPercentage: 0.0,
        matchedSkills: [],
        missingSkills: requiredSkills,
        extractedInfo: 'Error parsing resume: $e',
        analysis: 'Unable to analyze resume due to parsing error.',
        recommendation: 'REVIEW',
      );
    }
  }

  Future<String> generateResumeSummary({
    required String name,
    required List<String> skills,
    required List<String> experience,
    required String? education,
  }) async {
    final prompt =
        '''
Generate a professional resume summary (3-4 sentences) for a candidate with the following information:

Name: $name
Skills: ${skills.join(', ')}
Experience: ${experience.join('; ')}
Education: ${education ?? 'Not specified'}

IMPORTANT: Do NOT just list keywords. Instead, elaborate on each skill and experience:
- Expand each skill into a meaningful description of expertise
- Elaborate on experience with specific achievements and impact
- Create detailed, professional sentences that showcase depth of knowledge
- Use action verbs and quantify achievements where possible
- Make it ATS-friendly but also human-readable

Create an impactful, detailed professional summary that elaborates on qualifications rather than just listing them.
''';

    return await generateText(prompt);
  }

  Future<String> improveResumeBulletPoint(String bulletPoint) async {
    final prompt =
        '''
Transform the following resume bullet point into a detailed, professional description. 

If it contains only keywords or short phrases, ELABORATE them into full sentences:
- Expand keywords into meaningful descriptions
- Add context, impact, and achievements
- Use action verbs and quantify results where possible
- Make it ATS-friendly and impactful

Input: "$bulletPoint"

Return only the improved, elaborated bullet point (1-2 sentences), no additional text.
''';

    return await generateText(prompt);
  }

  Future<String> checkGrammarAndSpelling(String text) async {
    final prompt =
        '''
Check and correct the grammar and spelling in the following text. Return only the corrected text:

"$text"
''';

    return await generateText(prompt);
  }

  Future<String> generateVideoResumeScript({
    required String name,
    required String jobTitle,
    required List<String> keySkills,
    required String? experience,
  }) async {
    final prompt =
        '''
Generate a professional 60-90 second video resume script for a candidate applying for $jobTitle.

Candidate Name: $name
Key Skills: ${keySkills.join(', ')}
Experience: ${experience ?? 'Not specified'}

The script should:
- Start with a brief introduction
- Highlight key skills and experience relevant to the position
- Show enthusiasm and professionalism
- End with a strong closing statement

Return only the script text, formatted for easy reading.
''';

    return await generateText(prompt);
  }

  Future<List<String>> generateInterviewQuestions({
    required String domain,
    required String jobTitle,
    required int numberOfQuestions,
  }) async {
    final prompt =
        '''
Generate $numberOfQuestions interview questions for a $jobTitle position in the $domain domain.

Return the questions as a JSON array of strings:
["question1", "question2", "question3", ...]

Only return the JSON array, no additional text.
''';

    try {
      final response = await generateText(prompt);

      String jsonStr = response.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      final List<dynamic> questions = json.decode(jsonStr);
      return questions.map((q) => q.toString()).toList();
    } catch (e) {
      // Fallback questions
      return [
        'Tell me about yourself.',
        'Why are you interested in this position?',
        'What are your strengths?',
        'What are your weaknesses?',
        'Where do you see yourself in 5 years?',
      ];
    }
  }

  Future<QuestionAnswer> evaluateInterviewAnswer({
    required String question,
    required String answer,
    required String domain,
  }) async {
    final prompt =
        '''
Evaluate the following interview answer and provide detailed feedback in JSON format.

Question: $question
Answer: $answer
Domain: $domain

Provide a JSON response with this structure:
{
  "score": <number between 0-100>,
  "feedback": "<detailed feedback on the answer>",
  "strengths": [<array of strengths in the answer>],
  "improvements": [<array of areas for improvement>]
}

Only return the JSON, no additional text.
''';

    try {
      final response = await generateText(prompt);

      String jsonStr = response.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      final jsonData = json.decode(jsonStr) as Map<String, dynamic>;

      return QuestionAnswer(
        question: question,
        answer: answer,
        score: jsonData['score']?.toDouble(),
        feedback: jsonData['feedback'],
        strengths: jsonData['strengths'] != null
            ? List<String>.from(jsonData['strengths'])
            : null,
        improvements: jsonData['improvements'] != null
            ? List<String>.from(jsonData['improvements'])
            : null,
      );
    } catch (e) {
      return QuestionAnswer(
        question: question,
        answer: answer,
        score: 50.0,
        feedback: 'Unable to evaluate answer: $e',
        strengths: [],
        improvements: ['Please provide a more detailed answer.'],
      );
    }
  }

  Future<Map<String, String>> generateLinkedInStyleProfile({
    required String fullName,
    required String currentRole,
    required String experienceLevel,
    required List<String> topSkills,
    required String educationSummary,
    required String industry,
    String? careerGoal,
  }) async {
    final prompt =
        '''
You are creating a LinkedIn-style professional profile from minimal data.

USER INPUT:
- Name: $fullName
- Current Role: $currentRole
- Experience Level: $experienceLevel
- Top Skills: ${topSkills.join(', ')}
- Education: $educationSummary
- Industry / Domain: $industry
- Career Goal: ${careerGoal ?? 'Not specified'}

TASK:
1. Create a short LINKEDIN HEADLINE (max 120 characters).
2. Create an ABOUT / SUMMARY section (2–3 short paragraphs).
3. Create a CURRENT EXPERIENCE section with 3–5 bullet points.
   - Use only the given info (do NOT invent company names if not provided).
   - Use action verbs and measurable impact where reasonable.
4. Create a SKILLS section as a comma-separated list, expanding the keywords into professional-looking skill names.

RESPONSE FORMAT (STRICT JSON, no extra text):

{
  "headline": "...",
  "summary": "...",
  "experience": "...",
  "skills": "..."
}
''';

    final raw = await generateText(prompt);

    String jsonStr = raw.trim();
    if (jsonStr.startsWith('```json')) {
      jsonStr = jsonStr.substring(7);
    }
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.substring(3);
    }
    if (jsonStr.endsWith('```')) {
      jsonStr = jsonStr.substring(0, jsonStr.length - 3);
    }
    jsonStr = jsonStr.trim();

    final data = json.decode(jsonStr) as Map<String, dynamic>;
    return {
      'headline': data['headline']?.toString() ?? '',
      'summary': data['summary']?.toString() ?? '',
      'experience': data['experience']?.toString() ?? '',
      'skills': data['skills']?.toString() ?? '',
    };
  }
}
