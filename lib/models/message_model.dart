import 'package:hive/hive.dart';

part 'message_model.g.dart';

@HiveType(typeId: 1)
enum MessageRole {
  @HiveField(0)
  user,
  @HiveField(1)
  assistant,
  @HiveField(2)
  system,
}

@HiveType(typeId: 2)
class MessageModel extends HiveObject {
  @HiveField(0)
  final MessageRole role;

  @HiveField(1)
  String content;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  String? imageBase64;

  @HiveField(4)
  String? imageMimeType;

  @HiveField(5)
  String? attachmentName;

  @HiveField(6)
  String? attachmentPath;

  @HiveField(7)
  String? attachmentMimeType;

  MessageModel({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.imageBase64,
    this.imageMimeType,
    this.attachmentName,
    this.attachmentPath,
    this.attachmentMimeType,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;

  bool get hasImageAttachment => imageBase64 != null && imageBase64!.isNotEmpty;
  bool get hasFileAttachment =>
      attachmentPath != null && attachmentPath!.isNotEmpty;
  bool get hasAttachment => hasImageAttachment || hasFileAttachment;

  Map<String, String> toLlamaMessage() {
    return {'role': role.name, 'content': content};
  }
}
