import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../controllers/chat_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/model_controller.dart';
import '../controllers/update_controller.dart';
import '../routes/app_routes.dart';
import '../services/local_api_server_service.dart';
import '../services/model_manager.dart';
import '../services/background_optimizer_service.dart';
import '../services/chat_storage_service.dart';

class SettingsScreen extends StatelessWidget {
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              _sectionTitle(context, 'Preferences'),
              const SizedBox(height: 8),
              _optionSection(
                context,
                children: [
                  _toggleRow(
                    context,
                    title: 'Theme mode',
                    value: themeCtrl.isDarkMode,
                    valueLabel: themeCtrl.isDarkMode ? 'Dark' : 'Light',
                    onChanged: (val) => themeCtrl.toggleTheme(),
                  ),
                  _actionRow(
                    context,
                    title: 'Model Library',
                    value: 'Open',
                    onTap: () => Get.toNamed(AppRoutes.modelLibrary),
                  ),
                  _actionRow(
                    context,
                    title: 'Global Prompt',
                    value: chatCtrl.systemPrompt.value.isEmpty
                        ? 'Default'
                        : 'Custom',
                    onTap: () => _showPromptEditor(context, chatCtrl),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              _sectionTitle(context, 'Connection'),
              const SizedBox(height: 8),
              _optionSection(
                context,
                children: [
                  Obx(
                    () => _toggleRow(
                      context,
                      title: 'Local API server',
                      value: apiServer.isRunning.value,
                      valueLabel: apiServer.isRunning.value ? 'On' : 'Off',
                      onChanged: apiServer.isStarting.value
                          ? null
                          : (enabled) async {
                              try {
                                if (enabled) {
                                  await apiServer.start();
                                } else {
                                  await apiServer.stop();
                                }
                              } catch (e) {}
                            },
                    ),
                  ),
                  _actionRow(
                    context,
                    title: 'API Port',
                    value: apiServer.port.value.toString(),
                    onTap: () => _showPortEditor(context, apiServer),
                  ),
                  Obx(
                    () => _toggleRow(
                      context,
                      title: 'Allow External Connections',
                      value: apiServer.allInterfaces.value,
                      valueLabel: apiServer.allInterfaces.value ? 'On' : 'Off',
                      onChanged: apiServer.isStarting.value
                          ? null
                          : (enabled) async {
                              try {
                                await apiServer.setAllInterfaces(enabled);
                              } catch (e) {}
                            },
                    ),
                  ),
                  _actionRow(
                    context,
                    title: 'Sample Endpoints',
                    value: 'Test',
                    onTap: () => Get.toNamed(AppRoutes.apiEndpoints),
                  ),
                ],
              ),
              Obx(
                () => apiServer.isRunning.value
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _localApiInfoCard(context, apiServer),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 14),
              _sectionTitle(context, 'System'),
              const SizedBox(height: 8),
              _optionSection(
                context,
                children: [
                  _actionRow(
                    context,
                    title: 'Compute Device',
                    value: _hardwareSummary(storage),
                    onTap: () => _showHardwareSheet(context, storage),
                  ),
                  if (Platform.isAndroid)
                    _actionRow(
                      context,
                      title: 'Battery Optimization',
                      value: '',
                      onTap: () async {
                        await BackgroundOptimizerService.openBatterySettings();
                      },
                    ),
                  _actionRow(
                    context,
                    title: 'Model Storage',
                    value: 'Copy',
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: modelManager.modelsDir),
                      );
                    },
                  ),
                  _actionRow(
                    context,
                    title: 'App Logs',
                    value: 'Open',
                    onTap: () => Get.toNamed(AppRoutes.logs),
                  ),
                  _actionRow(
                    context,
                    title: 'Clear Temporary Cache',
                    value: 'Clear',
                    onTap: () async {
                      await Get.find<ModelController>().clearCache();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),
              _sectionTitle(context, 'Updates'),
              const SizedBox(height: 8),
              _optionSection(
                context,
                children: [
                  GetX<UpdateController>(
                    init: Get.find<UpdateController>(),
                    builder: (updateCtrl) {
                      return _actionRow(
                        context,
                        title: 'Check for updates',
                        value: updateCtrl.isChecking.value ? 'Checking...' : '',
                        onTap: () async {
                          if (updateCtrl.isChecking.value) return;
                          await updateCtrl.checkForUpdates();
                          if (updateCtrl.isUpdateAvailable.value) {
                            _showUpdateDialog(context, updateCtrl);
                          }
                        },
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),
              _sectionTitle(context, 'Find us on'),
              const SizedBox(height: 8),
              _optionSection(
                context,
                children: [
                  _actionRow(
                    context,
                    title: 'Star the repo',
                    value: '',
                    onTap: () async {
                      final url = Uri.parse(
                        'https://github.com/iad1tya/WhyyCloud',
                      );
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                  _actionRow(
                    context,
                    title: 'Follow dev on Instagram',
                    value: '',
                    onTap: () async {
                      final url = Uri.parse('https://instagram.com/iad1tya');
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                  _actionRow(
                    context,
                    title: 'Follow dev on X',
                    value: '',
                    onTap: () async {
                      final url = Uri.parse('https://x.com/xad1tya');
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),
              _sectionTitle(context, 'Danger Zone'),
              const SizedBox(height: 8),
              _optionSection(
                context,
                children: [
                  _destructiveRow(
                    context,
                    title: 'Delete All Chats',
                    onTap: () => _confirmDeleteAllChats(context, chatCtrl),
                  ),
                  _destructiveRow(
                    context,
                    title: 'Reinstall the App',
                    onTap: () => _confirmReinstallApp(
                      context,
                      chatCtrl: chatCtrl,
                      themeCtrl: themeCtrl,
                      apiServer: apiServer,
                      storage: storage,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
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
                  showBackButton
                      ? Icons.arrow_back_rounded
                      : Icons.menu_rounded,
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

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: context.textM,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _optionSection(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderFaint),
      ),
      child: Column(
        children: _interleave(
          children,
          Divider(height: 1, thickness: 1, color: context.borderFaint),
        ),
      ),
    );
  }

  Widget _actionRow(
    BuildContext context, {
    required String title,
    required String value,
    required VoidCallback onTap,
    Color? valueColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: context.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value.isNotEmpty) ...[
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? context.textM,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right_rounded, size: 20, color: context.textD),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
    String? valueLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: context.text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (valueLabel != null) ...[
            Text(
              valueLabel,
              style: TextStyle(
                color: value ? context.accent : context.textM,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: context.accent,
          ),
        ],
      ),
    );
  }

  Widget _destructiveRow(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.red.withValues(alpha: 0.85),
            ),
          ],
        ),
      ),
    );
  }

  String _hardwareSummary(ChatStorageService storage) {
    switch (storage.backendType) {
      case 'vulkan':
        return 'GPU Vulkan';
      case 'opencl':
        return 'GPU OpenCL';
      default:
        return 'CPU Only';
    }
  }

  Widget _localApiInfoCard(
    BuildContext context,
    LocalApiServerService apiServer,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderFaint),
      ),
      child: Obx(() {
        final external = apiServer.allInterfaces.value;
        final loopbackRoot = 'http://127.0.0.1:${apiServer.port.value}';
        final baseUrl = apiServer.baseUrl;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dns_rounded, size: 18, color: context.accent),
                const SizedBox(width: 8),
                Text(
                  'Local API Details',
                  style: TextStyle(
                    color: context.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Running',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(context, 'Server URL', loopbackRoot),
            const SizedBox(height: 8),
            _infoRow(context, 'API Base URL', baseUrl),
            const SizedBox(height: 8),
            _infoRow(context, 'Health check', 'GET $loopbackRoot/healthz'),
            const SizedBox(height: 8),
            _infoRow(context, 'Models endpoint', 'GET $baseUrl/models'),
            const SizedBox(height: 8),
            _infoRow(
              context,
              'Chat endpoint',
              'POST $baseUrl/chat/completions',
            ),
            const SizedBox(height: 8),
            _infoRow(
              context,
              'Binding',
              external ? 'All network interfaces' : 'Local device only',
            ),
            if (external) ...[
              const SizedBox(height: 8),
              _infoRow(
                context,
                'LAN access',
                'Use http://<device-ip>:${apiServer.port.value}/v1 from another device',
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Use these endpoints in apps that speak the OpenAI API format.',
              style: TextStyle(color: context.textD, fontSize: 12, height: 1.4),
            ),
          ],
        );
      }),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyle(
              color: context.textD,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: context.text, fontSize: 12, height: 1.35),
          ),
        ),
      ],
    );
  }

  Future<void> _showPromptEditor(
    BuildContext context,
    ChatController chatCtrl,
  ) async {
    final result = await Get.to<String?>(
      () => _PromptEditorPage(initialText: chatCtrl.systemPrompt.value),
    );

    if (result == null) return;
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    if (result.isEmpty) {
      chatCtrl.clearGlobalSystemPrompt();
    } else {
      chatCtrl.setGlobalSystemPrompt(result);
    }
  }

  Future<void> _showPortEditor(
    BuildContext context,
    LocalApiServerService apiServer,
  ) async {
    final controller = TextEditingController(
      text: apiServer.port.value.toString(),
    );
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.bgPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('API Port', style: TextStyle(color: dialogContext.text)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: dialogContext.text, fontSize: 14),
          decoration: InputDecoration(
            hintText: '4891',
            filled: true,
            fillColor: dialogContext.bgInput,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(dialogContext).pop();
            },
            child: Text('Cancel', style: TextStyle(color: dialogContext.textD)),
          ),
          ElevatedButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(dialogContext).pop(controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null) return;
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    final parsed = int.tryParse(result);
    if (parsed == null || parsed < 1024 || parsed > 65535) {
      return;
    }
    await apiServer.setPort(parsed);
  }

  Future<void> _showHardwareSheet(
    BuildContext context,
    ChatStorageService storage,
  ) async {
    await Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: context.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: SingleChildScrollView(
            child: _HardwareSettingsCard(storage: storage),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _confirmDeleteAllChats(
    BuildContext context,
    ChatController chatCtrl,
  ) async {
    final confirmed = await Get.dialog<bool?>(
      AlertDialog(
        backgroundColor: context.bgPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete All Chats?', style: TextStyle(color: context.text)),
        content: Text(
          'This removes every conversation from this device.',
          style: TextStyle(color: context.textM),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: TextStyle(color: context.textD)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Get.find<ChatStorageService>().deleteAllChats();
      chatCtrl.chats.clear();
      chatCtrl.activeChatId.value = null;
    }
  }

  Future<void> _confirmReinstallApp(
    BuildContext context, {
    required ChatController chatCtrl,
    required ThemeController themeCtrl,
    required LocalApiServerService apiServer,
    required ChatStorageService storage,
  }) async {
    final confirmed = await Get.dialog<bool?>(
      AlertDialog(
        backgroundColor: context.bgPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reinstall the App?',
          style: TextStyle(color: context.text),
        ),
        content: Text(
          'This resets chats, prompts, API settings, hardware settings, theme, and temporary cache to defaults.',
          style: TextStyle(color: context.textM),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: TextStyle(color: context.textD)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await apiServer.stop();
    await Get.find<ChatStorageService>().deleteAllChats();
    chatCtrl.chats.clear();
    chatCtrl.activeChatId.value = null;
    chatCtrl.clearGlobalSystemPrompt();
    chatCtrl.updateTemperature(0.7);
    themeCtrl.resetToDefault();
    await Get.find<ModelController>().unloadModel();
    await Get.find<ModelController>().clearCache();
    storage.backendType = 'cpu';
    storage.gpuLayers = 0;
    storage.lastModelId = '';
    await apiServer.resetToDefaults();
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

  void _showUpdateDialog(BuildContext context, UpdateController updateCtrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.bgPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Update Available',
          style: TextStyle(color: dialogContext.text),
        ),
        content: Obx(() {
          if (updateCtrl.isDownloading.value) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Downloading update...',
                  style: TextStyle(color: dialogContext.textM),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: updateCtrl.downloadProgress.value,
                  backgroundColor: dialogContext.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    dialogContext.accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(updateCtrl.downloadProgress.value * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: dialogContext.textD, fontSize: 12),
                ),
              ],
            );
          }
          if (updateCtrl.downloadedFilePath.value.isNotEmpty) {
            return Text(
              'Download complete! Ready to install.',
              style: TextStyle(color: dialogContext.textM),
            );
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Version ${updateCtrl.latestVersion.value} is available.',
                  style: TextStyle(
                    color: dialogContext.textM,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  updateCtrl.latestReleaseNotes.value,
                  style: TextStyle(color: dialogContext.textD, fontSize: 13),
                ),
              ],
            ),
          );
        }),
        actions: [
          Obx(() {
            if (updateCtrl.isDownloading.value) {
              return const SizedBox.shrink();
            }
            return TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                updateCtrl.downloadedFilePath.value = '';
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: dialogContext.textD),
              ),
            );
          }),
          Obx(() {
            if (updateCtrl.isDownloading.value) {
              return const SizedBox.shrink();
            }
            if (updateCtrl.downloadedFilePath.value.isNotEmpty) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  updateCtrl.installUpdate();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text(
                  'Install',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            final isDark =
                ThemeData.estimateBrightnessForColor(context.accent) ==
                Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black;
            return ElevatedButton(
              onPressed: () => updateCtrl.downloadUpdate(),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accent,
                foregroundColor: textColor,
                elevation: 0,
              ),
              child: Text('Download', style: TextStyle(color: textColor)),
            );
          }),
        ],
      ),
    );
  }
}

