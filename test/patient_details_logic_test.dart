import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

bool isCriticalMeasurement(Map<String, String> measurement) {
  try {
    switch (measurement['type']) {
      case 'Blood Pressure':
        final parts = measurement['value']?.split('/');
        if (parts != null && parts.length == 2) {
          final systolic = int.tryParse(parts[0]);
          final diastolicStr = parts[1].split(' ')[0];
          final diastolic = int.tryParse(diastolicStr);
          return systolic != null &&
              diastolic != null &&
              (systolic > 180 || systolic < 90 || diastolic > 120 || diastolic < 60);
        }
        return false;

      case 'Heartbeat Rate':
        final bpmStr = measurement['value']?.split(' ')[0];
        final bpm = int.tryParse(bpmStr ?? '');
        return bpm != null && (bpm < 60 || bpm > 100);

      case 'Blood Oxygen Level':
        final spo2Str = measurement['value']?.split(' ')[0];
        final spo2 = int.tryParse(spo2Str ?? '');
        return spo2 != null && spo2 < 90;

      case 'Respiratory Rate':
        final rateStr = measurement['value']?.split(' ')[0];
        final rate = int.tryParse(rateStr ?? '');
        return rate != null && (rate < 12 || rate > 20);

      default:
        return false;
    }
  } catch (error) {
    return false;
  }
}

String formatDate(String isoDate) {
  try {
    final DateTime dateTime = DateTime.parse(isoDate);
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(dateTime);
  } catch (e) {
    return 'Invalid Date';
  }
}

String formatDateTime(String rawDate) {
  try {
    final utcTime = DateTime.parse(rawDate);
    final localTime = utcTime.toLocal();
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(localTime);
  } catch (e) {
    return 'Invalid Date';
  }
}

void main() {
  group('PatientDetails logic', () {
    test('detects critical blood pressure', () {
      final measurement = {
        'type': 'Blood Pressure',
        'value': '190/130 mmHg',
        'dateTime': DateTime.now().toIso8601String(),
      };
      expect(isCriticalMeasurement(measurement), isTrue);
    });

    test('detects normal heartbeat', () {
      final measurement = {
        'type': 'Heartbeat Rate',
        'value': '80 bpm',
        'dateTime': DateTime.now().toIso8601String(),
      };
      expect(isCriticalMeasurement(measurement), isFalse);
    });

    test('formats ISO date correctly', () {
      final iso = '2025-04-10T15:00:00.000Z';
      final formatted = formatDate(iso);
      expect(formatted, '2025-04-10');
    });

    test('formats ISO datetime to local time string', () {
      final iso = '2025-04-10T15:00:00.000Z';
      final formatted = formatDateTime(iso);
      expect(formatted.length, greaterThan(10)); // ex: '2025-04-10 11:00'
    });
  });
}
