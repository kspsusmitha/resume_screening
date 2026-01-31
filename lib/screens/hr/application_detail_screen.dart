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

class ApplicationDetailScreen extends StatelessWidget {
  final Application application;

  const ApplicationDetailScreen({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    final applicationProvider = Provider.of<ApplicationProvider>(context);
    final jobProvider = Provider.of<JobProvider>(context);
    final job = jobProvider.getJobById(application.jobId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.candidateName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(application.candidateEmail),
                    if (job != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Applied for:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(job.title),
                      Text('${job.domain} • ${job.location}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (application.matchPercentage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match Score',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: application.matchPercentage! / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          application.matchPercentage! >= 70
                              ? AppTheme.accentColor
                              : AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${application.matchPercentage!.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
            if (application.missingSkills != null &&
                application.missingSkills!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Missing Skills',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: application.missingSkills!.map((skill) {
                          return Chip(
                            label: Text(skill),
                            backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                          'Application Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (application.status == ApplicationStatus.shortlisted)
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => InterviewSchedulingDialog(
                                  candidateName: application.candidateName,
                                  onSchedule: ({
                                    required DateTime interviewDate,
                                    required String interviewTime,
                                    required String interviewerName,
                                    required String interviewLocation,
                                    String? interviewNotes,
                                  }) {
                                    applicationProvider.scheduleInterview(
                                      applicationId: application.id,
                                      interviewDate: interviewDate,
                                      interviewTime: interviewTime,
                                      interviewerName: interviewerName,
                                      interviewLocation: interviewLocation,
                                      interviewNotes: interviewNotes,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Interview scheduled for ${application.candidateName}',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: const Text('Schedule Interview'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
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
                        return FilterChip(
                          label: Text(status.toString().split('.').last),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              applicationProvider.updateApplicationStatus(
                                application.id,
                                status,
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            // Interview Details Card
            if (application.status == ApplicationStatus.interviewScheduled &&
                application.interviewDate != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.shade50.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Interview Scheduled',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InterviewDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Date',
                        value: DateFormat('EEEE, MMMM dd, yyyy')
                            .format(application.interviewDate!),
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
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CandidateCategory.values.map((category) {
                        final isSelected = application.category == category;
                        return FilterChip(
                          label: Text(category.toString().split('.').last),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              applicationProvider.updateApplicationCategory(
                                application.id,
                                category,
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            if (application.resumeText != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(application.resumeText!),
                    ],
                  ),
                ),
              ),
            ],
            if (application.videoResumePath != null && application.videoResumePath!.isNotEmpty) ...[
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
                            'Video Resume',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () async {
                              final url = Uri.parse(application.videoResumePath!);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            tooltip: 'Open in browser',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _VideoResumePlayer(videoUrl: application.videoResumePath!),
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
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
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
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('Unable to load video'),
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
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
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

