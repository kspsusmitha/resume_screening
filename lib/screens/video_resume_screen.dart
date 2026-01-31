import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/storage_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class VideoResumeScreen extends StatefulWidget {
  const VideoResumeScreen({super.key});

  @override
  State<VideoResumeScreen> createState() => _VideoResumeScreenState();
}

class _VideoResumeScreenState extends State<VideoResumeScreen> {
  final _storageService = StorageService();
  bool _isRecording = false;
  bool _isUploading = false;
  bool _isUploadingFile = false;
  String? _recordedVideoPath;
  String? _uploadedVideoUrl;
  String? _selectedVideoPath;
  Uint8List? _selectedVideoBytes;
  VideoPlayerController? _videoPlayerController;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;
  bool _isCameraInitialized = false;
  Duration _recordingDuration = Duration.zero;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (kIsWeb) return;
    
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Find front camera (lensDirection.front) or use first available
        _currentCameraIndex = _cameras!.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
        if (_currentCameraIndex == -1) {
          _currentCameraIndex = 0; // Use back camera if front not available
        }
        
        _cameraController = CameraController(
          _cameras![_currentCameraIndex],
          ResolutionPreset.high,
          enableAudio: true,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera initialization failed: $e')),
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    if (kIsWeb || _cameras == null || _cameras!.isEmpty || _isRecording) return;
    
    if (_cameras!.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only one camera available')),
      );
      return;
    }

