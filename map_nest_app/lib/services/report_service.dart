import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reports';

  // Save a report to Firestore
  Future<void> saveReport(ReportModel report) async {
    try {
      await _firestore.collection(_collection).doc(report.id).set(report.toMap());
      debugPrint('Report saved successfully: ${report.id}');
    } catch (e) {
      debugPrint('Error saving report: $e');
      rethrow;
    }
  }

  // Get all reports (for admin use)
  Future<List<ReportModel>> getAllReports() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      debugPrint('Error getting reports: $e');
      return [];
    }
  }
}

