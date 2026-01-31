import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/resume_provider.dart';
import '../providers/auth_provider.dart';
import '../services/ai_service.dart';
import '../models/resume_model.dart';
import 'resume_preview_screen.dart';

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
  String _selectedTemplate = 'template1';
  bool _isGeneratingSummary = false;
  bool _isSaving = false;
  
  // Available templates
  final List<Map<String, String>> _templates = [
    {'id': 'template1', 'name': 'Classic', 'description': 'Traditional and professional'},
    {'id': 'template2', 'name': 'Modern', 'description': 'Clean and contemporary'},
    {'id': 'template3', 'name': 'Creative', 'description': 'Bold and eye-catching'},
    {'id': 'template4', 'name': 'Professional', 'description': 'Clean single-column layout'},
  ];

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
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final resumeProvider =
        Provider.of<ResumeProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final personalInfo = PersonalInfo(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    final resume = Resume(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: authProvider.currentUser?.id ?? '',
      name: '${_nameController.text.trim()}_Resume',
      personalInfo: personalInfo,
      education: _education,
      experience: _experience,
      skills: _skills,
      summary: _summaryController.text.trim().isEmpty
          ? null
          : _summaryController.text.trim(),
      templateId: _selectedTemplate,
    );

    await resumeProvider.createResume(resume);

    setState(() => _isSaving = false);

    if (!mounted) return;
    
    // Navigate to preview screen instead of going back
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResumePreviewScreen(resume: resume),
      ),
    );
  }

  void _showAddEducationDialog() {
    final degreeController = TextEditingController();
    final institutionController = TextEditingController();
    final fieldController = TextEditingController();
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final gpaController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Education'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: degreeController,
                  decoration: const InputDecoration(
                    labelText: 'Degree *',
                    hintText: 'e.g., Bachelor of Science',
                  ),
                  validator: (value) => value?.isEmpty ?? true 
                      ? 'Please enter degree' 
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: institutionController,
                  decoration: const InputDecoration(
                    labelText: 'Institution *',
                    hintText: 'e.g., University Name',
                  ),
                  validator: (value) => value?.isEmpty ?? true 
                      ? 'Please enter institution' 
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: fieldController,
                  decoration: const InputDecoration(
                    labelText: 'Field of Study (Optional)',
                    hintText: 'e.g., Computer Science',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: startDateController,
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          hintText: 'e.g., 2020',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: endDateController,
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          hintText: 'e.g., 2024',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: gpaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'GPA (Optional)',
                    hintText: 'e.g., 3.8',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _education.add(Education(
                    degree: degreeController.text.trim(),
                    institution: institutionController.text.trim(),
                    field: fieldController.text.trim().isEmpty 
                        ? null 
                        : fieldController.text.trim(),
                    startDate: startDateController.text.trim().isEmpty 
                        ? null 
                        : startDateController.text.trim(),
                    endDate: endDateController.text.trim().isEmpty 
                        ? null 
                        : endDateController.text.trim(),
                    gpa: gpaController.text.trim().isEmpty 
                        ? null 
                        : double.tryParse(gpaController.text.trim()),
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddExperienceDialog() {
    final titleController = TextEditingController();
    final companyController = TextEditingController();
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final responsibilityController = TextEditingController();
    final responsibilities = <String>[];
    bool isCurrent = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Experience'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Job Title *',
                      hintText: 'e.g., Software Developer',
                    ),
                    validator: (value) => value?.isEmpty ?? true 
                        ? 'Please enter job title' 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company *',
                      hintText: 'e.g., Tech Company Inc.',
                    ),
                    validator: (value) => value?.isEmpty ?? true 
                        ? 'Please enter company name' 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: startDateController,
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            hintText: 'e.g., Jan 2020',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: endDateController,
                          enabled: !isCurrent,
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            hintText: 'e.g., Dec 2023',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Current Job'),
                    value: isCurrent,
                    onChanged: (value) {
                      setDialogState(() {
                        isCurrent = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Responsibilities:'),
                      TextButton.icon(
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('AI Elaborate'),
                        onPressed: () async {
                          if (responsibilityController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter keywords or phrases first'),
                              ),
                            );
                            return;
                          }
                          
                          try {
                            final elaborated = await _aiService.improveResumeBulletPoint(
                              responsibilityController.text.trim(),
                            );
                            setDialogState(() {
                              responsibilityController.text = elaborated;
                            });
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: responsibilityController,
                          decoration: const InputDecoration(
                            hintText: 'Enter keywords/phrases (use AI to elaborate)',
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              setDialogState(() {
                                responsibilities.add(value.trim());
                                responsibilityController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (responsibilityController.text.trim().isNotEmpty) {
                            setDialogState(() {
                              responsibilities.add(responsibilityController.text.trim());
                              responsibilityController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (responsibilities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...responsibilities.asMap().entries.map((entry) {
                      final index = entry.key;
                      final resp = entry.value;
                      return ListTile(
                        dense: true,
                        title: Text('• $resp'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () {
                            setDialogState(() {
                              responsibilities.removeAt(index);
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    _experience.add(Experience(
                      title: titleController.text.trim(),
                      company: companyController.text.trim(),
                      startDate: startDateController.text.trim().isEmpty 
                          ? null 
                          : startDateController.text.trim(),
                      endDate: endDateController.text.trim().isEmpty 
                          ? null 
                          : endDateController.text.trim(),
                      isCurrent: isCurrent,
                      responsibilities: responsibilities,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Builder'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveResume,
            icon: _isSaving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Template Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Template',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _templates.map((template) {
                          final isSelected = _selectedTemplate == template['id'];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTemplate = template['id']!;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected 
                                      ? Theme.of(context).primaryColor 
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: isSelected 
                                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    template['name']!,
                                    style: TextStyle(
                                      fontWeight: isSelected 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                      color: isSelected 
                                          ? Theme.of(context).primaryColor 
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    template['description']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
                            onPressed: () => _showAddEducationDialog(),
                          ),
                        ],
                      ),
                      if (_education.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No education added yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      else
                        ..._education.asMap().entries.map((entry) {
                          final index = entry.key;
                          final edu = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(edu.degree),
                              subtitle: Text('${edu.institution}${edu.field != null ? ' • ${edu.field}' : ''}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _education.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          );
                        }),
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
                            onPressed: () => _showAddExperienceDialog(),
                          ),
                        ],
                      ),
                      if (_experience.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No experience added yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      else
                        ..._experience.asMap().entries.map((entry) {
                          final index = entry.key;
                          final exp = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(exp.title),
                              subtitle: Text('${exp.company}${exp.startDate != null ? ' • ${exp.startDate}${exp.isCurrent ? " - Present" : exp.endDate != null ? " - ${exp.endDate}" : ""}' : ''}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _experience.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          );
                        }),
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

