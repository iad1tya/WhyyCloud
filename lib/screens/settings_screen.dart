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
        _header(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              _sectionGroup(
                context,
                title: 'Appearance',
                children: [
                  Obx(
                    () => _materialSwitchTile(
                      context,
                      title: 'Dark Mode',
                      subtitle: themeCtrl.isDarkMode
                          ? 'Using dark theme'
                          : 'Using light theme',
                      value: themeCtrl.isDarkMode,
                      activeThumbColor: context.accent,
                      onChanged: (val) => themeCtrl.toggleTheme(),
                    ),
                  ),
                ],
              ),

              _sectionGroup(
                context,
                title: 'AI Behavior',
                children: [
                  Text(
                    'Global System Prompt',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Applied to all new chats. Existing chats keep their own prompt.',
                    style: TextStyle(fontSize: 13, color: context.textD, height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => TextFormField(
                      key: ValueKey('system-prompt-${chatCtrl.systemPrompt.value.length}'),
                      initialValue: chatCtrl.systemPrompt.value,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: 15,
                        color: context.text,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. You are a helpful assistant...',
                        hintStyle: TextStyle(color: context.textD),
                        filled: true,
                        fillColor: context.bgInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (v) => chatCtrl.setGlobalSystemPrompt(v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
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
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        foregroundColor: AppColors.red,
                        backgroundColor: AppColors.red.withValues(alpha: 0.14),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              _sectionGroup(
                context,
                title: 'Behavior',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Temperature',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.text,
                      ),
                    ),
                    subtitle: Text(
                      'Select one response style preset.',
                      style: TextStyle(fontSize: 13, color: context.textD),
                    ),
                    trailing: Obx(
                      () => Chip(
                        label: Text(chatCtrl.temperature.value.toStringAsFixed(1)),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Obx(
                    () {
                      final temperature = chatCtrl.temperature.value.clamp(0.0, 2.0).toDouble();
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _tempPresetChip(context, chatCtrl, 0.0, '0.0', temperature),
                          _tempPresetChip(context, chatCtrl, 0.7, '0.7 Default', temperature),
                          _tempPresetChip(context, chatCtrl, 1.0, '1.0', temperature),
                          _tempPresetChip(context, chatCtrl, 1.5, '1.5', temperature),
                          _tempPresetChip(context, chatCtrl, 2.0, '2.0', temperature),
                        ],
                      );
                    },
                  ),
                ],
              ),

              if (Platform.isAndroid) ...[
                _sectionGroup(
                  context,
                  title: 'System',
                  children: [
                    _menuTile(
                      context,
                      title: 'Battery Optimization',
                      subtitle: 'Disable to prevent background killing',
                      leadingIcon: null,
                      trailing: FutureBuilder<bool>(
                        future: BackgroundOptimizerService.isOptimizationDisabled(),
                        builder: (context, snapshot) {
                          final disabled = snapshot.data ?? false;
                          if (disabled) {
                            return const Icon(Icons.check_circle_rounded,
                                color: AppColors.green, size: 20);
                          }
                          return const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: Colors.white);
                        },
                      ),
                      onTap: () async {
                        await BackgroundOptimizerService.openBatterySettings();
                      },
                    ),
                  ],
                ),
              ],

              _sectionGroup(
                context,
                title: 'Hardware',
                children: [
                  _HardwareSettingsCard(storage: storage),
                ],
              ),

              _sectionGroup(
                context,
                title: 'Connectivity',
                children: [
                  _surfaceCard(
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
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _materialSwitchTile(
                              context,
                              title: 'Local API server',
                              subtitle: 'OpenAI base URL: ${apiServer.baseUrl}',
                              value: running,
                              activeThumbColor: context.accent,
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
                            ),
                            const SizedBox(height: 10),
                            _materialSwitchTile(
                              context,
                              title: 'Allow External Connections',
                              subtitle: 'Listen on 0.0.0.0 instead of localhost',
                              value: apiServer.allInterfaces.value,
                              activeThumbColor: AppColors.orange,
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
                            ),
                            if (apiServer.allInterfaces.value)
                              Container(
                                margin: const EdgeInsets.only(top: 4, bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withValues(alpha: 0.10),
                                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.30)),
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
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
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
                              child: FilledButton.tonal(
                                onPressed: () {
                                  Get.toNamed('/api-endpoints');
                                },
                                style: FilledButton.styleFrom(
                                  foregroundColor: context.text,
                                  backgroundColor: context.bgInput,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Sample Endpoints & Testing'),
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

              _sectionGroup(
                context,
                title: 'Storage & Tools',
                children: [
                  _surfaceCard(
                    context,
                    borderColor: context.border,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      title: Text(
                        'Model Storage',
                        style: TextStyle(color: context.text, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(modelManager.modelsDir, style: TextStyle(color: context.textD, fontSize: 12)),
                      trailing: null,
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: modelManager.modelsDir));
                        Get.snackbar('Path Copied', 'Model storage path copied to clipboard.', snackPosition: SnackPosition.BOTTOM);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _surfaceCard(
                    context,
                    borderColor: context.border,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      title: Text(
                        'App Logs',
                        style: TextStyle(color: context.text, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('View logs, errors & share with developers', style: TextStyle(color: context.textD, fontSize: 12)),
                      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: context.textD),
                      onTap: () => Get.toNamed('/logs'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _surfaceCard(
                    context,
                    borderColor: context.border,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      title: Text(
                        'Clear Temporary Cache',
                        style: TextStyle(color: context.text, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Remove temporary app files', style: TextStyle(color: context.textD, fontSize: 12)),
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
                  ),
                ],
              ),

              _sectionGroup(
                context,
                title: 'Danger Zone',
                children: [
                  _boxedTile(
                    context,
                    title: 'Delete All Chats',
                    subtitle: 'Remove every conversation from this device',
                    trailing: null,
                    surface: context.bgPanel,
                    borderColor: AppColors.red.withValues(alpha: 0.25),
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

  Widget _header(BuildContext context) {
    return Padding(
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
          border: Border(
            bottom: BorderSide(color: context.borderFaint, width: 1),
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(
                  showBackButton ? Icons.arrow_back_rounded : Icons.menu_rounded,
                  size: 22,
                  color: context.text,
                ),
                onPressed: showBackButton
                    ? () => Get.back()
                    : (onOpenDrawer ?? () => Scaffold.of(context).openDrawer()),
              ),
            ),
            Center(
              child: Text(
                'Settings',
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
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: context.textM,
        letterSpacing: 0.6,
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
    return _surfaceCard(
      context,
      color: surface,
      borderColor: borderColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: leadingIcon == null
            ? null
            : CircleAvatar(
                radius: 16,
                backgroundColor: (leadingColor ?? context.accent).withValues(alpha: 0.14),
                child: Icon(
                  leadingIcon,
                  size: 18,
                  color: leadingColor ?? context.accent,
                ),
              ),
        title: Text(
          title,
          style: TextStyle(
            color: context.text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: context.textD, fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _materialSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    Color? activeThumbColor,
  }) {
    return _surfaceCard(
      context,
      color: context.bgInput,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(
          title,
          style: TextStyle(
            color: context.text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: context.textD, fontSize: 12),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: activeThumbColor,
        ),
      ),
    );
  }

  Widget _tempPresetChip(
    BuildContext context,
    ChatController chatCtrl,
    double value,
    String label,
    double temperature,
  ) {
    final selected = (temperature - value).abs() < 0.05;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => chatCtrl.updateTemperature(value),
      labelStyle: TextStyle(
        color: context.text,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      checkmarkColor: Colors.white,
      selectedColor: context.accent.withValues(alpha: 0.18),
      backgroundColor: context.bgInput,
      side: BorderSide(
        color: selected ? context.accent.withValues(alpha: 0.45) : Colors.transparent,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  Widget _sectionGroup(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, title),
          const SizedBox(height: 10),
          _surfaceCard(
            context,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _interleave(children, const SizedBox(height: 10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boxedTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? surface,
    Color? borderColor,
  }) {
    return _surfaceCard(
      context,
      color: surface,
      borderColor: borderColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Text(
          title,
          style: TextStyle(color: context.text, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: context.textD, fontSize: 12)),
        trailing: trailing,
        onTap: onTap,
      ),
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

  Widget _surfaceCard(
    BuildContext context, {
    required Widget child,
    Color? color,
    Color? borderColor,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color ?? context.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }

  Widget _statusChip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
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
        color: context.bgInput,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Recommended Auto Config ──
          Text(
            'Compute Device',
            style: TextStyle(color: context.text, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Current: $_currentConfigLabel',
            style: TextStyle(color: context.textM, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Recommended button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.border.withValues(alpha: 0.6)),
            ),
            child: SizedBox(
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
                  side: BorderSide.none,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
            color: selected ? context.accent.withValues(alpha: 0.18) : context.bgPanel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? context.accent.withValues(alpha: 0.55) : context.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: context.text,
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

