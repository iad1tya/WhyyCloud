/// Represents a downloadable/loadable AI model from the catalog.
class AiModelInfo {
  final String id;
  final String name;
  final String filename;
  final String url;
  final double sizeGb;
  final int minRamGb;
  final String label;        // UNCENSORED / STANDARD / CUSTOM
  final String badge;        // RECOMMENDED, HERETIC, etc.
  final String systemPrompt;
  final bool recommended;

  const AiModelInfo({
    required this.id,
    required this.name,
    required this.filename,
    required this.url,
    required this.sizeGb,
    required this.minRamGb,
    required this.label,
    required this.badge,
    required this.systemPrompt,
    this.recommended = false,
  });

  factory AiModelInfo.fromJson(Map<String, dynamic> json) {
    return AiModelInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      filename: json['filename'] as String,
      url: json['url'] as String,
      sizeGb: (json['sizeGb'] as num).toDouble(),
      minRamGb: (json['minRamGb'] as num).toInt(),
      label: json['label'] as String? ?? 'STANDARD',
      badge: json['badge'] as String? ?? '',
      systemPrompt: json['systemPrompt'] as String? ?? '',
      recommended: json['recommended'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'filename': filename,
        'url': url,
        'sizeGb': sizeGb,
        'minRamGb': minRamGb,
        'label': label,
        'badge': badge,
        'systemPrompt': systemPrompt,
        'recommended': recommended,
      };

  bool get isUncensored => label == 'UNCENSORED';
  bool get isStandard => label == 'STANDARD';
  bool get isCustom => label == 'CUSTOM';
}
