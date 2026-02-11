import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/drug.dart';
import '../../domain/entities/drug_type.dart';
import '../../core/utils/dose_calculator.dart';
import 'add_reminder_screen.dart';
import '../../core/providers/language_provider.dart';

class DetailsScreen extends StatefulWidget {
  final Drug drug;
  const DetailsScreen({super.key, required this.drug});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final DoseCalculator _doseCalculator = DoseCalculator();
  final TextEditingController _weightController = TextEditingController();
  String _calculatedDose = '';

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isEnglish = languageProvider.isEnglish;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? widget.drug.englishName : widget.drug.arabicName),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share(
                '${isEnglish ? widget.drug.englishName : widget.drug.arabicName}\n'
                '${isEnglish ? 'Category' : 'الفئة'}: ${widget.drug.category}\n'
                '${isEnglish ? 'Dosage' : 'الجرعة'}: ${widget.drug.dosage}',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(isEnglish ? 'Category' : 'الفئة', widget.drug.category, Icons.category),
                    const Divider(),
                    _buildInfoRow(isEnglish ? 'Type' : 'النوع', isEnglish ? widget.drug.type.name : widget.drug.type.arabicName, Icons.merge_type),
                    const Divider(),
                    _buildInfoRow(isEnglish ? 'Description' : 'الوصف', widget.drug.description, Icons.description),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Safe Dose Limit (New)
            if (widget.drug.maxDailyDoseMg > 0)
              Card(
                color: Colors.orange[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.security, color: Colors.orange),
                  title: Text(
                    isEnglish ? 'Safe Daily Limit' : 'حد الاستخدام الآمن يومياً',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${widget.drug.maxDailyDoseMg} mg'),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Dosage Section
            Text(
              isEnglish ? 'Dosage & Usage' : 'الجرعة وطريقة الاستخدام',
              style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF00695C)),
            ),
            const SizedBox(height: 10),
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(widget.drug.dosage, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),

            // Dose Calculator (if applicable)
            if (widget.drug.minDosePerKg > 0)
              _buildCalculator(isEnglish),

            const SizedBox(height: 20),
            
            // Side Effects & Contraindications
            _buildWarningSection(isEnglish ? 'Side Effects' : 'الأعراض الجانبية', widget.drug.sideEffects, Colors.orange),
            const SizedBox(height: 10),
            _buildWarningSection(isEnglish ? 'Contraindications' : 'موانع الاستعمال', widget.drug.contraindications, Colors.red),
            
            const SizedBox(height: 30),
            
            // Add Reminder Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddReminderScreen(
                        initialDrugName: isEnglish ? widget.drug.englishName : widget.drug.arabicName,
                        initialDrugType: widget.drug.type.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.alarm_add),
                label: Text(isEnglish ? 'Set Dose Reminder' : 'ضبط تذكير للجرعة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF00695C), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningSection(String title, String content, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(content),
        ),
      ],
    );
  }

  Widget _buildCalculator(bool isEnglish) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEnglish ? 'Pediatric Dose Calculator (by weight)' : 'حاسبة جرعة الأطفال (حسب الوزن)',
          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: isEnglish ? 'Weight (kg)' : 'الوزن (كجم)',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                double? weight = double.tryParse(_weightController.text);
                if (weight != null) {
                  setState(() {
                    _calculatedDose = _doseCalculator.getDoseRecommendation(weight, widget.drug);
                  });
                }
              },
              child: Text(isEnglish ? 'Calculate' : 'احسب'),
            ),
          ],
        ),
        if (_calculatedDose.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '${isEnglish ? 'Recommended Dose' : 'الجرعة الموصى بها'}: $_calculatedDose',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
        const SizedBox(height: 5),
        Text(
          isEnglish 
            ? '* For educational purposes only. The specialist responsible for calculating doses is the doctor.' 
            : '* لأغراض تعليمية فقط. المختص بحساب الجرعات هو الطبيب والبرنامج لا يغني عن استشارته.',
          style: const TextStyle(fontSize: 11, color: Colors.red, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
