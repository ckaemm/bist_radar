import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_analysis_provider.dart';
import '../models/ai_analysis.dart';

class AiAnalysisCard extends StatelessWidget {
  final String symbol;
  final double currentPrice;
  final double rsiValue;
  final double macdValue;
  final double macdSignal;
  final double bollingerUpper;
  final double bollingerLower;
  final double? volume;
  final double? changePercent;

  const AiAnalysisCard({
    super.key,
    required this.symbol,
    required this.currentPrice,
    required this.rsiValue,
    required this.macdValue,
    required this.macdSignal,
    required this.bollingerUpper,
    required this.bollingerLower,
    this.volume,
    this.changePercent,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AiAnalysisProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00D4AA).withAlpha(77),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, provider),
              const Divider(color: Color(0xFF3A3A4E), height: 1),
              _buildBody(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AiAnalysisProvider provider) {
    final isLoading = provider.state == AiAnalysisState.loading ||
        provider.state == AiAnalysisState.streaming;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Color(0xFF00D4AA), size: 20),
          const SizedBox(width: 8),
          const Text(
            'AI Analiz',
            style: TextStyle(
              color: Color(0xFF00D4AA),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!provider.isOllamaAvailable) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(51),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Çevrimdışı',
                style: TextStyle(color: Colors.orange, fontSize: 10),
              ),
            ),
          ],
          const Spacer(),
          if (provider.state == AiAnalysisState.success ||
              provider.state == AiAnalysisState.error)
            TextButton(
              onPressed: provider.reset,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
              ),
              child: const Text('Sıfırla', style: TextStyle(fontSize: 12)),
            ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: isLoading ? null : () => _startAnalysis(context),
            icon: isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  )
                : const Icon(Icons.auto_awesome, size: 16),
            label: Text(
              isLoading ? 'Analiz ediliyor...' : 'Analiz Et',
              style: const TextStyle(fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AiAnalysisProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: switch (provider.state) {
        AiAnalysisState.idle => _buildIdle(),
        AiAnalysisState.loading => _buildLoading(),
        AiAnalysisState.streaming => _buildStreaming(provider),
        AiAnalysisState.success => _buildSuccess(provider.currentAnalysis!),
        AiAnalysisState.error => _buildError(provider.errorMessage),
      },
    );
  }

  Widget _buildIdle() {
    return Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.white38, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Yapay zeka ile teknik analiz yaptır',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 2),
              Text(
                'RSI, MACD ve Bollinger bantlarına göre AL/SAT/BEKLE önerisi alırsın.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            CircularProgressIndicator(color: Color(0xFF00D4AA), strokeWidth: 2),
            SizedBox(height: 12),
            Text(
              'Model yanıt hazırlıyor...',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreaming(AiAnalysisProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _PulsingDot(),
            const SizedBox(width: 8),
            const Text(
              'AI yazıyor...',
              style: TextStyle(
                color: Color(0xFF00D4AA),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            provider.streamingText.isEmpty
                ? 'Bağlanıyor...'
                : provider.streamingText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(AiAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _RecommendationBadge(recommendation: analysis.recommendation),
            const SizedBox(width: 8),
            _RiskChip(riskLevel: analysis.riskLevel),
            const Spacer(),
            Text(
              _formatTimestamp(analysis.timestamp),
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            analysis.summary,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 13),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                'Bu analiz yatırım tavsiyesi değildir. Kendi araştırmanızı yapınız.',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
            SizedBox(width: 8),
            Text(
              'Bağlantı hatası',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withAlpha(77)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Ollama kurulu ve çalışıyor mu?',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '1. Terminalde çalıştır: ollama serve\n'
                '2. Modeli indir: ollama pull llama3.2\n'
                '3. Emülatör kullanıyorsan 10.0.2.2:11434 adresi erişilebilir olmalı.',
                style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _startAnalysis(BuildContext context) {
    context.read<AiAnalysisProvider>().analyzeStockStreaming(
          symbol: symbol,
          currentPrice: currentPrice,
          rsiValue: rsiValue,
          macdValue: macdValue,
          macdSignal: macdSignal,
          bollingerUpper: bollingerUpper,
          bollingerLower: bollingerLower,
        );
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')} '
        '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}';
  }
}

// ── Alt bileşenler ──────────────────────────────────────────────────────────

class _RecommendationBadge extends StatelessWidget {
  final String recommendation;
  const _RecommendationBadge({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final color = switch (recommendation) {
      'AL' => Colors.green,
      'SAT' => Colors.red,
      _ => Colors.amber,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Text(
        recommendation,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _RiskChip extends StatelessWidget {
  final String riskLevel;
  const _RiskChip({required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final color = switch (riskLevel) {
      'Düşük' => Colors.green,
      'Yüksek' => Colors.red,
      _ => Colors.orange,
    };
    return Chip(
      label: Text(
        'Risk: $riskLevel',
        style: TextStyle(color: color, fontSize: 11),
      ),
      backgroundColor: color.withAlpha(26),
      side: BorderSide(color: color.withAlpha(77)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF00D4AA),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
