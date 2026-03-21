import 'package:flutter/material.dart';
import '../services/ollama_service.dart';

class AiSettingsScreen extends StatefulWidget {
  final OllamaService ollamaService;

  const AiSettingsScreen({super.key, required this.ollamaService});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  late final TextEditingController _urlController;
  late String _selectedModel;
  late String _selectedLanguage;

  bool _isTesting = false;
  bool? _isConnected;
  List<String> _availableModels = [];
  bool _isLoadingModels = false;

  static const _quickUrls = [
    ('Emülatör (10.0.2.2)', 'http://10.0.2.2:11434'),
    ('Localhost', 'http://localhost:11434'),
    ('Loopback (127.0.0.1)', 'http://127.0.0.1:11434'),
  ];

  @override
  void initState() {
    super.initState();
    _urlController =
        TextEditingController(text: widget.ollamaService.baseUrl);
    _selectedModel = widget.ollamaService.model;
    _selectedLanguage = widget.ollamaService.language;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    widget.ollamaService.updateBaseUrl(_urlController.text.trim());

    setState(() {
      _isTesting = true;
      _isConnected = null;
      _availableModels = [];
    });

    final available = await widget.ollamaService.isAvailable();

    if (!mounted) return;
    setState(() {
      _isConnected = available;
      _isTesting = false;
    });

    if (available) _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() => _isLoadingModels = true);
    try {
      final models = await widget.ollamaService.getAvailableModels();
      if (!mounted) return;
      setState(() {
        _availableModels = models;
        if (models.isNotEmpty && !models.contains(_selectedModel)) {
          _selectedModel = models.first;
          widget.ollamaService.updateModel(_selectedModel);
        }
      });
    } catch (_) {
      // Model listesi alınamazsa sessizce geç
    } finally {
      if (mounted) setState(() => _isLoadingModels = false);
    }
  }

  void _applyQuickUrl(String url) {
    _urlController.text = url;
    setState(() {
      _isConnected = null;
      _availableModels = [];
    });
  }

  void _saveAndPop() {
    widget.ollamaService.updateBaseUrl(_urlController.text.trim());
    widget.ollamaService.updateModel(_selectedModel);
    widget.ollamaService.updateLanguage(_selectedLanguage);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('AI Ayarları',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
        actions: [
          TextButton(
            onPressed: _saveAndPop,
            child: const Text('Kaydet',
                style: TextStyle(color: Color(0xFF00D4AA), fontSize: 14)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Sunucu Adresi'),
          const SizedBox(height: 8),
          _buildUrlField(),
          const SizedBox(height: 12),
          _buildQuickUrls(),
          const SizedBox(height: 12),
          _buildTestButton(),
          const SizedBox(height: 6),
          _buildConnectionStatus(),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Yanıt Dili'),
          const SizedBox(height: 8),
          _buildLanguageSelector(),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Model Seçimi'),
          const SizedBox(height: 8),
          _buildModelList(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          _LangOption(
            label: 'Türkçe',
            flag: '🇹🇷',
            value: 'tr',
            selected: _selectedLanguage == 'tr',
            onTap: () => setState(() => _selectedLanguage = 'tr'),
          ),
          Container(width: 1, height: 48, color: Colors.white12),
          _LangOption(
            label: 'English',
            flag: '🇬🇧',
            value: 'en',
            selected: _selectedLanguage == 'en',
            onTap: () => setState(() => _selectedLanguage = 'en'),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlField() {
    return TextField(
      controller: _urlController,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'http://10.0.2.2:11434',
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF2A2A3E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00D4AA)),
        ),
        prefixIcon:
            const Icon(Icons.link, color: Colors.white38, size: 18),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
          onPressed: () {
            _urlController.clear();
            setState(() => _isConnected = null);
          },
        ),
      ),
      keyboardType: TextInputType.url,
      onChanged: (_) => setState(() => _isConnected = null),
    );
  }

  Widget _buildQuickUrls() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _quickUrls.map((entry) {
        final (label, url) = entry;
        final isActive = _urlController.text.trim() == url;
        return ActionChip(
          label: Text(label, style: const TextStyle(fontSize: 11)),
          avatar: const Icon(Icons.bolt, size: 13),
          backgroundColor:
              isActive ? const Color(0xFF00D4AA).withAlpha(38) : const Color(0xFF2A2A3E),
          side: BorderSide(
            color: isActive
                ? const Color(0xFF00D4AA).withAlpha(153)
                : Colors.white12,
          ),
          labelStyle: TextStyle(
            color: isActive ? const Color(0xFF00D4AA) : Colors.white60,
          ),
          iconTheme: IconThemeData(
            color: isActive ? const Color(0xFF00D4AA) : Colors.white38,
          ),
          onPressed: () => _applyQuickUrl(url),
        );
      }).toList(),
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isTesting ? null : _testConnection,
        icon: _isTesting
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF00D4AA)),
              )
            : const Icon(Icons.wifi_find, size: 17),
        label:
            Text(_isTesting ? 'Test ediliyor...' : 'Bağlantıyı Test Et'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF00D4AA),
          side: const BorderSide(color: Color(0xFF00D4AA)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    if (_isConnected == null) return const SizedBox.shrink();

    final ok = _isConnected!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (ok ? Colors.green : Colors.red).withAlpha(26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (ok ? Colors.green : Colors.red).withAlpha(77),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color: ok ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ok
                  ? 'Ollama sunucusuna bağlanıldı'
                  : 'Bağlantı kurulamadı. Ollama çalışıyor mu?',
              style: TextStyle(
                color: ok ? Colors.green : Colors.red,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelList() {
    if (_isLoadingModels) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF00D4AA)),
        ),
      );
    }

    if (_availableModels.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.white38, size: 16),
                SizedBox(width: 6),
                Text(
                  'Model listesi yüklenemedi',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Bağlantıyı test ettikten sonra mevcut modeller listelenir.\n'
              'Ollama\'ya model eklemek için:\n  ollama pull llama3.2',
              style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.6),
            ),
            const SizedBox(height: 10),
            _ManualModelField(
              currentModel: _selectedModel,
              onChanged: (val) {
                setState(() => _selectedModel = val);
                widget.ollamaService.updateModel(val);
              },
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: RadioGroup<String>(
        groupValue: _selectedModel,
        onChanged: (val) {
          if (val == null) return;
          setState(() => _selectedModel = val);
          widget.ollamaService.updateModel(val);
        },
        child: Column(
          children: _availableModels.asMap().entries.map((entry) {
            final index = entry.key;
            final modelName = entry.value;
            final isLast = index == _availableModels.length - 1;
            return Column(
              children: [
                RadioListTile<String>(
                  value: modelName,
                  title: Text(
                    modelName,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  subtitle: _modelDescription(modelName),
                  activeColor: const Color(0xFF00D4AA),
                  dense: true,
                ),
                if (!isLast)
                  const Divider(
                      color: Colors.white12, height: 1, indent: 16, endIndent: 16),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget? _modelDescription(String name) {
    final lower = name.toLowerCase();
    String? desc;
    if (lower.contains('llama3')) {
      desc = 'Meta — genel amaçlı, Türkçe desteği iyi';
    } else if (lower.contains('mistral')) {
      desc = 'Mistral AI — hızlı ve verimli';
    } else if (lower.contains('gemma')) {
      desc = 'Google — hafif model';
    } else if (lower.contains('phi')) {
      desc = 'Microsoft — küçük ama yetenekli';
    }
    if (desc == null) return null;
    return Text(desc,
        style: const TextStyle(color: Colors.white38, fontSize: 11));
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final String flag;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.flag,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF00D4AA).withAlpha(38)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFF00D4AA) : Colors.white54,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle,
                    color: Color(0xFF00D4AA), size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF00D4AA),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ManualModelField extends StatefulWidget {
  final String currentModel;
  final ValueChanged<String> onChanged;

  const _ManualModelField({
    required this.currentModel,
    required this.onChanged,
  });

  @override
  State<_ManualModelField> createState() => _ManualModelFieldState();
}

class _ManualModelFieldState extends State<_ManualModelField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentModel);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: 'Model adı',
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        hintText: 'llama3.2',
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF1E1E2E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF00D4AA)),
        ),
      ),
      onSubmitted: widget.onChanged,
      onChanged: widget.onChanged,
    );
  }
}
