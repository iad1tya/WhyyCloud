import 'package:hive/hive.dart';
import 'message_model.dart';

part 'chat_model.g.dart';

@HiveType(typeId: 0)
class ChatModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String modelId;

  @HiveField(3)
  String systemPrompt;

  @HiveField(4)
  final List<MessageModel> messages;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  ChatModel({
    required this.id,
    this.title = 'New Chat',
    this.modelId = '',
    this.systemPrompt = '',
    List<MessageModel>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Auto-generate title from first user message.
  void autoTitle() {
    if (title != 'New Chat') return;
    final firstUserMsg = messages.where((m) => m.isUser).firstOrNull;
    if (firstUserMsg != null) {
      final raw = firstUserMsg.content.trim();
      title = raw.length > 40 ? '${raw.substring(0, 40)}…' : raw;
    }
  }
}
