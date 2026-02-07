import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../models/job_model.dart';
import '../../models/application_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/glass_container.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isApplying = false;
  bool _hasApplied = false;
  final _storageService = StorageService();

  PlatformFile? _pickedFile;
  Map<String, dynamic>? _selectedStoredResume;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkApplicationStatus(),
    );
  }

  void _checkApplicationStatus() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final applicationProvider = Provider.of<ApplicationProvider>(
      context,
      listen: false,
    );
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      final hasApplied = applicationProvider.hasAppliedForJob(
        widget.job.id,
        userId,
      );
      if (mounted) {
        setState(() {
          _hasApplied = hasApplied;
        });
      }
    }
  }

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.single;
          _selectedStoredResume = null; // Clear duplicate selection
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking resume: $e')));
    }
  }

  Future<void> _selectFromMyResumes() async {
    final userId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.id;
    if (userId == null) return;

    try {
      // Show loading indicator or get resumes
      final resumes = await _storageService.getUserResumesFromRTDB(userId);

      if (!mounted) return;

      if (resumes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No uploaded resumes found. Please upload one first.',
            ),
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select from My Resumes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: resumes.length,
                    itemBuilder: (context, index) {
                      final resume = resumes[index];
                      final fileName = resume['fileName'] ?? 'Unknown';

                      return ListTile(
                        leading: const Icon(
                          Icons.description,
                          color: AppTheme.primaryColor,
                        ),
                        title: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Uploaded: ${resume['uploadedAt'] ?? ''}',
                        ),
                        onTap: () {
                          setState(() {
                            _selectedStoredResume = resume;
                            _pickedFile = null; // Clear local file pick
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _applyForJob() async {
    if (_pickedFile == null && _selectedStoredResume == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload or select a resume')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final applicationProvider = Provider.of<ApplicationProvider>(
      context,
      listen: false,
    );

    setState(() => _isApplying = true);

    try {
      final userId = authProvider.currentUser?.id ?? 'unknown';
      String? resumeUrl;
      String resumeText = '';

      if (_pickedFile != null) {
        // Process local file upload
        final file = _pickedFile!;
        resumeText = file.name;
        final userName = authProvider.currentUser?.name ?? 'Unknown_User';
        final fileName =
            'resume_${DateTime.now().millisecondsSinceEpoch}.${file.extension ?? 'pdf'}';

        if (kIsWeb) {
          if (file.bytes != null) {
            resumeUrl = await _storageService.uploadResumeToRTDB(
              userId: userId,
              userName: userName,
              bytes: file.bytes!,
              fileName: fileName,
            );
          }
        } else {
          if (file.path != null) {
            resumeUrl = await _storageService.uploadResumeToRTDBFromPath(
              userId: userId,
              userName: userName,
              filePath: file.path!,
              fileName: fileName,
            );
          }
        }
      } else if (_selectedStoredResume != null) {
        // Use existing stored resume
        resumeText = _selectedStoredResume!['fileName'];
        resumeUrl = 'rtdb://resumes/$userId/${_selectedStoredResume!['id']}';
      }

      if (resumeUrl == null) {
        throw Exception('Failed to process resume.');
      }

      final application = Application(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        jobId: widget.job.id,
        candidateId: authProvider.currentUser?.id ?? '',
        candidateName: authProvider.currentUser?.name ?? 'Candidate',
        candidateEmail: authProvider.currentUser?.email ?? '',
        resumePath: resumeUrl,
        resumeText: resumeText,
        status: ApplicationStatus.applied,
      );

      await applicationProvider.createApplication(application);

      if (!mounted) return;

      setState(() {
        _hasApplied = true;
        _isApplying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      print('Error applying: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;
      setState(() => _isApplying = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error applying: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Job Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1497215728101-856f4ea42174?q=80&w=2070&auto=format&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1F2937), // Dark grey fallback
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),

          Column(
            children: [
              SizedBox(
                height: kToolbarHeight + MediaQuery.of(context).padding.top,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Text(
                        widget.job.title,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            color: Colors.white.withOpacity(0.9),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.job.domain} • ${widget.job.location}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                          ),
                        ],
                      ),
                      if (widget.job.salaryRange != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            widget.job.salaryRange!,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Description Section
                      GlassContainer(
                        opacity: 0.8,
                        blur: 10,
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.description_outlined,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Job Description',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.job.description,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    height: 1.6,
                                    color: Colors.black87,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Requirements Section
                      GlassContainer(
                        opacity: 0.8,
                        blur: 10,
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.list_alt,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Requirements',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Updated to remove _buildRequirementItem helper call and inline it or define it
                            Row(
                              children: [
                                Icon(
                                  Icons.work_history_outlined,
                                  size: 20,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Experience',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    Text(
                                      '${widget.job.experienceLevel} years',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Required Skills',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.job.requiredSkills.map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    skill,
                                    style: TextStyle(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.9,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // HR Info
                      GlassContainer(
                        opacity: 0.8,
                        blur: 10,
                        padding: const EdgeInsets.all(16),
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryColor
                                  .withOpacity(0.1),
                              child: Text(
                                widget.job.hrName.isNotEmpty
                                    ? widget.job.hrName[0].toUpperCase()
                                    : 'H',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Posted by',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  widget.job.hrName,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassContainer(
              opacity: 0.95,
              blur: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hasApplied)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Already Applied',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      if (_pickedFile == null &&
                          _selectedStoredResume == null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.upload_file,
                                label: 'Upload New',
                                onTap: _pickResume,
                                isOutlined: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.history,
                                label: 'Select Saved',
                                onTap: _selectFromMyResumes,
                                isOutlined: true,
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.description,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selected Resume',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _pickedFile?.name ??
                                          _selectedStoredResume?['fileName'] ??
                                          'Resume',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _pickedFile = null;
                                    _selectedStoredResume = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                      if (_pickedFile != null || _selectedStoredResume != null)
                        Container(
                          width: double.infinity,
                          height: 54,
                          margin: const EdgeInsets.only(top: 16),
                          child: ElevatedButton(
                            onPressed: _isApplying ? null : _applyForJob,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppTheme.primaryColor.withOpacity(
                                0.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isApplying
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Submit Application',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            border: isOutlined
                ? Border.all(color: Colors.grey.withOpacity(0.3))
                : null,
            borderRadius: BorderRadius.circular(16),
            color: isOutlined ? Colors.transparent : AppTheme.primaryColor,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: isOutlined ? AppTheme.primaryColor : Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isOutlined ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
