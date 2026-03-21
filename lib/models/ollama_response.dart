class OllamaResponse {
  final String model;
  final String response;
  final bool done;
  final int? totalDuration;
  final int? loadDuration;
  final int? promptEvalCount;
  final int? evalCount;

  OllamaResponse({
    required this.model,
    required this.response,
    required this.done,
    this.totalDuration,
    this.loadDuration,
    this.promptEvalCount,
    this.evalCount,
  });

  factory OllamaResponse.fromJson(Map<String, dynamic> json) {
    return OllamaResponse(
      model: json['model'] as String,
      response: json['response'] as String,
      done: json['done'] as bool,
      totalDuration: json['total_duration'] as int?,
      loadDuration: json['load_duration'] as int?,
      promptEvalCount: json['prompt_eval_count'] as int?,
      evalCount: json['eval_count'] as int?,
    );
  }
}
