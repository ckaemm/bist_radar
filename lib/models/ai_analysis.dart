import 'package:flutter/material.dart';

class AiAnalysis {
  final String stockSymbol;
  final String summary;
  final String recommendation;
  final String technicalComment;
  final String riskLevel;
  final DateTime timestamp;

  AiAnalysis({
    required this.stockSymbol,
    required this.summary,
    required this.recommendation,
    required this.technicalComment,
    required this.riskLevel,
    required this.timestamp,
  });

  factory AiAnalysis.fromRawResponse({
    required String stockSymbol,
    required String rawText,
  }) {
    final recommendation = _parseRecommendation(rawText);
    final riskLevel = _parseRiskLevel(rawText);

    return AiAnalysis(
      stockSymbol: stockSymbol,
      summary: rawText.trim(),
      recommendation: recommendation,
      technicalComment: rawText.trim(),
      riskLevel: riskLevel,
      timestamp: DateTime.now(),
    );
  }

  static String _parseRecommendation(String text) {
    final match = RegExp(r'ÖNERİ\s*:\s*(AL|SAT|BEKLE)', caseSensitive: false)
        .firstMatch(text);
    if (match != null) return match.group(1)!.toUpperCase();
    return 'BEKLE';
  }

  static String _parseRiskLevel(String text) {
    final match = RegExp(
      r'RİSK\s+SEVİYESİ\s*:\s*(Düşük|Orta|Yüksek|DÜŞÜK|ORTA|YÜKSEK)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      final val = match.group(1)!.toLowerCase();
      if (val.contains('düşük') || val.contains('dusuk')) return 'Düşük';
      if (val.contains('yüksek') || val.contains('yuksek')) return 'Yüksek';
      return 'Orta';
    }
    return 'Orta';
  }

  Color get recommendationColor {
    switch (recommendation) {
      case 'AL':
        return Colors.green;
      case 'SAT':
        return Colors.red;
      default:
        return Colors.amber;
    }
  }
}
