import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/resume_provider.dart';
import '../services/ai_service.dart';
import '../models/resume_model.dart';

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  final _aiService = AIService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _summaryController = TextEditingController();
  final _skillController = TextEditingController();
  final List<String> _skills = [];
  final List<Education> _education = [];
  final List<Experience> _experience = [];
  bool _isGeneratingSummary = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _summaryController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _generateSummary() async {
    if (_nameController.text.trim().isEmpty || _skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and skills first')),
      );
      return;
    }

    setState(() => _isGeneratingSummary = true);

    try {
      final experienceList = _experience.map((e) => e.title).toList();
      final educationText = _education.isNotEmpty
          ? _education.map((e) => e.degree).join(', ')
          : null;

      final summary = await _aiService.generateResumeSummary(
        name: _nameController.text.trim(),
        skills: _skills,
        experience: experienceList,
        education: educationText,
      );

      setState(() {
        _summaryController.text = summary;
        _isGeneratingSummary = false;
      });
    } catch (e) {
      setState(() => _isGeneratingSummary = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _addSkill() {
    if (_skillController.text.trim().isNotEmpty) {
      setState(() {
        _skills.add(_skillController.text.trim());
        _skillController.clear();
      });
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _skills.removeAt(index);
    });
  }

  Future<void> _saveResume() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final resumeProvider =
        Provider.of<ResumeProvider>(context, listen: false);

    final personalInfo = PersonalInfo(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    final resume = Resume(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // Will be from auth provider
      name: '${_nameController.text.trim()}_Resume',
      personalInfo: personalInfo,
      education: _education,
      experience: _experience,
      skills: _skills,
      summary: _summaryController.text.trim().isEmpty
          ? null
          : _summaryController.text.trim(),
    );

    await resumeProvider.createResume(resume);

    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resume saved successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveResume,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                        'Personal Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone (Optional)',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                            'Professional Summary',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton.icon(
                            onPressed: _isGeneratingSummary ? null : _generateSummary,
                            icon: _isGeneratingSummary
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('AI Generate'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _summaryController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Write a professional summary or use AI to generate one',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skills',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _skillController,
                              decoration: const InputDecoration(
                                labelText: 'Add Skill',
                                hintText: 'e.g., Flutter',
                              ),
                              onSubmitted: (_) => _addSkill(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addSkill,
                          ),
                        ],
                      ),
                      if (_skills.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_skills.length, (index) {
                            return Chip(
                              label: Text(_skills[index]),
                              onDeleted: () => _removeSkill(index),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                            'Education',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add'),
                            onPressed: () {
                              // Show dialog to add education
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Add education feature coming soon')),
                              );
                            },
                          ),
                        ],
                      ),
                      if (_education.isEmpty)
                        Text(
                          'No education added yet',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                            'Experience',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add'),
                            onPressed: () {
                              // Show dialog to add experience
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Add experience feature coming soon')),
                              );
                            },
                          ),
                        ],
                      ),
                      if (_experience.isEmpty)
                        Text(
                          'No experience added yet',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveResume,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Resume'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

