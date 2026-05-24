import 'dart:async';
import 'package:get/get.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/llm_service.dart';
import '../services/chat_storage_service.dart';

class ChatController extends GetxController {
  final LlmService _llm = Get.find<LlmService>();
  final ChatStorageService _storage = Get.find<ChatStorageService>();

  final chats = <ChatModel>[].obs;
  final activeChatId = RxnString();
  final isGenerating = false.obs;
  final streamedResponse = ''.obs;
  final temperature = 0.7.obs;
  final systemPrompt = ''.obs;

  StreamSubscription<String>? _genSub;

  @override
  void onInit() {
    super.onInit();
    _loadChats();
    temperature.value = _normalizeTemperature(_storage.defaultTemperature);
    systemPrompt.value = _storage.globalSystemPrompt;
  }

  void _loadChats() {
    chats.value = _storage.getAllChats();
  }

  ChatModel? get activeChat {
    if (activeChatId.value == null) return null;
    try {
      return chats.firstWhere((c) => c.id == activeChatId.value);
    } catch (_) {
      return null;
    }
  }

  void newChat() {
    final chat = ChatModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      systemPrompt: systemPrompt.value,
    );
    chats.insert(0, chat);
    _storage.saveChat(chat);
    activeChatId.value = chat.id;
  }

  void switchChat(String id) {
    activeChatId.value = id;
    final chat = activeChat;
    if (chat != null) {
      systemPrompt.value = chat.systemPrompt;
    }
  }

  void deleteChat(String id) {
    chats.removeWhere((c) => c.id == id);
    _storage.deleteChat(id);
    if (activeChatId.value == id) {
      activeChatId.value = chats.isNotEmpty ? chats.first.id : null;
    }
  }

  Future<void> sendMessage(
    String text, {
    String? modelFilename,
    String? attachmentName,
    String? attachmentPath,
    String? attachmentMimeType,
    String? attachmentBase64,
  }) async {
    final trimmedText = text.trim();
    final hasAttachment =
        (attachmentPath != null && attachmentPath.isNotEmpty) ||
        (attachmentBase64 != null && attachmentBase64.isNotEmpty);
    if (trimmedText.isEmpty && !hasAttachment) return;
    final chat = activeChat;
    if (chat == null) return;

    final isImageAttachment =
        attachmentMimeType?.startsWith('image/') == true &&
        (attachmentBase64 != null && attachmentBase64.isNotEmpty);

    final content = trimmedText.isNotEmpty
        ? trimmedText
        : (attachmentName?.isNotEmpty == true
              ? 'Attached ${attachmentName!.endsWith('.gguf') ? 'file' : 'item'}: $attachmentName'
              : 'Attached item');

    final userMsg = MessageModel(
      role: MessageRole.user,
      content: content,
      attachmentName: attachmentName,
      attachmentPath: attachmentPath,
      attachmentMimeType: attachmentMimeType,
      imageBase64: isImageAttachment ? attachmentBase64 : null,
      imageMimeType: isImageAttachment ? attachmentMimeType : null,
    );
    chat.messages.add(userMsg);
    chat.autoTitle();
    chat.updatedAt = DateTime.now();

    if (chat.modelId.isEmpty && modelFilename != null) {
      chat.modelId = modelFilename;
    }

    _storage.saveChat(chat);
    chats.refresh();

    final history = chat.messages
        .where((m) => !m.isSystem)
        .map((m) => m.toLlamaMessage())
        .toList();

    isGenerating.value = true;
    streamedResponse.value = '';

    final aiMsg = MessageModel(role: MessageRole.assistant, content: '');
    chat.messages.add(aiMsg);
    chats.refresh();

    try {
      final stream = _llm.generate(
        messages: history,
        systemPrompt: chat.systemPrompt.isNotEmpty
            ? chat.systemPrompt
            : systemPrompt.value,
        temperature: temperature.value,
      );

      await for (final token in stream) {
        streamedResponse.value += token;
        aiMsg.content = streamedResponse.value;

        chats.refresh();
      }
    } catch (e) {
      if (aiMsg.content.isEmpty) {
        aiMsg.content = '⚠ Error: ${e.toString()}';
      }
    } finally {
      aiMsg.content = aiMsg.content
          .replaceAll(
            RegExp(
              r'<\|end\|>|<\|eot_id\|>|<\|endoftext\|>|<\|im_end\|>|<\|im_start\|>'
              r'|<end_of_turn>|<start_of_turn>|<\|assistant\|>|<\|user\|>|<\|system\|>'
              r'|<\|pad\|>|</s>|<s>|\[INST\]|\[/INST\]|\[end\]',
            ),
            '',
          )
          .trim();
      isGenerating.value = false;
      streamedResponse.value = '';
      chat.updatedAt = DateTime.now();
      _storage.saveChat(chat);
      chats.refresh();
    }
  }

  void stopGeneration() {
    _llm.stopGeneration();
    isGenerating.value = false;
  }

  void updateSystemPrompt(String prompt) {
    systemPrompt.value = prompt;
    final chat = activeChat;
    if (chat != null) {
      chat.systemPrompt = prompt;
      _storage.saveChat(chat);
    }
  }

  void setGlobalSystemPrompt(String prompt) {
    systemPrompt.value = prompt;
    _storage.globalSystemPrompt = prompt;
  }

  void clearGlobalSystemPrompt() {
    systemPrompt.value = '';
    _storage.globalSystemPrompt = '';
  }

  void updateTemperature(double temp) {
    final normalized = _normalizeTemperature(temp);
    temperature.value = normalized;
    _storage.defaultTemperature = normalized;
  }

  double _normalizeTemperature(double temp) => temp.clamp(0.0, 2.0).toDouble();

  @override
  void onClose() {
    _genSub?.cancel();
    super.onClose();
  }
}