class _PromptEditorPage extends StatefulWidget {
  final String initialText;

  const _PromptEditorPage({required this.initialText});

  @override
  State<_PromptEditorPage> createState() => _PromptEditorPageState();
}

class _PromptEditorPageState extends State<_PromptEditorPage> {
  late final TextEditingController _controller;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final changed = _controller.text.trim() != widget.initialText.trim();
    if (changed != _changed) {
      setState(() => _changed = changed);
    }
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bgPanel,
        elevation: 0,
        title: Text('Global Prompt', style: TextStyle(color: context.text)),
        iconTheme: IconThemeData(color: context.text),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(color: context.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. You are a helpful assistant...',
                    filled: true,
                    fillColor: context.bgPanel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(''),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: BorderSide(
                          color: AppColors.red.withValues(alpha: 0.6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _changed ? _save : null,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.disabled))
                            return context.borderFaint;
                          return context.accent;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          final bg = states.contains(WidgetState.disabled)
                              ? context.borderFaint
                              : context.accent;
                          return ThemeData.estimateBrightnessForColor(bg) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black;
                        }),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 14),
                        ),
                        elevation: WidgetStateProperty.all(0),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  static Map<String, dynamic> _detectBestConfig() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return {
        'backend': 'cpu',
        'gpuLayers': 0,
        'reason': 'CPU mode — most compatible on desktop',
      };
    }

    final cores = Platform.numberOfProcessors;

    if (cores >= 8) {
      return {
        'backend': 'opencl',
        'gpuLayers': 33,
        'reason': 'OpenCL GPU — best for high-end SoC ($cores cores detected)',
      };
    } else if (cores >= 6) {
      return {
        'backend': 'cpu',
        'gpuLayers': 0,
        'reason': 'CPU mode — safe for mid-range devices ($cores cores)',
      };
    } else {
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
  }

  void _saveBackend(String val) {
    setState(() => _backend = val);
    widget.storage.backendType = val;

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
          Text(
            'Compute Device',
            style: TextStyle(
              color: context.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current: $_currentConfigLabel',
            style: TextStyle(color: context.textM, fontSize: 12),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.border.withValues(alpha: 0.6)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _applyAutoConfig,
                icon: Icon(Icons.tune_rounded, size: 16, color: context.text),
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
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: context.accent,
                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.bgInput,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _gpuLayers.toInt().toString(),
                    style: TextStyle(
                      color: context.text,
                      fontWeight: FontWeight.bold,
                    ),
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
            color: selected
                ? context.accent.withValues(alpha: 0.18)
                : context.bgPanel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? context.accent.withValues(alpha: 0.55)
                  : context.border,
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
