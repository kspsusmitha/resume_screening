import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/storage_service.dart';

class UploadedResumePreviewScreen extends StatefulWidget {
  final String rtdbPath;
  final String fileName;

  const UploadedResumePreviewScreen({
    super.key,
    required this.rtdbPath,
    required this.fileName,
  });

  @override
  State<UploadedResumePreviewScreen> createState() =>
      _UploadedResumePreviewScreenState();
}

class _UploadedResumePreviewScreenState
    extends State<UploadedResumePreviewScreen> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkFileTypeAndLoad();
  }

  Future<void> _checkFileTypeAndLoad() async {
    final lowerName = widget.fileName.toLowerCase();
    if (!lowerName.endsWith('.pdf')) {
      setState(() {
        _errorMessage =
            'Preview not supported for this file type.\nOnly PDF files can be previewed.';
        _isLoading = false;
      });
      return;
    }
    await _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      print('DEBUG: Attempting to download resume from: ${widget.rtdbPath}');
      final result = await StorageService().downloadResumeFromRTDB(
        widget.rtdbPath,
      );

      if (result != null && result['bytes'] != null) {
        final bytes = result['bytes'] as Uint8List;
        print(
          'DEBUG: Resume downloaded successfully. Size: ${bytes.length} bytes',
        );

        // Check for PDF magic number (%PDF)
        if (bytes.length < 4 ||
            bytes[0] != 0x25 || // %
            bytes[1] != 0x50 || // P
            bytes[2] != 0x44 || // D
            bytes[3] != 0x46) // F
        {
          final header = bytes.length > 10
              ? String.fromCharCodes(bytes.sublist(0, 10))
              : String.fromCharCodes(bytes);
          print(
            'DEBUG: Invalid PDF header. Starts with: $header (Hex: ${bytes.sublist(0, 4)})',
          );

          if (mounted) {
            setState(() {
              _errorMessage =
                  'Invalid File Format.\nThe file does not appear to be a valid PDF.\n(Header: $header)';
              _isLoading = false;
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _pdfBytes = bytes;
            _isLoading = false;
          });
        }
      } else {
        print(
          'DEBUG: Download result is null or has no bytes. Result: $result',
        );
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load resume data from database.';
            _isLoading = false;
          });
        }
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error downloading/loading PDF: $e');
      print('DEBUG: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fileName)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (!widget.fileName.toLowerCase().endsWith('.pdf'))
                const Text(
                  'Please download the file to view it.',
                  style: TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _checkFileTypeAndLoad(); // Retry full check
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfBytes != null) {
      return Stack(
        children: [
          SfPdfViewer.memory(
            _pdfBytes!,
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              print('DEBUG: PdfViewer failed to load. Error: ${details.error}');
              print('DEBUG: PdfViewer description: ${details.description}');
              setState(() {
                _errorMessage =
                    'Failed to render PDF: ${details.error}\nDescription: ${details.description}';
              });
            },
          ),
          if (_pdfBytes!.isEmpty)
            const Center(child: Text('PDF file is empty (0 bytes).')),
        ],
      );
    }

    return const Center(child: Text('No PDF data found.'));
  }
}
