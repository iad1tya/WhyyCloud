import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../controllers/chat_controller.dart';

class ChatSidebar extends StatelessWidget {
  final VoidCallback onNewChat;
  final ValueChanged<String> onSelectChat;
  final ValueChanged<String> onDeleteChat;
  final bool showNewChatButton;

  const ChatSidebar({
    super.key,
    required this.onNewChat,
    required this.onSelectChat,
    required this.onDeleteChat,
    this.showNewChatButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ChatController>();

    return Column(
      children: [
        // New chat button
        if (showNewChatButton)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onNewChat,
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text(
                  'New Chat',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: context.text,
                  elevation: 0,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.border, width: 1),
                  ),
                ),
              ),
            ),
          ),

        // Chat list
        Expanded(
          child: Obx(() {
            final chats = ctrl.chats;
            if (chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 36, color: context.textD),
                    const SizedBox(height: 12),
                    Text(
                      'No chats yet',
                      style: TextStyle(fontSize: 13, color: context.textD),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final isActive = chat.id == ctrl.activeChatId.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isActive
                      ? context.accent.withValues(alpha: context.isDark ? 0.12 : 0.08)
                      : context.bgPanel,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => onSelectChat(chat.id),
                      borderRadius: BorderRadius.circular(16),
                      hoverColor: context.bgHover,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 14,
                              color: isActive ? context.accent : context.textD,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                chat.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                  color: isActive ? context.text : context.textM,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Delete button with confirmation
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: IconButton(
                                onPressed: () => _confirmDelete(context, chat.id, chat.title),
                                icon: Icon(Icons.close_rounded, size: 14, color: context.textD),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),

        // Footer
        Container(
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.bgPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderFaint),
          ),
          child: Row(
            children: [
              Icon(Icons.save_outlined, size: 14, color: context.textD),
              const SizedBox(width: 8),
              Text(
                'Chats saved locally',
                style: TextStyle(fontSize: 11, color: context.textD),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, String chatId, String chatTitle) async {
    final confirmed = await showDialog<bool?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.bgPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Chat',
          style: TextStyle(
            color: context.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Delete "$chatTitle"?\nThis action cannot be undone.',
          style: TextStyle(color: context.textM, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: TextStyle(color: context.textD)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      onDeleteChat(chatId);
    }
  }
}
