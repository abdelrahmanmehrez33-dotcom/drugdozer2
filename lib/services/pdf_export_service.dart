import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/entities/family_member.dart';

class PdfExportService {
  static final PdfExportService _instance = PdfExportService._internal();
  factory PdfExportService() => _instance;
  PdfExportService._internal();

  // Generate PDF for a single family member
  Future<Uint8List> generateMemberReport({
    required FamilyMember member,
    bool isEnglish = false,
  }) async {
    final pdf = pw.Document();

    // Load Arabic font
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    final textDirection = isEnglish ? pw.TextDirection.ltr : pw.TextDirection.rtl;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: textDirection,
        build: (context) => [
          // Header
          _buildHeader(member, isEnglish, arabicFontBold),
          pw.SizedBox(height: 20),

          // Personal Information
          _buildSection(
            title: isEnglish ? 'Personal Information' : 'المعلومات الشخصية',
            content: _buildPersonalInfo(member, isEnglish, arabicFont),
            font: arabicFontBold,
            isEnglish: isEnglish,
          ),
          pw.SizedBox(height: 15),

          // Chronic Diseases
          if (member.chronicDiseases.isNotEmpty) ...[
            _buildSection(
              title: isEnglish ? 'Chronic Diseases' : 'الأمراض المزمنة',
              content: _buildListItems(member.chronicDiseases, arabicFont),
              font: arabicFontBold,
              isEnglish: isEnglish,
            ),
            pw.SizedBox(height: 15),
          ],

          // Allergies
          if (member.allergies.isNotEmpty) ...[
            _buildSection(
              title: isEnglish ? 'Allergies' : 'الحساسية',
              content: _buildListItems(member.allergies, arabicFont),
              font: arabicFontBold,
              isEnglish: isEnglish,
            ),
            pw.SizedBox(height: 15),
          ],

          // Current Medications
          if (member.currentMedications.isNotEmpty) ...[
            _buildSection(
              title: isEnglish ? 'Current Medications' : 'الأدوية الحالية',
              content: _buildListItems(member.currentMedications, arabicFont),
              font: arabicFontBold,
              isEnglish: isEnglish,
            ),
            pw.SizedBox(height: 15),
          ],

          // Notes
          if (member.notes != null && member.notes!.isNotEmpty) ...[
            _buildSection(
              title: isEnglish ? 'Notes' : 'ملاحظات',
              content: pw.Text(
                member.notes!,
                style: pw.TextStyle(font: arabicFont, fontSize: 12),
                textDirection: textDirection,
              ),
              font: arabicFontBold,
              isEnglish: isEnglish,
            ),
          ],

          // Footer
          pw.SizedBox(height: 30),
          _buildFooter(isEnglish, arabicFont),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(FamilyMember member, bool isEnglish, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: isEnglish 
                ? pw.CrossAxisAlignment.start 
                : pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                isEnglish ? 'Medical Report' : 'التقرير الطبي',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  color: PdfColors.white,
                ),
                textDirection: isEnglish ? pw.TextDirection.ltr : pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                member.name,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 18,
                  color: PdfColors.white,
                ),
                textDirection: isEnglish ? pw.TextDirection.ltr : pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'DrugDoZer',
              style: pw.TextStyle(
                font: font,
                fontSize: 14,
                color: PdfColors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSection({
    required String title,
    required pw.Widget content,
    required pw.Font font,
    required bool isEnglish,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: isEnglish 
            ? pw.CrossAxisAlignment.start 
            : pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 16,
              color: PdfColors.teal,
            ),
            textDirection: isEnglish ? pw.TextDirection.ltr : pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  pw.Widget _buildPersonalInfo(FamilyMember member, bool isEnglish, pw.Font font) {
    final textDirection = isEnglish ? pw.TextDirection.ltr : pw.TextDirection.rtl;
    
    return pw.Column(
      crossAxisAlignment: isEnglish 
          ? pw.CrossAxisAlignment.start 
          : pw.CrossAxisAlignment.end,
      children: [
        _buildInfoRow(
          label: isEnglish ? 'Name' : 'الاسم',
          value: member.name,
          font: font,
          textDirection: textDirection,
        ),
        pw.SizedBox(height: 8),
        _buildInfoRow(
          label: isEnglish ? 'Relationship' : 'صلة القرابة',
          value: member.relationship,
          font: font,
          textDirection: textDirection,
        ),
        if (member.age != null) ...[
          pw.SizedBox(height: 8),
          _buildInfoRow(
            label: isEnglish ? 'Age' : 'العمر',
            value: '${member.age} ${isEnglish ? "years" : "سنة"}',
            font: font,
            textDirection: textDirection,
          ),
        ],
        if (member.weight != null) ...[
          pw.SizedBox(height: 8),
          _buildInfoRow(
            label: isEnglish ? 'Weight' : 'الوزن',
            value: '${member.weight} ${isEnglish ? "kg" : "كجم"}',
            font: font,
            textDirection: textDirection,
          ),
        ],
        pw.SizedBox(height: 8),
        _buildInfoRow(
          label: isEnglish ? 'Report Date' : 'تاريخ التقرير',
          value: _formatDate(DateTime.now()),
          font: font,
          textDirection: textDirection,
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow({
    required String label,
    required String value,
    required pw.Font font,
    required pw.TextDirection textDirection,
  }) {
    return pw.Row(
      mainAxisAlignment: textDirection == pw.TextDirection.rtl 
          ? pw.MainAxisAlignment.end 
          : pw.MainAxisAlignment.start,
      children: textDirection == pw.TextDirection.rtl
          ? [
              pw.Text(value, style: pw.TextStyle(font: font, fontSize: 12)),
              pw.Text(' :$label', style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700)),
            ]
          : [
              pw.Text('$label: ', style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700)),
              pw.Text(value, style: pw.TextStyle(font: font, fontSize: 12)),
            ],
    );
  }

  pw.Widget _buildListItems(List<String> items, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.map((item) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          children: [
            pw.Container(
              width: 6,
              height: 6,
              decoration: const pw.BoxDecoration(
                color: PdfColors.teal,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Text(
                item,
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  pw.Widget _buildFooter(bool isEnglish, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            isEnglish 
                ? 'This report is generated by DrugDoZer App'
                : 'تم إنشاء هذا التقرير بواسطة تطبيق DrugDoZer',
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
            textDirection: isEnglish ? pw.TextDirection.ltr : pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            isEnglish 
                ? 'For medical advice, please consult a healthcare professional'
                : 'للحصول على استشارة طبية، يرجى مراجعة الطبيب المختص',
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
            textDirection: isEnglish ? pw.TextDirection.ltr : pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  // Share PDF for a single member
  Future<void> shareMemberReport({
    required FamilyMember member,
    bool isEnglish = false,
  }) async {
    final pdfBytes = await generateMemberReport(member: member, isEnglish: isEnglish);
    
    final fileName = '${member.name.replaceAll(' ', '_')}_medical_report.pdf';
    
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
    );
  }

  // Print PDF for a single member
  Future<void> printMemberReport({
    required FamilyMember member,
    bool isEnglish = false,
  }) async {
    final pdfBytes = await generateMemberReport(member: member, isEnglish: isEnglish);
    
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: '${member.name} - Medical Report',
    );
  }

  // Legacy method for compatibility
  static Future<void> exportFamilyToPdf(List<FamilyMember> members, String fileName) async {
    final service = PdfExportService();
    await service.shareAllMembersReport(members: members, isEnglish: true);
  }

  // Generate PDF for all family members
  Future<Uint8List> generateAllMembersReport({
    required List<FamilyMember> members,
    bool isEnglish = false,
  }) async {
    final pdf = pw.Document();

    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    final textDirection = isEnglish ? pw.TextDirection.ltr : pw.TextDirection.rtl;

    // Cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(30),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  'DrugDoZer',
                  style: pw.TextStyle(
                    font: arabicFontBold,
                    fontSize: 36,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                isEnglish ? 'Family Medical Report' : 'التقرير الطبي للعائلة',
                style: pw.TextStyle(
                  font: arabicFontBold,
                  fontSize: 28,
                  color: PdfColors.teal,
                ),
                textDirection: textDirection,
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                '${isEnglish ? "Total Members" : "عدد الأفراد"}: ${members.length}',
                style: pw.TextStyle(font: arabicFont, fontSize: 16),
                textDirection: textDirection,
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                '${isEnglish ? "Date" : "التاريخ"}: ${_formatDate(DateTime.now())}',
                style: pw.TextStyle(font: arabicFont, fontSize: 14, color: PdfColors.grey600),
                textDirection: textDirection,
              ),
            ],
          ),
        ),
      ),
    );

    // Individual member pages
    for (final member in members) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: textDirection,
          build: (context) => [
            _buildHeader(member, isEnglish, arabicFontBold),
            pw.SizedBox(height: 20),
            _buildSection(
              title: isEnglish ? 'Personal Information' : 'المعلومات الشخصية',
              content: _buildPersonalInfo(member, isEnglish, arabicFont),
              font: arabicFontBold,
              isEnglish: isEnglish,
            ),
            if (member.chronicDiseases.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              _buildSection(
                title: isEnglish ? 'Chronic Diseases' : 'الأمراض المزمنة',
                content: _buildListItems(member.chronicDiseases, arabicFont),
                font: arabicFontBold,
                isEnglish: isEnglish,
              ),
            ],
            if (member.allergies.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              _buildSection(
                title: isEnglish ? 'Allergies' : 'الحساسية',
                content: _buildListItems(member.allergies, arabicFont),
                font: arabicFontBold,
                isEnglish: isEnglish,
              ),
            ],
            if (member.currentMedications.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              _buildSection(
                title: isEnglish ? 'Current Medications' : 'الأدوية الحالية',
                content: _buildListItems(member.currentMedications, arabicFont),
                font: arabicFontBold,
                isEnglish: isEnglish,
              ),
            ],
          ],
        ),
      );
    }

    return pdf.save();
  }

  // Share all members report
  Future<void> shareAllMembersReport({
    required List<FamilyMember> members,
    bool isEnglish = false,
  }) async {
    final pdfBytes = await generateAllMembersReport(members: members, isEnglish: isEnglish);
    
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'family_medical_report.pdf',
    );
  }
}
