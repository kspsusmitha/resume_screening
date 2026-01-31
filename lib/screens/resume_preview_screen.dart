import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/resume_model.dart';
import '../services/pdf_service.dart';

class ResumePreviewScreen extends StatefulWidget {
  final Resume resume;

  const ResumePreviewScreen({super.key, required this.resume});

  @override
  State<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends State<ResumePreviewScreen> {
  bool _isDownloading = false;
  bool _isLoadingPDF = true;
  Uint8List? _pdfBytes;
  final PdfViewerController _pdfViewerController = PdfViewerController();

  Future<void> _downloadPDF() async {
    setState(() => _isDownloading = true);
    
    final pdfService = PDFService();
    final fileName = '${widget.resume.name}.pdf';
    
    try {
      if (kIsWeb) {
        await pdfService.downloadResumePDF(
          widget.resume,
          fileName,
          templateId: widget.resume.templateId,
        );
      } else {
        await pdfService.exportResumePDF(
          widget.resume,
          templateId: widget.resume.templateId,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb 
                  ? 'PDF download started!' 
                  : 'PDF exported successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _goToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPDF() async {
    setState(() => _isLoadingPDF = true);
    
    try {
      final pdfService = PDFService();
      _pdfBytes = await pdfService.generateResumePDF(
        widget.resume,
        templateId: widget.resume.templateId,
      );
      
      if (mounted) {
        setState(() => _isLoadingPDF = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPDF = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.resume.name),
      ),
      body: Column(
        children: [
          // Success Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.green.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Resume saved successfully! Preview your PDF below.',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // PDF Viewer
          Expanded(
            child: _isLoadingPDF
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generating PDF preview...'),
                      ],
                    ),
                  )
                : _pdfBytes == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            const Text('Failed to load PDF'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadPDF,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _pdfBytes != null
                        ? SfPdfViewer.memory(
                            _pdfBytes!,
                            controller: _pdfViewerController,
                            enableDoubleTapZooming: true,
                            enableTextSelection: true,
                          )
                        : const Center(child: Text('PDF not available')),
          ),
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadPDF,
                  icon: _isDownloading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(_isDownloading ? 'Downloading...' : 'Download PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _goToHome,
                        icon: const Icon(Icons.home),
                        label: const Text('Home'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
