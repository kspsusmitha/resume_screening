import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../providers/application_provider.dart';
import '../../providers/job_provider.dart';
import '../../models/application_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interview_scheduling_dialog.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/fade_in_widget.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../../services/storage_service.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final Application application;

  const ApplicationDetailScreen({super.key, required this.application});

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final applicationProvider = Provider.of<ApplicationProvider>(context);
    final jobProvider = Provider.of<JobProvider>(context);

    // Bug Fix: Get the latest application state from provider using ID
    final application =
        applicationProvider.getApplicationById(widget.application.id) ??
        widget.application;
    final job = jobProvider.getJobById(application.jobId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Application Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1497215728101-856f4ea42174?q=80&w=2070&auto=format&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFF1F2937)),
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
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card (Candidate Info)
                  FadeInWidget(
                    child: GlassContainer(
                      opacity: 0.2,
                      blur: 15,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Text(
                                  application.candidateName.isNotEmpty
                                      ? application.candidateName[0]
                                            .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      application.candidateName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      application.candidateEmail,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (job != null) ...[
                            const SizedBox(height: 16),
                            Divider(color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'Applied for:',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              job.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${job.domain} • ${job.location}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Match Score
                  if (application.matchPercentage != null)
                    FadeInWidget(
                      delay: const Duration(milliseconds: 100),
                      child: GlassContainer(
                        opacity: 0.2,
                        blur: 15,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Match Score',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: application.matchPercentage! / 100,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  application.matchPercentage! >= 70
                                      ? AppTheme.accentColor
                                      : AppTheme.warningColor,
                                ),
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${application.matchPercentage!.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Missing Skills
                  if (application.missingSkills != null &&
                      application.missingSkills!.isNotEmpty)
                    FadeInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: GlassContainer(
                        opacity: 0.2,
                        blur: 15,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Missing Skills',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: application.missingSkills!.map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.errorColor.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    skill,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Application Status & Actions
                  FadeInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: GlassContainer(
                      opacity: 0.2,
                      blur: 15,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Application Status',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (application.status ==
                                  ApplicationStatus.shortlisted)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          InterviewSchedulingDialog(
                                            candidateName:
                                                application.candidateName,
                                            onSchedule:
                                                ({
                                                  required DateTime
                                                  interviewDate,
                                                  required String interviewTime,
                                                  required String
                                                  interviewerName,
                                                  required String
                                                  interviewLocation,
                                                  String? interviewNotes,
                                                }) {
                                                  applicationProvider
                                                      .scheduleInterview(
                                                        applicationId:
                                                            application.id,
                                                        interviewDate:
                                                            interviewDate,
                                                        interviewTime:
                                                            interviewTime,
                                                        interviewerName:
                                                            interviewerName,
                                                        interviewLocation:
                                                            interviewLocation,
                                                        interviewNotes:
                                                            interviewNotes,
                                                      );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Interview scheduled for ${application.candidateName}',
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );
                                                },
                                          ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                  ),
                                  label: const Text('Schedule Interview'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ApplicationStatus.values.map((status) {
                              final isSelected = application.status == status;
                              return ChoiceChip(
                                label: Text(
                                  status.toString().split('.').last,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black, // Black for visibility
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    applicationProvider.updateApplicationStatus(
                                      application.id,
                                      status,
                                    );
                                  }
                                },
                                selectedColor: AppTheme.primaryColor,
                                backgroundColor: isSelected
                                    ? null
                                    : Colors.white.withOpacity(
                                        0.9,
                                      ), // More opaque white for contrast
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.transparent,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Interview Details
                  if (application.interviewDate != null)
                    FadeInWidget(
                      delay: const Duration(milliseconds: 400),
                      child: GlassContainer(
                        opacity: 0.2,
                        blur: 15,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 16),
                        border: Border.all(
                          color: AppTheme.accentColor.withOpacity(0.5),
                          width: 1.5,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event_available,
                                  color: AppTheme.accentColor,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Interview Scheduled',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _InterviewDetailRow(
                              icon: Icons.calendar_today,
                              label: 'Date',
                              value: DateFormat(
                                'EEEE, MMMM dd, yyyy',
                              ).format(application.interviewDate!),
                            ),
                            if (application.interviewTime != null) ...[
                              const SizedBox(height: 12),
                              _InterviewDetailRow(
                                icon: Icons.access_time,
                                label: 'Time',
                                value: application.interviewTime!,
                              ),
                            ],
                            if (application.interviewerName != null) ...[
                              const SizedBox(height: 12),
                              _InterviewDetailRow(
                                icon: Icons.person,
                                label: 'Interviewer',
                                value: application.interviewerName!,
                              ),
                            ],
                            if (application.interviewLocation != null) ...[
                              const SizedBox(height: 12),
                              _InterviewDetailRow(
                                icon: Icons.location_on,
                                label: 'Location',
                                value: application.interviewLocation!,
                              ),
                            ],
                            if (application.interviewNotes != null &&
                                application.interviewNotes!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _InterviewDetailRow(
                                icon: Icons.note,
                                label: 'Notes',
                                value: application.interviewNotes!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  // Category Selection
                  FadeInWidget(
                    delay: const Duration(milliseconds: 500),
                    child: GlassContainer(
                      opacity: 0.2,
                      blur: 15,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: CandidateCategory.values.map((category) {
                              final isSelected =
                                  application.category == category;
                              return ChoiceChip(
                                label: Text(
                                  category.toString().split('.').last,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black, // Black for visibility
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    applicationProvider
                                        .updateApplicationCategory(
                                          application.id,
                                          category,
                                        );
                                  }
                                },
                                selectedColor: AppTheme.secondaryColor,
                                backgroundColor: isSelected
                                    ? null
                                    : Colors.white.withOpacity(
                                        0.9,
                                      ), // More opaque black/white contrast
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppTheme.secondaryColor
                                        : Colors.transparent,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Resume Text
                  if (application.resumeText != null)
                    FadeInWidget(
                      delay: const Duration(milliseconds: 600),
                      child: GlassContainer(
                        opacity: 0.2,
                        blur: 15,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Resume Content',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (application.resumePath != null)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.download,
                                      color: Colors.white,
                                    ),
                                    tooltip: 'Download Resume',
                                    onPressed: () => _downloadResume(
                                      context,
                                      application.resumePath!,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                application.resumeText!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Video Resume
                  if (application.videoResumePath != null &&
                      application.videoResumePath!.isNotEmpty)
                    FadeInWidget(
                      delay: const Duration(milliseconds: 700),
                      child: GlassContainer(
                        opacity: 0.2,
                        blur: 15,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Video Resume',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.open_in_new,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    final url = Uri.parse(
                                      application.videoResumePath!,
                                    );
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                  tooltip: 'Open in browser',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _VideoResumePlayer(
                                videoUrl: application.videoResumePath!,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadResume(BuildContext context, String resumePath) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Downloading resume...')));

      final result = await StorageService().downloadFile(resumePath);

      if (result == null) {
        throw Exception('Download failed');
      }

      if (result is String) {
        final url = Uri.parse(result);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch URL');
        }
      } else if (result is Map) {
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Web download for RTDB not implemented'),
            ),
          );
          return;
        }

        final bytes = result['bytes'] as Uint8List;
        final fileName = result['fileName'] as String;

        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _InterviewDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InterviewDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Video player widget for viewing video resumes
class _VideoResumePlayer extends StatefulWidget {
  final String videoUrl;

  const _VideoResumePlayer({required this.videoUrl});

  @override
  State<_VideoResumePlayer> createState() => _VideoResumePlayerState();
}

class _VideoResumePlayerState extends State<_VideoResumePlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unable to load video',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(widget.videoUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in Browser'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller!),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppTheme.accentColor,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
          if (!_controller!.value.isPlaying)
            IconButton(
              icon: const Icon(
                Icons.play_circle_filled,
                size: 64,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _controller!.play();
                });
              },
            ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
