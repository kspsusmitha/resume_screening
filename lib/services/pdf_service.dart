import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/resume_model.dart';

class PDFService {
  /// Generate PDF from Resume model with template support
  Future<Uint8List> generateResumePDF(Resume resume, {String? templateId}) async {
    final template = templateId ?? resume.templateId;
    
    switch (template) {
      case 'template2':
        return _generateModernTemplate(resume);
      case 'template3':
        return _generateCreativeTemplate(resume);
      case 'template4':
        return _generateProfessionalTemplate(resume);
      default:
        return _generateClassicTemplate(resume);
    }
  }

  /// Classic Template (Template 1)
  Future<Uint8List> _generateClassicTemplate(Resume resume) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(resume.personalInfo),
            pw.SizedBox(height: 20),
            
            // Professional Summary
            if (resume.summary != null && resume.summary!.isNotEmpty) ...[
              _buildSectionTitle('Professional Summary'),
              pw.SizedBox(height: 8),
              _buildParagraph(resume.summary!),
              pw.SizedBox(height: 20),
            ],
            
            // Skills
            if (resume.skills.isNotEmpty) ...[
              _buildSectionTitle('Skills'),
              pw.SizedBox(height: 8),
              _buildSkills(resume.skills),
              pw.SizedBox(height: 20),
            ],
            
            // Experience
            if (resume.experience.isNotEmpty) ...[
              _buildSectionTitle('Experience'),
              pw.SizedBox(height: 8),
              ...resume.experience.map((exp) => _buildExperience(exp)),
              pw.SizedBox(height: 20),
            ],
            
