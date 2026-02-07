import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/job_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/glass_container.dart';

class JobFormScreen extends StatefulWidget {
  final Job? job;
  final bool isCreating;

  const JobFormScreen({super.key, this.job, this.isCreating = false});

  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _domainController = TextEditingController();
  final _salaryController = TextEditingController();
  final _experienceController = TextEditingController();
  final _skillsController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      final job = widget.job!;
      _titleController.text = job.title;
      _descriptionController.text = job.description;
      _locationController.text = job.location;
      _domainController.text = job.domain;
      _salaryController.text = job.salaryRange ?? '';
      _experienceController.text = job.experienceLevel.toString();
      _skillsController.text = job.requiredSkills.join(', ');
      _isActive = job.isActive;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _domainController.dispose();
    _salaryController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final jobProvider = Provider.of<JobProvider>(context, listen: false);

    final skills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final job = Job(
      id: widget.job?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      requiredSkills: skills,
      experienceLevel: int.tryParse(_experienceController.text) ?? 0,
      salaryRange: _salaryController.text.trim().isEmpty
          ? null
          : _salaryController.text.trim(),
      location: _locationController.text.trim(),
      domain: _domainController.text.trim(),
      hrId: authProvider.currentUser?.id ?? '',
      hrName: authProvider.currentUser?.name ?? 'HR Manager',
      isActive: _isActive,
      // If we are editing, preserve status. If creating, set to false (pending) or true depending on requirements.
      // Usually new jobs might need approval or just be active. Assuming pending if admin approval needed.
      isApproved: widget.job?.isApproved ?? false,
    );

    if (widget.job != null) {
      await jobProvider.updateJob(job);
    } else {
      await jobProvider.createJob(job);
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.job != null
              ? 'Job updated successfully'
              : 'Job created successfully',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.job != null ? 'Edit Job' : 'Create Job',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1586281380349-632531db7ed4?q=80&w=2070&auto=format&fit=crop',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(color: AppTheme.backgroundColor);
              },
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: AppTheme.backgroundColor),
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.white.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
            ),
          ),
          // Form Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FadeInWidget(
                delay: const Duration(milliseconds: 100),
                child: GlassContainer(
                  opacity: 0.8,
                  blur: 15,
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Job Title *',
                            prefixIcon: const Icon(Icons.work_outline),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter job title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _domainController,
                          decoration: InputDecoration(
                            labelText: 'Domain *',
                            prefixIcon: const Icon(Icons.category),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter domain';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            labelText: 'Location *',
                            prefixIcon: const Icon(Icons.location_on),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter location';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _experienceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Exp (years) *',
                                  prefixIcon: const Icon(Icons.trending_up),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _salaryController,
                                decoration: InputDecoration(
                                  labelText: 'Salary (Opt)',
                                  prefixIcon: const Icon(Icons.attach_money),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _skillsController,
                          decoration: InputDecoration(
                            labelText: 'Required Skills *',
                            prefixIcon: const Icon(Icons.code),
                            helperText: 'e.g., Flutter, Dart, REST APIs',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter required skills';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            labelText: 'Job Description *',
                            prefixIcon: const Icon(Icons.description),
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter job description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SwitchListTile(
                          title: const Text(
                            'Job Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(_isActive ? 'Active' : 'Closed'),
                          value: _isActive,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    widget.job != null
                                        ? 'Update Job'
                                        : 'Create Job',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
