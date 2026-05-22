import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../controllers/chat_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/model_controller.dart';
import '../services/local_api_server_service.dart';
import '../services/model_manager.dart';
import '../services/background_optimizer_service.dart';
import '../services/chat_storage_service.dart';

class SettingsScreen extends StatelessWidget {
  /// When true, no Scaffold — just the body content for embedding in tabs.
  final bool embedded;
  final VoidCallback? onOpenDrawer;

  const SettingsScreen({super.key, this.embedded = false, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return _SettingsBody(showBackButton: false, onOpenDrawer: onOpenDrawer);
    }
    return Scaffold(
      backgroundColor: context.bg,
      body: _SettingsBody(showBackButton: true),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onOpenDrawer;

  const _SettingsBody({this.showBackButton = false, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final chatCtrl = Get.find<ChatController>();
    final modelManager = Get.find<ModelManager>();
    final themeCtrl = Get.find<ThemeController>();
    final apiServer = Get.find<LocalApiServerService>();
    final storage = Get.find<ChatStorageService>();

    return Column(
      children: [
        // ── Top bar ──────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            showBackButton ? MediaQuery.of(context).padding.top + 12 : 12,
            12,
            4,
          ),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: context.bgPanel,
              borderRadius: BorderRadius.circular(0),
              border: Border(
                bottom: BorderSide(color: context.borderFaint, width: 1),
              ),
            ),
            child: Row(
              children: [
                if (showBackButton)
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: context.text),
                    onPressed: () => Get.back(),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.menu_rounded, color: context.text),
                    onPressed: onOpenDrawer ?? () => Scaffold.of(context).openDrawer(),
                  ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),

        // ── Body ─────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
            children: [
              _SectionGroup(
                title: 'Appearance',
                children: [
                  Obx(
                    () => SwitchListTile(
                      title: Text(
                        'Dark Mode',
                        style: TextStyle(color: context.text, fontSize: 14),
                      ),
                      subtitle: Text(
                        themeCtrl.isDarkMode
                            ? 'Using dark theme'
                            : 'Using light theme',
                        style: TextStyle(color: context.textD, fontSize: 12),
                      ),
                      // secondary icon removed to keep list compact
                      value: themeCtrl.isDarkMode,
                      onChanged: (val) => themeCtrl.toggleTheme(),
                      activeThumbColor: context.accent,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              _SectionGroup(
                title: 'AI Behavior',
                children: [
                  Text(
                    'Global System Prompt',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Applied to all new chats. Existing chats keep their own prompt.',
                    style: TextStyle(fontSize: 12, color: context.textD),
                  ),
                  const SizedBox(height: 6),
                  Obx(
                    () => TextField(
                      controller:
                          TextEditingController(text: chatCtrl.systemPrompt.value)
                            ..selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: chatCtrl.systemPrompt.value.length,
                              ),
                            ),
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.text,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. You are a helpful assistant...',
                        hintStyle: TextStyle(color: context.textD),
                        filled: true,
                        fillColor: context.bgInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.accent),
                        ),
                      ),
                      onChanged: (v) => chatCtrl.setGlobalSystemPrompt(v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        chatCtrl.clearGlobalSystemPrompt();
                        Get.snackbar(
                          'Cleared',
                          'Global system prompt removed.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.red),
                      label: const Text(
                        'Clear Prompt',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: BorderSide(color: AppColors.red.withOpacity(0.22)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              _SectionGroup(
                title: 'Behavior',
                children: [
                  Text(
                    'Temperature',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Obx(
                    () {
                      final temperature = chatCtrl.temperature.value.clamp(0.0, 2.0).toDouble();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: temperature,
                                    min: 0.0,
                                    max: 2.0,
                                    divisions: 20,
                                    activeColor: context.accent,
                                    inactiveColor: context.border,
                                    label: temperature.toStringAsFixed(1),
                                    onChanged: (v) => chatCtrl.updateTemperature(v),
                                  ),
                                ),
                                Container(
                                  width: 52,
                                  alignment: Alignment.center,
                                  child: Text(
                                    temperature.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: context.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _tempPresetChip(context, chatCtrl, 0.0, '0.0'),
                                _tempPresetChip(context, chatCtrl, 0.7, '0.7 (Default)'),
                                _tempPresetChip(context, chatCtrl, 1.0, '1.0'),
                                _tempPresetChip(context, chatCtrl, 1.5, '1.5'),
                                _tempPresetChip(context, chatCtrl, 2.0, '2.0'),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),

              if (Platform.isAndroid) ...[
                _SectionGroup(
                  title: 'System',
                  wrapInCard: false,
                  children: [
                    _menuTile(
                      context,
                      title: 'Battery Optimization',
                      subtitle: 'Disable to prevent background killing',
                        leadingIcon: null,
                      surface: Colors.transparent,
                      borderColor: context.border,
                      trailing: FutureBuilder<bool>(
                        future: BackgroundOptimizerService.isOptimizationDisabled(),
                        builder: (context, snapshot) {
                          final disabled = snapshot.data ?? false;
                          if (disabled) {
                            return const Icon(Icons.check_circle_rounded,
                                color: AppColors.green, size: 20);
                          }
                          return const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.orange);
                        },
                      ),
                      onTap: () async {
                        await BackgroundOptimizerService.openBatterySettings();
                      },
                    ),
                  ],
                ),
              ],

              _SectionGroup(
                title: 'Hardware',
                children: [
                  const SizedBox(height: 12),
                  _HardwareSettingsCard(storage: storage),
                ],
              ),

              _SectionGroup(
                title: 'Connectivity',
                children: [
                  _card(
                    context,
                    child: Obx(() {
                      final running = apiServer.isRunning.value;
                      final starting = apiServer.isStarting.value;
                      final ready = apiServer.hasLoadedModel;
                      final busy = apiServer.isBusy;
                      final statusText = starting
                          ? 'Starting'
                          : running
                          ? ready
                                ? busy
                                      ? 'Busy'
                                      : 'Running'
                                : 'No model loaded'
                          : 'Stopped';
                      final statusColor = running && ready
                          ? AppColors.green
                          : running
                          ? AppColors.orange
                          : context.textD;

                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              title: Text(
                                'Local API server',
                                style: TextStyle(color: context.text, fontSize: 14),
                              ),
                              subtitle: Text(
                                'OpenAI base URL: ${apiServer.baseUrl}',
                                style: TextStyle(
                                  color: context.textD,
                                  fontSize: 12,
                                ),
                              ),
                              // secondary icon removed to tighten layout
                              value: running,
                              onChanged: starting
                                  ? null
                                  : (enabled) async {
                                      try {
                                        if (enabled) {
                                          await apiServer.start();
                                        } else {
                                          await apiServer.stop();
                                        }
                                      } catch (e) {
                                        Get.snackbar(
                                          'Local API Error',
                                          e.toString(),
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      }
                                    },
                              activeThumbColor: context.accent,
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: Text(
                                'Allow External Connections',
                                style: TextStyle(color: context.text, fontSize: 14),
                              ),
                              subtitle: Text(
                                'Listen on 0.0.0.0 instead of localhost',
                                style: TextStyle(
                                  color: context.textD,
                                  fontSize: 12,
                                ),
                              ),
                              value: apiServer.allInterfaces.value,
                              onChanged: starting
                                  ? null
                                  : (enabled) async {
                                      try {
                                        await apiServer.setAllInterfaces(enabled);
                                      } catch (e) {
                                        Get.snackbar(
                                          'Settings Error',
                                          e.toString(),
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      }
                                    },
                              activeThumbColor: AppColors.orange,
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (apiServer.allInterfaces.value)
                              Container(
                                margin: const EdgeInsets.only(top: 4, bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withOpacity(0.1),
                                  border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.orange),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Anyone on your network can access your loaded model.',
                                        style: TextStyle(fontSize: 11, color: context.text),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _statusChip(context, statusText, statusColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FutureBuilder<String?>(
                                    future: apiServer.allInterfaces.value
                                        ? apiServer.getDeviceIp()
                                        : Future.value(null),
                                    builder: (context, snapshot) {
                                      String url = apiServer.baseUrl;
                                      if (apiServer.allInterfaces.value && snapshot.hasData) {
                                        url = 'http://${snapshot.data}:${apiServer.port.value}/v1';
                                      }
                                      return SelectableText(
                                        url,
                                        style: TextStyle(
                                          color: context.text,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: ValueKey('api-port-${apiServer.port.value}'),
                              initialValue: apiServer.port.value.toString(),
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: context.text, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Port',
                                helperText:
                                    'Use API key "local" in clients that require one.',
                                labelStyle: TextStyle(color: context.textM),
                                helperStyle: TextStyle(
                                  color: context.textD,
                                  fontSize: 11,
                                ),
                                filled: true,
                                fillColor: context.bgInput,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: context.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: context.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: context.accent),
                                ),
                              ),
                              onFieldSubmitted: (value) async {
                                final parsed = int.tryParse(value.trim());
                                if (parsed == null ||
                                    parsed < 1024 ||
                                    parsed > 65535) {
                                  Get.snackbar(
                                    'Invalid Port',
                                    'Choose a port from 1024 to 65535.',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  return;
                                }
                                try {
                                  await apiServer.setPort(parsed);
                                  Get.snackbar(
                                    'Local API Updated',
                                    'Base URL is ${apiServer.baseUrl}',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                } catch (e) {
                                  Get.snackbar(
                                    'Local API Error',
                                    e.toString(),
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Get.toNamed('/api-endpoints');
                                },
                                child: const Text('Sample Endpoints & Testing'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: context.text,
                                  side: BorderSide(color: context.border),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            if (apiServer.errorMessage.value.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                apiServer.errorMessage.value,
                                style: const TextStyle(
                                  color: AppColors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),

              _SectionGroup(
                title: 'Storage & Tools',
                children: [
                  _menuTile(
                    context,
                    title: 'Model Storage',
                    subtitle: modelManager.modelsDir,
                    leadingIcon: null,
                    onTap: () async {
                      // Copy models dir to clipboard and refresh scan
                      await Clipboard.setData(ClipboardData(text: modelManager.modelsDir));
                      Get.snackbar('Path Copied', 'Model storage path copied to clipboard.', snackPosition: SnackPosition.BOTTOM);
                    },
                  ),
                  const SizedBox(height: 6),
                  _menuTile(
                    context,
                    title: 'App Logs',
                    subtitle: 'View logs, errors & share with developers',
                    leadingIcon: null,
                    leadingColor: AppColors.orange,
                    trailing: Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: context.textD),
                    onTap: () => Get.toNamed('/logs'),
                  ),
                  const SizedBox(height: 6),
                  _menuTile(
                    context,
                    title: 'Clear Temporary Cache',
                    subtitle: 'Remove temporary app files',
                    leadingIcon: null,
                    leadingColor: context.textM,
                    trailing: null,
                    onTap: () async {
                      final confirmed = await Get.dialog<bool?>(
                        AlertDialog(
                          backgroundColor: context.bgPanel,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: Text('Clear Temporary Cache', style: TextStyle(color: context.text)),
                          content: Text('Remove temporary cached files used by the system picker?', style: TextStyle(color: context.textM)),
                          actions: [
                            TextButton(onPressed: () => Get.back(result: false), child: Text('Cancel', style: TextStyle(color: context.textD))),
                            ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Clear')),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await Get.find<ModelController>().clearCache();
                      }
                    },
                  ),
                ],
              ),

              _SectionGroup(
                title: 'Danger Zone',
                children: [
                  _menuTile(
                    context,
                    title: 'Delete All Chats',
                    subtitle: 'Remove every conversation from this device',
                    leadingIcon: null,
                    leadingColor: AppColors.red,
                    trailing: null,
                    surface: context.bgPanel,
                    borderColor: AppColors.red.withOpacity(0.25),
                    onTap: () async {
                      String typed = '';
                      final confirmed = await Get.dialog<bool?>(
                        AlertDialog(
                          backgroundColor: context.bgPanel,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text('Delete All Chats?', style: TextStyle(color: context.text)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Type DELETE to confirm. This cannot be undone.', style: TextStyle(color: context.textM)),
                              const SizedBox(height: 12),
                              TextField(
                                autofocus: true,
                                onChanged: (v) => typed = v.trim(),
                                decoration: InputDecoration(
                                  hintText: 'Type DELETE to confirm',
                                  filled: true,
                                  fillColor: context.bgInput,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Get.back(result: false), child: Text('Cancel', style: TextStyle(color: context.textD))),
                            ElevatedButton(onPressed: () => Get.back(result: typed == 'DELETE'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.red), child: const Text('Delete All', style: TextStyle(color: Colors.white))),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        // Persist deletion and clear in-memory state
                        await Get.find<ChatStorageService>().deleteAllChats();
                        chatCtrl.chats.clear();
                        chatCtrl.activeChatId.value = null;
                        Get.snackbar('Done', 'All chats deleted.', snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Whyy Cloud v1.0',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.textM,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Powered by llamadart + llama.cpp',
                      style: TextStyle(fontSize: 11, color: context.textD),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.textD,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData? leadingIcon,
    Color? leadingColor,
    Widget? trailing,
    VoidCallback? onTap,
    Color? surface,
    Color? borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface ?? context.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: borderColor == null ? null : Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (leadingColor ?? context.accent).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      leadingIcon,
                      size: 16,
                      color: leadingColor ?? context.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: context.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.textD,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tempPresetChip(BuildContext context, ChatController chatCtrl, double value, String label) {
    final temperature = chatCtrl.temperature.value.clamp(0.0, 2.0).toDouble();
    final selected = (temperature - value).abs() < 0.05;
    return InkWell(
      onTap: () => chatCtrl.updateTemperature(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withOpacity(0.18) : context.bgPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.accent : context.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : context.text,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _SectionGroup({
    required String title,
    required List<Widget> children,
    bool wrapInCard = true,
  }) {
    return Builder(
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, title),
              const SizedBox(height: 6),
              if (wrapInCard)
                _card(
                  context,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _interleave(children, const SizedBox(height: 8)),
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _interleave(children, const SizedBox(height: 8)),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _interleave(List<Widget> items, Widget separator) {
    if (items.isEmpty) return const [];
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i != items.length - 1) result.add(separator);
    }
    return result;
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderFaint),
      ),
      child: child,
    );
  }

  Widget _statusChip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HardwareSettingsCard extends StatefulWidget {
  final ChatStorageService storage;

  const _HardwareSettingsCard({required this.storage});

  @override
  State<_HardwareSettingsCard> createState() => _HardwareSettingsCardState();
}

class _HardwareSettingsCardState extends State<_HardwareSettingsCard> {
  late String _backend;
  late double _gpuLayers;
  bool _showManual = false;

  // Auto-detect the best backend and GPU layers for this device
  static Map<String, dynamic> _detectBestConfig() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      // Desktop: CPU is safest, Vulkan if available
      return {'backend': 'cpu', 'gpuLayers': 0, 'reason': 'CPU mode — most compatible on desktop'};
    }

    // Android/iOS: detect available RAM and processor count
    final cores = Platform.numberOfProcessors;
    
    if (cores >= 8) {
      // High-end device (e.g. Snapdragon 8 Gen 2+, Dimensity 9000+)
      return {
        'backend': 'opencl',
        'gpuLayers': 33,
        'reason': 'OpenCL GPU — best for high-end SoC ($cores cores detected)',
      };
    } else if (cores >= 6) {
      // Mid-range device
      return {
        'backend': 'cpu',
        'gpuLayers': 0,
        'reason': 'CPU mode — safe for mid-range devices ($cores cores)',
      };
    } else {
      // Low-end device
      return {
        'backend': 'cpu',
        'gpuLayers': 0,
        'reason': 'CPU mode — optimized for lower-end devices ($cores cores)',
      };
    }
  }

  @override
  void initState() {
    super.initState();
    _backend = widget.storage.backendType;
    _gpuLayers = widget.storage.gpuLayers.toDouble();
  }

  void _applyAutoConfig() {
    final config = _detectBestConfig();
    setState(() {
      _backend = config['backend'] as String;
      _gpuLayers = (config['gpuLayers'] as int).toDouble();
    });
    widget.storage.backendType = _backend;
    widget.storage.gpuLayers = _gpuLayers.toInt();
    Get.snackbar(
      'Auto Config Applied',
      config['reason'] as String,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _saveBackend(String val) {
    setState(() => _backend = val);
    widget.storage.backendType = val;
    // Auto-set sensible GPU layers when switching
    if (val == 'cpu') {
      setState(() => _gpuLayers = 0);
      widget.storage.gpuLayers = 0;
    } else if (_gpuLayers == 0) {
      setState(() => _gpuLayers = 33);
      widget.storage.gpuLayers = 33;
    }
  }

  void _saveGpuLayers(double val) {
    setState(() => _gpuLayers = val);
    widget.storage.gpuLayers = val.toInt();
  }

  String get _currentConfigLabel {
    switch (_backend) {
      case 'vulkan':
        return 'GPU (Vulkan) • ${_gpuLayers.toInt()} layers';
      case 'opencl':
        return 'GPU (OpenCL) • ${_gpuLayers.toInt()} layers';
      default:
        return 'CPU Only';
    }
  }

  @override
  Widget build(BuildContext context) {
    final autoConfig = _detectBestConfig();

    return Container(
      decoration: BoxDecoration(
        color: context.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Recommended Auto Config ──
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: context.accent),
              const SizedBox(width: 8),
              Text(
                'Compute Device',
                style: TextStyle(color: context.text, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Current: $_currentConfigLabel',
            style: TextStyle(color: context.textM, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Recommended button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _applyAutoConfig,
              icon: Icon(
                Icons.tune_rounded,
                size: 16,
                color: context.text,
              ),
              label: const Text('Apply Recommended Settings'),
              style: OutlinedButton.styleFrom(
                backgroundColor: context.bgInput,
                foregroundColor: context.text,
                side: BorderSide(
                  color: context.isDark ? context.borderFaint : context.border,
                  width: 1.2,
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: context.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    autoConfig['reason'] as String,
                    style: TextStyle(color: context.textM, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Manual Override Toggle ──
          InkWell(
            onTap: () => setState(() => _showManual = !_showManual),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _showManual ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: context.textM,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Manual Override',
                    style: TextStyle(
                      color: context.textM,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showManual) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildBackendButton('CPU', 'cpu'),
                const SizedBox(width: 8),
                _buildBackendButton('Vulkan', 'vulkan'),
                const SizedBox(width: 8),
                _buildBackendButton('OpenCL', 'opencl'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GPU Layers',
                  style: TextStyle(color: context.text, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.bgInput,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _gpuLayers.toInt().toString(),
                    style: TextStyle(color: context.text, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: context.accent,
                inactiveTrackColor: context.border,
                thumbColor: context.accent,
                overlayColor: context.accent.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _gpuLayers,
                min: 0,
                max: 99,
                divisions: 99,
                onChanged: _backend == 'cpu' ? null : _saveGpuLayers,
              ),
            ),
            Text(
              'If the app crashes when loading a model, reduce GPU layers or switch to CPU. Reload the model after changing settings.',
              style: TextStyle(color: context.textD, fontSize: 11, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackendButton(String label, String value) {
    final selected = _backend == value;
    return Expanded(
      child: InkWell(
        onTap: () => _saveBackend(value),
        borderRadius: BorderRadius.circular(8),
            child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? context.accent : context.bgInput,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? context.accent : context.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : context.text,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