            // Education
            if (resume.education.isNotEmpty) ...[
              _buildSectionTitle('Education'),
              pw.SizedBox(height: 8),
              ...resume.education.map((edu) => _buildEducation(edu)),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Export PDF and show print/share dialog
  Future<void> exportResumePDF(Resume resume, {String? templateId}) async {
    final pdfBytes = await generateResumePDF(resume, templateId: templateId);
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  /// Download PDF (for web)
  Future<void> downloadResumePDF(Resume resume, String fileName, {String? templateId}) async {
    final pdfBytes = await generateResumePDF(resume, templateId: templateId);
    
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
    );
  }

  /// Modern Template (Template 2) - Clean and contemporary
  Future<Uint8List> _generateModernTemplate(Resume resume) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            // Modern Header with colored bar
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue700,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    resume.personalInfo.fullName,
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Text(
                        resume.personalInfo.email,
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                      ),
                      if (resume.personalInfo.phone != null) ...[
                        pw.Text(' • ', style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                        pw.Text(
                          resume.personalInfo.phone!,
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Professional Summary
            if (resume.summary != null && resume.summary!.isNotEmpty) ...[
              _buildModernSectionTitle('PROFESSIONAL SUMMARY'),
              pw.SizedBox(height: 8),
              _buildParagraph(resume.summary!),
              pw.SizedBox(height: 20),
            ],
            
            // Skills
            if (resume.skills.isNotEmpty) ...[
              _buildModernSectionTitle('SKILLS'),
              pw.SizedBox(height: 8),
              _buildSkills(resume.skills),
              pw.SizedBox(height: 20),
            ],
            
            // Experience
            if (resume.experience.isNotEmpty) ...[
              _buildModernSectionTitle('EXPERIENCE'),
              pw.SizedBox(height: 8),
              ...resume.experience.map((exp) => _buildExperience(exp)),
              pw.SizedBox(height: 20),
            ],
            
            // Education
            if (resume.education.isNotEmpty) ...[
              _buildModernSectionTitle('EDUCATION'),
              pw.SizedBox(height: 8),
              ...resume.education.map((edu) => _buildEducation(edu)),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Creative Template (Template 3) - Bold and eye-catching
  Future<Uint8List> _generateCreativeTemplate(Resume resume) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(25),
        build: (pw.Context context) {
          return [
            // Creative Header with side bar
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 5,
                  height: 100,
                  color: PdfColors.red700,
                ),
                pw.SizedBox(width: 15),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        resume.personalInfo.fullName,
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        resume.personalInfo.email,
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                      if (resume.personalInfo.phone != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          resume.personalInfo.phone!,
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 25),
            
            // Professional Summary
            if (resume.summary != null && resume.summary!.isNotEmpty) ...[
              _buildCreativeSectionTitle('PROFESSIONAL SUMMARY'),
              pw.SizedBox(height: 10),
              _buildParagraph(resume.summary!),
              pw.SizedBox(height: 20),
            ],
            
            // Skills
            if (resume.skills.isNotEmpty) ...[
              _buildCreativeSectionTitle('SKILLS'),
              pw.SizedBox(height: 10),
              _buildSkills(resume.skills),
              pw.SizedBox(height: 20),
            ],
            
            // Experience
            if (resume.experience.isNotEmpty) ...[
              _buildCreativeSectionTitle('EXPERIENCE'),
              pw.SizedBox(height: 10),
              ...resume.experience.map((exp) => _buildExperience(exp)),
              pw.SizedBox(height: 20),
            ],
            
            // Education
            if (resume.education.isNotEmpty) ...[
              _buildCreativeSectionTitle('EDUCATION'),
              pw.SizedBox(height: 10),
              ...resume.education.map((edu) => _buildEducation(edu)),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildModernSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 2, color: PdfColors.blue700),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue700,
        ),
      ),
    );
  }

  pw.Widget _buildCreativeSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.red700,
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  /// Professional Template (Template 4) - Clean single-column layout matching uploaded design
  Future<Uint8List> _generateProfessionalTemplate(Resume resume) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (pw.Context context) {
          return [
            // Header - Large bold name (all caps)
            pw.Text(
              resume.personalInfo.fullName.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 4),
            
            // Contact Information - Horizontal layout with separators
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                if (resume.personalInfo.phone != null) ...[
                  pw.Text(
                    resume.personalInfo.phone!,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(' | ', style: const pw.TextStyle(fontSize: 10)),
                ],
                pw.Text(
                  resume.personalInfo.email,
                  style: const pw.TextStyle(fontSize: 10),
                ),
                if (resume.personalInfo.address != null) ...[
                  pw.Text(' | ', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    resume.personalInfo.address!,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Horizontal separator line
            pw.Container(
              height: 1,
              color: PdfColors.black,
            ),
            pw.SizedBox(height: 20),
            
            // About Me Section
            if (resume.summary != null && resume.summary!.isNotEmpty) ...[
              _buildProfessionalSectionTitle('ABOUT ME'),
              pw.SizedBox(height: 12),
              _buildParagraph(resume.summary!),
              pw.SizedBox(height: 20),
            ],
            
            // Education Section
            if (resume.education.isNotEmpty) ...[
              _buildProfessionalSectionTitle('EDUCATION'),
              pw.SizedBox(height: 12),
              ...resume.education.map((edu) => _buildProfessionalEducation(edu)),
              pw.SizedBox(height: 20),
            ],
            
            // Work Experience Section
            if (resume.experience.isNotEmpty) ...[
              _buildProfessionalSectionTitle('WORK EXPERIENCE'),
              pw.SizedBox(height: 12),
              ...resume.experience.map((exp) => _buildProfessionalExperience(exp)),
              pw.SizedBox(height: 20),
            ],
            
            // Skills Section
            if (resume.skills.isNotEmpty) ...[
              _buildProfessionalSectionTitle('SKILLS'),
              pw.SizedBox(height: 12),
              _buildProfessionalSkills(resume.skills),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildProfessionalSectionTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          height: 1,
          color: PdfColors.black,
        ),
      ],
    );
  }

  pw.Widget _buildProfessionalEducation(Education edu) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Institution | Dates format
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                edu.institution,
                style: const pw.TextStyle(fontSize: 11),
              ),
              if (edu.startDate != null || edu.endDate != null)
                pw.Text(
                  '${edu.startDate ?? ""}${edu.startDate != null && edu.endDate != null ? "-" : ""}${edu.endDate ?? ""}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
            ],
          ),
          pw.SizedBox(height: 4),
          // Bold degree/title
          pw.Text(
            edu.degree,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          // Description/field if available
          if (edu.field != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              edu.field!,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
          if (edu.gpa != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'GPA: ${edu.gpa!.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildProfessionalExperience(Experience exp) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Company | Dates format
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                exp.company,
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                '${exp.startDate ?? ""}${exp.startDate != null && (exp.endDate != null || exp.isCurrent) ? "-" : ""}${exp.isCurrent ? "Present" : exp.endDate ?? ""}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          // Bold job title
          pw.Text(
            exp.title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          // Responsibilities
          if (exp.responsibilities.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            ...exp.responsibilities.map((resp) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, bottom: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: const pw.TextStyle(fontSize: 10)),
                    pw.Expanded(
                      child: pw.Text(
                        resp,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildProfessionalSkills(List<String> skills) {
    // Organize skills into 3 columns
    final itemsPerColumn = (skills.length / 3).ceil();
    final columns = <List<String>>[];
    
    for (int i = 0; i < skills.length; i += itemsPerColumn) {
      columns.add(skills.sublist(
        i,
        i + itemsPerColumn > skills.length ? skills.length : i + itemsPerColumn,
      ));
    }
    
    // Ensure we have 3 columns
    while (columns.length < 3) {
      columns.add([]);
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: columns.map((column) {
        return pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: column.map((skill) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: const pw.TextStyle(fontSize: 10)),
                    pw.Expanded(
                      child: pw.Text(
                        skill,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  // Helper methods for building PDF sections

  pw.Widget _buildHeader(PersonalInfo personalInfo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          personalInfo.fullName,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Text(
              personalInfo.email,
              style: const pw.TextStyle(fontSize: 10),
            ),
            if (personalInfo.phone != null) ...[
              pw.Text(' • ', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(
                personalInfo.phone!,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ],
        ),
        if (personalInfo.address != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            personalInfo.address!,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
        if (personalInfo.linkedIn != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'LinkedIn: ${personalInfo.linkedIn}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 1, color: PdfColors.grey700),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildParagraph(String text) {
    return pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 11),
      textAlign: pw.TextAlign.justify,
    );
  }

  pw.Widget _buildSkills(List<String> skills) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 4,
      children: skills.map((skill) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            skill,
            style: const pw.TextStyle(fontSize: 10),
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildExperience(Experience exp) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  exp.title,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                _formatDateRange(exp.startDate, exp.endDate, exp.isCurrent),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            exp.company,
            style: pw.TextStyle(
              fontSize: 11,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          if (exp.responsibilities.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            ...exp.responsibilities.map((resp) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: const pw.TextStyle(fontSize: 10)),
                    pw.Expanded(
                      child: pw.Text(
                        resp,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildEducation(Education edu) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  edu.degree,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (edu.startDate != null || edu.endDate != null)
                pw.Text(
                  _formatDateRange(edu.startDate, edu.endDate, false),
                  style: const pw.TextStyle(fontSize: 10),
                ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            edu.institution,
            style: pw.TextStyle(
              fontSize: 11,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          if (edu.field != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              edu.field!,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
          if (edu.gpa != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'GPA: ${edu.gpa!.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateRange(String? start, String? end, bool isCurrent) {
    final startStr = start ?? '';
    final endStr = isCurrent ? 'Present' : (end ?? '');
    
    if (startStr.isEmpty && endStr.isEmpty) return '';
    if (startStr.isEmpty) return endStr;
    if (endStr.isEmpty) return startStr;
    
    return '$startStr - $endStr';
  }
}
