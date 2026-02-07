import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/interview_provider.dart';
import '../providers/job_provider.dart';
import '../services/ai_service.dart';
import '../models/interview_model.dart';
import '../models/job_model.dart';
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
  String _selectedCategory = 'Technical';
  final List<String> _categories = [
    'Technical',
    'Behavioral',
    'Situational',
    'HR',
    'Coding',
  ];

  List<String> _questions = [];
  List<QuestionAnswer> _questionAnswers = [];
  int _currentQuestionIndex = 0;
  final _answerController = TextEditingController();

  bool _isGeneratingQuestions = false;
  bool _isEvaluating = false;
  bool _isFetchingHint = false;
  String? _currentHint;

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
      _currentHint = null; // Reset hint
    });

    try {
      final questions = await _aiService.generateInterviewQuestions(
        domain: _selectedJob!.domain,
        jobTitle: _selectedJob!.title,
        numberOfQuestions: 5,
        category: _selectedCategory,
      );

      setState(() {
        _questions = questions;
        _questionAnswers = questions
            .map((q) => QuestionAnswer(question: q))
            .toList();
        _isGeneratingQuestions = false;
      });
    } catch (e) {
      setState(() => _isGeneratingQuestions = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _getHint() async {
    setState(() => _isFetchingHint = true);
    try {
      final hint = await _aiService.generateQuestionHint(
        question: _questions[_currentQuestionIndex],
        jobTitle: _selectedJob?.title ?? '',
        domain: _selectedJob?.domain ?? '',
      );
      setState(() {
        _currentHint = hint;
        _isFetchingHint = false;
      });
    } catch (e) {
      setState(() => _isFetchingHint = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not get hint: $e')));
    }
  }

  Future<void> _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your answer')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answerController.clear();
        _currentHint = null;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _answerController.text =
            _questionAnswers[_currentQuestionIndex].answer ?? '';
        _currentHint = null; // Hide hint when going back for clarity
      });
    }
  }

  Future<void> _finishSession() async {
    final avgScore =
        _questionAnswers
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

    final interviewProvider = Provider.of<InterviewProvider>(
      context,
      listen: false,
    );
    await interviewProvider.createSession(session);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Session completed! Average score: ${avgScore.toStringAsFixed(1)}%',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);
    final jobs = jobProvider.activeJobs;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Interview Prep')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Setup',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<Job>(
                      value: _selectedJob,
                      decoration: InputDecoration(
                        labelText: 'Select Job Role',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.work_outline),
                      ),
                      items: jobs.map((job) {
                        return DropdownMenuItem(
                          value: job,
                          child: Text(
                            job.title,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                    const SizedBox(height: 20),
                    Text(
                      'Interview Focus',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        return ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = category;
                                _questions = []; // Reset if category changes
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed:
                            (_selectedJob != null && !_isGeneratingQuestions)
                            ? _generateQuestions
                            : null,
                        child: _isGeneratingQuestions
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Start Interview Session'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isGeneratingQuestions) ...[
              const SizedBox(height: 32),
              const Center(
                child: LoadingIndicator(
                  message: 'AI is preparing your interview...',
                ),
              ),
            ],
            if (_questions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_questionAnswers[_currentQuestionIndex].score !=
                              null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_questionAnswers[_currentQuestionIndex].score!.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _questions[_currentQuestionIndex],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),

                      // HINT SECTION
                      const SizedBox(height: 12),
                      if (_currentHint == null &&
                          _questionAnswers[_currentQuestionIndex].answer ==
                              null)
                        TextButton.icon(
                          onPressed: _isFetchingHint ? null : _getHint,
                          icon: _isFetchingHint
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lightbulb_outline, size: 18),
                          label: const Text('Need a Hint?'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.amber[800],
                          ),
                        ),
                      if (_currentHint != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Colors.amber[800],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _currentHint!,
                                  style: TextStyle(
                                    color: Colors.amber[900],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),
                      TextField(
                        controller: _answerController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Type your answer here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        enabled:
                            _questionAnswers[_currentQuestionIndex].answer ==
                            null,
                      ),

                      // FEEDBACK SECTION
                      if (_questionAnswers[_currentQuestionIndex].answer !=
                          null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.assessment,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI Feedback',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                _questionAnswers[_currentQuestionIndex]
                                        .feedback ??
                                    'No feedback generated.',
                                style: const TextStyle(height: 1.5),
                              ),

                              if (_questionAnswers[_currentQuestionIndex]
                                      .strengths
                                      ?.isNotEmpty ??
                                  false) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Strengths:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._questionAnswers[_currentQuestionIndex]
                                    .strengths!
                                    .map(
                                      (s) => Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(s)),
                                        ],
                                      ),
                                    ),
                              ],

                              if (_questionAnswers[_currentQuestionIndex]
                                      .improvements
                                      ?.isNotEmpty ??
                                  false) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'To Improve:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._questionAnswers[_currentQuestionIndex]
                                    .improvements!
                                    .map(
                                      (s) => Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.arrow_upward,
                                            size: 16,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(s)),
                                        ],
                                      ),
                                    ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (_questionAnswers[_currentQuestionIndex].answer ==
                          null) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isEvaluating ? null : _submitAnswer,
                            child: _isEvaluating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Submit Answer'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentQuestionIndex > 0)
                    OutlinedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    )
                  else
                    const SizedBox(), // Spacer

                  if (_currentQuestionIndex < _questions.length - 1)
                    ElevatedButton.icon(
                      onPressed:
                          _questionAnswers[_currentQuestionIndex].answer != null
                          ? _nextQuestion
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    ),

                  if (_currentQuestionIndex == _questions.length - 1 &&
                      _questionAnswers[_currentQuestionIndex].answer != null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _finishSession,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Finish Session'),
                    ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }
}
