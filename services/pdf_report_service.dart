import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'firebase_service.dart';

class PdfReportService {
  PdfReportService._();

  static const PdfColor _brandPink = PdfColor.fromInt(0xFFE91E8C);
  static const PdfColor _brandPurple = PdfColor.fromInt(0xFF7A2790);
  static const PdfColor _grey = PdfColor.fromInt(0xFF64748B);

  static Future<Uint8List> generateMotherReport() async {
    final user = FirebaseAuth.instance.currentUser;
    final userName =
        user?.displayName ?? user?.email?.split('@').first ?? 'User';

    final weight = await _fetchDocs('mother_weight');
    final bp = await _fetchDocs('blood_pressure');

    final glucoseRaw = await _fetchDocs('glucose');
    final glucose = glucoseRaw.map((data) {
      final map = Map<String, dynamic>.from(data);
      final isFasting = map['isFasting'];
      map['readingType'] = isFasting == null
          ? '-'
          : (isFasting == true ? 'Fasting' : 'Without Fasting');
      return map;
    }).toList();

    final medical = await _fetchDocs('medical_history');

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader('Mother Health Report', userName),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _section('Weight', weight, ['weight'], ['Weight (kg)'],
              dateField: 'date'),
          _section('Blood Pressure', bp, ['systolic', 'diastolic'],
              ['Systolic', 'Diastolic']),
          _section('Glucose Level', glucose, ['glucoseLevel', 'readingType'],
              ['Glucose (mg/dL)', 'Type']),
          _section(
            'Medical History',
            medical,
            ['diseaseName', 'medicines'],
            ['Condition', 'Medicines'],
            dateField: 'visitDate',
          ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> generateBabyReport({
    required String babyId,
    required String babyName,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> babyDoc;
    try {
      babyDoc = await FirestoreService.collection('babies').doc(babyId).get();
    } catch (e) {
      throw Exception('Failed to load baby profile "$babyId": $e');
    }
    final babyData = babyDoc.data() ?? {};
    final gender = (babyData['gender'] ?? '').toString();
    final bloodGroup = (babyData['bloodGroup'] ?? '').toString();
    final subtitle =
        [gender, bloodGroup].where((e) => e.isNotEmpty).join(' • ');

    final weight = await _fetchDocsByBaby('baby_weight', babyId);
    final vaccination = await _fetchDocsByBaby('vaccinations', babyId);
    final allergy = await _fetchDocsByBaby('allergies', babyId);
    final milestone = await _fetchDocsByBaby('milestones', babyId);
    final medical = await _fetchDocsByBaby('baby_medical_history', babyId);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _buildHeader('$babyName — Health Report', subtitle),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _section('Weight', weight, ['weight'], ['Weight (kg)'],
              dateField: 'date'),
          _section(
            'Vaccinations',
            vaccination,
            ['vaccineName', 'status'],
            ['Vaccine', 'Status'],
            dateField: 'vaccinationDate',
          ),
          _section(
            'Allergies',
            allergy,
            ['allergyName', 'reaction', 'advice'],
            ['Allergy', 'Reaction', 'Advice'],
          ),
          _section(
            'Milestones',
            milestone,
            ['title'],
            ['Milestone'],
            dateField: 'milestoneDate',
          ),
          _section(
            'Medical History',
            medical,
            ['disease', 'treatment', 'notes'],
            ['Condition', 'Treatment', 'Notes'],
          ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<List<Map<String, dynamic>>> _fetchDocs(
      String collection) async {
    try {
      final snap = await FirestoreService.collection(collection)
          .orderBy('createdAt', descending: false)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      throw Exception('Failed to load "$collection": $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchDocsByBaby(
      String collection, String babyId) async {
    try {
      final snap = await FirestoreService.collection(collection)
          .where('babyId', isEqualTo: babyId)
          .get();
      final list = snap.docs.map((d) => d.data()).toList();
      list.sort((a, b) =>
          _resolveDate(a['createdAt']).compareTo(_resolveDate(b['createdAt'])));
      return list;
    } catch (e) {
      throw Exception('Failed to load "$collection" for baby "$babyId": $e');
    }
  }

  static DateTime _resolveDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static pw.Widget _buildHeader(String title, String subtitle) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _brandPink, width: 2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Mother And Baby SmartCare',
            style: pw.TextStyle(
              fontSize: 11,
              color: _brandPurple,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          if (subtitle.isNotEmpty)
            pw.Text(subtitle,
                style: const pw.TextStyle(fontSize: 11, color: _grey)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: _grey),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}  ·  Mother And Baby SmartCare , Confidential Health Record',
        style: const pw.TextStyle(fontSize: 8, color: _grey),
      ),
    );
  }

  static pw.Widget _section(
    String title,
    List<Map<String, dynamic>> docs,
    List<String> fields,
    List<String> labels, {
    String dateField = 'createdAt',
  }) {
    if (docs.isEmpty) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 18),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _brandPurple),
            ),
            pw.SizedBox(height: 6),
            pw.Text('No records available.',
                style: const pw.TextStyle(fontSize: 10, color: _grey)),
          ],
        ),
      );
    }

    final headers = ['Date & Time', ...labels];
    final rows = docs.map((data) {
      final dt = _resolveDate(data[dateField] ?? data['createdAt']);
      return [
        DateFormat('dd MMM yyyy, hh:mm a').format(dt),
        for (final f in fields) (data[f] ?? '-').toString(),
      ];
    }).toList();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _brandPurple),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: _brandPink),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          ),
        ],
      ),
    );
  }
}
