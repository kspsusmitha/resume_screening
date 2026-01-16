import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_indicator.dart';

class VideoResumeScreen extends StatefulWidget {
  const VideoResumeScreen({super.key});

  @override
  State<VideoResumeScreen> createState() => _VideoResumeScreenState();
}

class _VideoResumeScreenState extends State<VideoResumeScreen> {
  final _aiService = AIService();
  final _jobTitleController = TextEditingController();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();
  String? _script;
  bool _isGenerating = false;
  bool _isRecording = false;

  @override
  void dispose() {
    _jobTitleController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _generateScript() async {
    if (_jobTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter job title')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _script = null;
    });

    try {
      final skills = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final script = await _aiService.generateVideoResumeScript(
        name: 'Candidate', // Will be from auth provider
        jobTitle: _jobTitleController.text.trim(),
        keySkills: skills,
        experience: _experienceController.text.trim().isEmpty
            ? null
            : _experienceController.text.trim(),
      );

      setState(() {
        _script = script;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _startRecording() async {
    // In a real app, this would initialize camera and start recording
    setState(() => _isRecording = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recording started (Camera integration needed)')),
    );
  }

  void _stopRecording() {
    setState(() => _isRecording = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recording stopped')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Resume'),
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
                      'Job Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _jobTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Job Title *',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _skillsController,
                      decoration: const InputDecoration(
                        labelText: 'Key Skills (comma-separated)',
                        prefixIcon: Icon(Icons.code),
                        helperText: 'e.g., Flutter, Dart, UI/UX',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _experienceController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Experience Summary (Optional)',
                        prefixIcon: Icon(Icons.business_center),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isGenerating ? null : _generateScript,
                      child: _isGenerating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Generate Script'),
                    ),
                  ],
                ),
              ),
            ),
            if (_isGenerating) ...[
              const SizedBox(height: 24),
              const LoadingIndicator(message: 'Generating script...'),
            ],
            if (_script != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'AI-Generated Script',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              // Copy to clipboard
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Script copied!')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _script!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Record Video Resume',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isRecording ? Icons.videocam : Icons.videocam_off,
                                size: 64,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isRecording ? 'Recording...' : 'Ready to Record',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_isRecording)
                            ElevatedButton.icon(
                              onPressed: _startRecording,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Recording'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorColor,
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _stopRecording,
                              icon: const Icon(Icons.stop),
                              label: const Text('Stop Recording'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Note: Camera integration required for actual recording',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

