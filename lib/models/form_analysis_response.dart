class FormAnalysisResponse {
  final List<UIField> fields;
  final String? formExplanation;
  final String languageDirection;
  final int imageWidth;
  final int imageHeight;
  final String sessionId;

  FormAnalysisResponse({
    required this.fields,
    this.formExplanation,
    required this.languageDirection,
    required this.imageWidth,
    required this.imageHeight,
    required this.sessionId,
  });

  factory FormAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return FormAnalysisResponse(
      fields: (json['fields'] as List).map((e) => UIField.fromJson(e)).toList(),
      formExplanation: json['form_explanation'],
      languageDirection: json['language_direction'],
      imageWidth: json['image_width'],
      imageHeight: json['image_height'],
      sessionId: json['session_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fields': fields.map((e) => e.toJson()).toList(),
      'form_explanation': formExplanation,
      'language_direction': languageDirection,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'session_id': sessionId,
    };
  }
}

class UIField {
  final String boxId;
  final String label;
  final String type;
  final List<double>? box;
  String? value;

  UIField({
    required this.boxId,
    required this.label,
    required this.type,
    this.box,
    this.value,
  });

  factory UIField.fromJson(Map<String, dynamic> json) {
    return UIField(
      boxId: json['box_id'],
      label: json['label'],
      type: json['type'],
      box: json['box'] != null ? List<double>.from(json['box'].map((b) => (b as num).toDouble())) : null,
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'box_id': boxId,
      'label': label,
      'type': type,
      'box': box,
      'value': value,
    };
  }
}