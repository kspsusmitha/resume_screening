import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/interview_provider.dart';
import '../providers/job_provider.dart';
import '../services/ai_service.dart';
import '../models/interview_model.dart';
import '../models/job_model.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_indicator.dart';

class InterviewPreparationScreen extends StatefulWidget {
  const InterviewPreparationScreen({super.key});

  @override
  State<InterviewPreparationScreen> createState() =>
      _InterviewPreparationScreenState();
}

class _InterviewPreparationScreenState
    extends State<InterviewPreparationScreen> {
  final _aiService = AIService();
  Job? _selectedJob;
  List<String> _questions = [];
  List<QuestionAnswer> _questionAnswers = [];
  int _currentQuestionIndex = 0;
  final _answerController = TextEditingController();
  bool _isGeneratingQuestions = false;
  bool _isEvaluating = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _generateQuestions() async {
    if (_selectedJob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job first')),
      );
      return;
    }

    setState(() {
      _isGeneratingQuestions = true;
      _questions = [];
      _questionAnswers = [];
      _currentQuestionIndex = 0;
    });

    try {
      final questions = await _aiService.generateInterviewQuestions(
        domain: _selectedJob!.domain,
        jobTitle: _selectedJob!.title,
        numberOfQuestions: 5,
      );

      setState(() {
        _questions = questions;
        _questionAnswers = questions.map((q) => QuestionAnswer(question: q)).toList();
        _isGeneratingQuestions = false;
      });
    } catch (e) {
      setState(() => _isGeneratingQuestions = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your answer')),
      );
      return;
    }

    setState(() => _isEvaluating = true);

    try {
      final evaluation = await _aiService.evaluateInterviewAnswer(
        question: _questions[_currentQuestionIndex],
        answer: _answerController.text.trim(),
        domain: _selectedJob?.domain ?? '',
      );

      setState(() {
        _questionAnswers[_currentQuestionIndex] = evaluation;
        _isEvaluating = false;
      });
    } catch (e) {
      setState(() => _isEvaluating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answerController.clear();
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _answerController.text =
            _questionAnswers[_currentQuestionIndex].answer ?? '';
      });
    }
  }

  Future<void> _finishSession() async {
    final avgScore = _questionAnswers
            .where((qa) => qa.score != null)
            .map((qa) => qa.score!)
            .fold(0.0, (sum, score) => sum + score) /
        _questionAnswers.where((qa) => qa.score != null).length;

    final session = InterviewSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      candidateId: '', // Will be set from auth provider
      jobId: _selectedJob?.id ?? '',
      domain: _selectedJob?.domain ?? '',
      questions: _questionAnswers,
      overallScore: avgScore,
      feedback: 'Great job! Keep practicing.',
    );

    final interviewProvider =
        Provider.of<InterviewProvider>(context, listen: false);
    await interviewProvider.createSession(session);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session completed! Average score: ${avgScore.toStringAsFixed(1)}%'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);
    final jobs = jobProvider.activeJobs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Interview Preparation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Job',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Job>(
                      value: _selectedJob,
                      decoration: const InputDecoration(
                        hintText: 'Choose a job for interview prep',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      items: jobs.map((job) {
                        return DropdownMenuItem(
                          value: job,
                          child: Text(job.title),
                        );
                      }).toList(),
                      onChanged: (job) {
                        setState(() {
                          _selectedJob = job;
                          _questions = [];
                          _questionAnswers = [];
                        });
                      },
                    ),
                    if (_selectedJob != null && _questions.isEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isGeneratingQuestions ? null : _generateQuestions,
                        child: _isGeneratingQuestions
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Generate Questions'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_isGeneratingQuestions) ...[
              const SizedBox(height: 24),
              const LoadingIndicator(message: 'Generating questions...'),
            ],
            if (_questions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (_questionAnswers[_currentQuestionIndex].score != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Score: ${_questionAnswers[_currentQuestionIndex].score!.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _questions[_currentQuestionIndex],
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _answerController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Your Answer',
                          hintText: 'Type your answer here...',
                        ),
                        enabled: _questionAnswers[_currentQuestionIndex].answer == null,
                      ),
                      if (_questionAnswers[_currentQuestionIndex].answer != null) ...[
                        const SizedBox(height: 16),
                        if (_questionAnswers[_currentQuestionIndex].feedback != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Feedback',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _questionAnswers[_currentQuestionIndex].feedback!,
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_questionAnswers[_currentQuestionIndex].strengths != null &&
                            _questionAnswers[_currentQuestionIndex].strengths!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Strengths',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._questionAnswers[_currentQuestionIndex]
                              .strengths!
                              .map((strength) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: AppTheme.accentColor, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(strength)),
                                      ],
                                    ),
                                  )),
                        ],
                        if (_questionAnswers[_currentQuestionIndex].improvements != null &&
                            _questionAnswers[_currentQuestionIndex].improvements!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Areas for Improvement',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._questionAnswers[_currentQuestionIndex]
                              .improvements!
                              .map((improvement) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info,
                                            color: AppTheme.warningColor, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(improvement)),
                                      ],
                                    ),
                                  )),
                        ],
                      ],
                      if (_questionAnswers[_currentQuestionIndex].answer == null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isEvaluating ? null : _submitAnswer,
                          child: _isEvaluating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Submit Answer'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousQuestion,
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                  if (_currentQuestionIndex < _questions.length - 1)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _questionAnswers[_currentQuestionIndex].answer != null
                            ? _nextQuestion
                            : null,
                        child: const Text('Next'),
                      ),
                    ),
                  if (_currentQuestionIndex == _questions.length - 1 &&
                      _questionAnswers[_currentQuestionIndex].answer != null) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _finishSession,
                        child: const Text('Finish Session'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

