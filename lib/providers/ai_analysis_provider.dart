import 'package:flutter/foundation.dart';
import '../models/ai_analysis.dart';
import '../services/ollama_service.dart';

enum AiAnalysisState { idle, loading, streaming, success, error }

class AiAnalysisProvider extends ChangeNotifier {
  final OllamaService _ollamaService;

  AiAnalysisState _state = AiAnalysisState.idle;
  AiAnalysis? _currentAnalysis;
  String _streamingText = '';
  String _errorMessage = '';
  bool _isOllamaAvailable = false;

  AiAnalysisProvider({OllamaService? ollamaService})
      : _ollamaService = ollamaService ?? OllamaService();

  AiAnalysisState get state => _state;
  AiAnalysis? get currentAnalysis => _currentAnalysis;
  String get streamingText => _streamingText;
  String get errorMessage => _errorMessage;
  bool get isOllamaAvailable => _isOllamaAvailable;

  Future<void> checkConnection() async {
    _isOllamaAvailable = await _ollamaService.isAvailable();
    notifyListeners();
  }

  Future<void> analyzeStock({
    required String symbol,
    required double currentPrice,
    required double rsiValue,
    required double macdValue,
    required double macdSignal,
    required double bollingerUpper,
    required double bollingerLower,
  }) async {
    _setState(AiAnalysisState.loading);
    _errorMessage = '';

    try {
      final analysis = await _ollamaService.analyzeStock(
        symbol: symbol,
        currentPrice: currentPrice,
        rsiValue: rsiValue,
        macdValue: macdValue,
        macdSignal: macdSignal,
        bollingerUpper: bollingerUpper,
        bollingerLower: bollingerLower,
      );
      _currentAnalysis = analysis;
      _setState(AiAnalysisState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AiAnalysisState.error);
    }
  }

  Future<void> analyzeStockStreaming({
    required String symbol,
    required double currentPrice,
    required double rsiValue,
    required double macdValue,
    required double macdSignal,
    required double bollingerUpper,
    required double bollingerLower,
  }) async {
    _streamingText = '';
    _errorMessage = '';
    var tokenCount = 0;
    _setState(AiAnalysisState.streaming);

    final systemPrompt = _ollamaService.buildStockSystemPrompt();
    final prompt = _ollamaService.buildStockUserPrompt(
      symbol: symbol,
      currentPrice: currentPrice,
      rsiValue: rsiValue,
      macdValue: macdValue,
      macdSignal: macdSignal,
      bollingerUpper: bollingerUpper,
      bollingerLower: bollingerLower,
    );

    try {
      await for (final token in _ollamaService.generateStream(
        prompt: prompt,
        systemPrompt: systemPrompt,
        options: {
          'num_predict': 1024,
          'num_ctx': 2048,
          'temperature': 0.3,
        },
      )) {
        _streamingText += token;
        tokenCount++;
        if (tokenCount % 5 == 0) notifyListeners();
      }
      notifyListeners(); // son tokenları da UI'a yansıt

      _currentAnalysis = AiAnalysis.fromRawResponse(
        stockSymbol: symbol,
        rawText: _streamingText,
      );
      _setState(AiAnalysisState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AiAnalysisState.error);
    }
  }

  void reset() {
    _state = AiAnalysisState.idle;
    _currentAnalysis = null;
    _streamingText = '';
    _errorMessage = '';
    notifyListeners();
  }

  void _setState(AiAnalysisState state) {
    _state = state;
    notifyListeners();
  }
}