    try {
      setState(() {
        _isCameraInitialized = false;
      });

      // Dispose current camera
      await _cameraController?.dispose();

      // Switch to next camera
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;

      // Initialize new camera
      _cameraController = CameraController(
        _cameras![_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error switching camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error switching camera: $e')),
        );
        // Try to reinitialize with previous camera
        _currentCameraIndex = (_currentCameraIndex - 1) % _cameras!.length;
        await _initializeCamera();
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (kIsWeb) {
        // Video recording not supported on web due to browser limitations
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video recording is not supported on web. Please upload an existing video file.'),
          ),
        );
        return;
      } else {
        // For mobile/desktop, use camera controller
        if (_cameraController == null || !_isCameraInitialized) {
          await _initializeCamera();
        }
        
        if (_cameraController != null && _cameraController!.value.isInitialized) {
          await _cameraController!.startVideoRecording();
          
          setState(() {
            _isRecording = true;
            _recordingDuration = Duration.zero;
          });
          
          _updateRecordingDuration();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera not initialized. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }


  void _updateRecordingDuration() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
        _updateRecordingDuration();
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      if (kIsWeb) {
        // Should not reach here as recording is disabled on web
        setState(() {
          _isRecording = false;
        });
        return;
      } else {
        if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
          final file = await _cameraController!.stopVideoRecording();
          setState(() {
            _isRecording = false;
            _recordedVideoPath = file.path;
            // Auto-preview the recorded video
            _previewVideo();
          });
        }
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording stopped')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping recording: $e')),
      );
    }
  }

  /// Pick and upload video file from device
  Future<void> _pickAndUploadVideo() async {
    setState(() => _isUploadingFile = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        _selectedVideoPath = file.path;
        
        if (kIsWeb && file.bytes != null) {
          _selectedVideoBytes = file.bytes;
        }

        // Preview the video
        await _previewVideo();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video: $e')),
      );
    } finally {
      setState(() => _isUploadingFile = false);
    }
  }

  /// Preview selected/recorded video
  Future<void> _previewVideo() async {
    try {
      String? videoPath;
      
      if (_selectedVideoPath != null) {
        videoPath = _selectedVideoPath;
      } else if (_recordedVideoPath != null) {
        videoPath = _recordedVideoPath;
      }
      
      if (videoPath == null) return;
      
      if (kIsWeb && _selectedVideoBytes != null) {
        // For web, preview is limited - show message that upload is needed
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video selected. Upload to complete the process.'),
          ),
        );
        setState(() => _showPreview = false);
        return;
      } else {
        // Dispose previous controller
        await _videoPlayerController?.dispose();
        
        // Create new controller with recorded/selected video
        _videoPlayerController = VideoPlayerController.file(File(videoPath));
        await _videoPlayerController!.initialize();
        
        if (mounted) {
          setState(() {
            _showPreview = true;
          });
          // Auto-play the preview
          await _videoPlayerController!.play();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error previewing video: $e')),
      );
    }
  }

  /// Replace current video (clear and start over)
  void _replaceVideo() {
    setState(() {
      _recordedVideoPath = null;
      _selectedVideoPath = null;
      _selectedVideoBytes = null;
      _uploadedVideoUrl = null;
      _showPreview = false;
    });
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
  }

  /// Upload video to Firebase Storage
  Future<void> _uploadVideo() async {
    if (_recordedVideoPath == null && _selectedVideoPath == null && _selectedVideoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record or select a video first')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id ?? 'unknown';
      final fileName = 'video_resume_${DateTime.now().millisecondsSinceEpoch}.${kIsWeb ? 'webm' : 'mp4'}';

      String? downloadUrl;
      
      if (kIsWeb) {
        // For web, upload from bytes
        if (_selectedVideoBytes != null) {
          downloadUrl = await _storageService.uploadVideoFromBytes(
            userId: userId,
            bytes: _selectedVideoBytes!,
            fileName: fileName,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a video file for web')),
          );
          setState(() => _isUploading = false);
          return;
        }
      } else {
        // For mobile/desktop, upload from file path
        final videoPath = _selectedVideoPath ?? _recordedVideoPath;
        if (videoPath != null) {
          downloadUrl = await _storageService.uploadVideoResumeFromPath(
            userId: userId,
            filePath: videoPath,
            fileName: fileName,
          );
        }
      }

      setState(() {
        _isUploading = false;
        _uploadedVideoUrl = downloadUrl;
      });

      if (!mounted) return;

      if (downloadUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video uploaded successfully!'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload video')),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading video: $e')),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Video Resume',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (_recordedVideoPath != null || _selectedVideoPath != null || _uploadedVideoUrl != null)
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Replace'),
                            onPressed: _replaceVideo,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Video Preview or Camera Preview
                    if (_showPreview && _videoPlayerController != null && _videoPlayerController!.value.isInitialized) ...[
                      // Show recorded/uploaded video preview
                      AspectRatio(
                        aspectRatio: _videoPlayerController!.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_videoPlayerController!),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: VideoProgressIndicator(
                                _videoPlayerController!,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: AppTheme.accentColor,
                                  bufferedColor: Colors.grey,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _videoPlayerController!.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                size: 64,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_videoPlayerController!.value.isPlaying) {
                                    _videoPlayerController!.pause();
                                  } else {
                                    _videoPlayerController!.play();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (_uploadedVideoUrl != null) ...[
                        // Show uploaded video URL preview
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
                                const Icon(
                                  Icons.check_circle,
                                  size: 64,
                                  color: AppTheme.accentColor,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Video Uploaded Successfully!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'URL: ${_uploadedVideoUrl!.substring(0, _uploadedVideoUrl!.length > 50 ? 50 : _uploadedVideoUrl!.length)}...',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        // Show camera preview when no video preview
                        Container(
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade700),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: !kIsWeb && _isCameraInitialized && _cameraController != null
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Camera Preview - Always visible
                                        CameraPreview(_cameraController!),
                                        // Camera switch button
                                        if (!_isRecording)
                                          Positioned(
                                            top: 16,
                                            right: 16,
                                            child: IconButton(
                                              icon: Icon(
                                                _cameras != null && 
                                                _cameras![_currentCameraIndex].lensDirection == 
                                                CameraLensDirection.front
                                                    ? Icons.camera_rear
                                                    : Icons.camera_front,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                              onPressed: _switchCamera,
                                              style: IconButton.styleFrom(
                                                backgroundColor: Colors.black54,
                                                padding: const EdgeInsets.all(12),
                                              ),
                                            ),
                                          ),
                                        // Recording indicator overlay
                                        if (_isRecording)
                                          Positioned(
                                            top: 16,
                                            left: 16,
                                            right: 16,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.9),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Recording ${_formatDuration(_recordingDuration)}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        // Overlay when not recording
                                        if (!_isRecording && (_recordedVideoPath == null && _selectedVideoPath == null))
                                          Container(
                                            color: Colors.black26,
                                            child: const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.videocam,
                                                    size: 48,
                                                    color: Colors.white70,
                                                  ),
                                                  SizedBox(height: 12),
                                                  Text(
                                                    'Camera Ready',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    )
                                  : Center(
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
                                            kIsWeb
                                                ? 'Upload a video file to get started'
                                                : (_isRecording 
                                                    ? 'Recording... ${_formatDuration(_recordingDuration)}'
                                                    : 'Initializing camera...'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          ),
                                          if (!kIsWeb && !_isCameraInitialized) ...[
                                            const SizedBox(height: 8),
                                            const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                      // Action Buttons
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: kIsWeb ? null : (_isRecording ? null : _startRecording),
                              icon: const Icon(Icons.videocam),
                              label: Text(kIsWeb ? 'Record (N/A)' : 'Record'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kIsWeb ? Colors.grey : AppTheme.errorColor,
                                side: BorderSide(color: kIsWeb ? Colors.grey : AppTheme.errorColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUploadingFile ? null : _pickAndUploadVideo,
                              icon: _isUploadingFile
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload_file),
                              label: const Text('Upload'),
                            ),
                          ),
                        ],
                      ),
                      if (_isRecording) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _stopRecording,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop Recording'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                          ),
                        ),
                      ],
                      if ((_recordedVideoPath != null || _selectedVideoPath != null) && !_showPreview) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _previewVideo,
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Preview Video'),
                        ),
                      ],
                      if (_showPreview || _recordedVideoPath != null || _selectedVideoPath != null) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadVideo,
                          icon: _isUploading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cloud_upload),
                          label: Text(_isUploading ? 'Uploading...' : 'Upload to Cloud'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        kIsWeb 
                            ? 'Note: Due to browser limitations, video recording is not available on web. Please upload an existing video file.'
                            : 'Note: Record a new video or upload an existing one from your device.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

