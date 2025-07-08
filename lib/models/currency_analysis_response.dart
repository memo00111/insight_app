class CurrencyAnalysisResponse {
  final String analysis;
  final String status;

  CurrencyAnalysisResponse({
    required this.analysis,
    required this.status,
  });

  factory CurrencyAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return CurrencyAnalysisResponse(
      analysis: json['analysis'] ?? '',
      status: json['status'] ?? 'error',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis': analysis,
      'status': status,
    };
  }

  bool get isSuccess => status.toLowerCase() == 'success';
} 