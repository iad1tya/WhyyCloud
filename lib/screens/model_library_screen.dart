import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../controllers/model_controller.dart';
import '../services/model_manager.dart';
import '../models/ai_model_info.dart';
import '../widgets/model_card.dart';

class ModelLibraryScreen extends StatelessWidget {
  final bool embedded;
  final VoidCallback? onOpenDrawer;

  const ModelLibraryScreen({super.key, this.embedded = false, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return _ModelLibraryBody(showBackButton: false, onOpenDrawer: onOpenDrawer);
    }
    return Scaffold(
      backgroundColor: context.bg,
      body: _ModelLibraryBody(showBackButton: true),
    );
  }
}

enum _Filter { all, downloaded, uncensored, custom }

class _HeaderTitle extends StatelessWidget {
  final String label;

  const _HeaderTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: context.text,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ModelLibraryBody extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onOpenDrawer;

  const _ModelLibraryBody({this.showBackButton = false, this.onOpenDrawer});

  @override
  State<_ModelLibraryBody> createState() => _ModelLibraryBodyState();
}

class _ModelLibraryBodyState extends State<_ModelLibraryBody> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ModelController>();
    final manager = Get.find<ModelManager>();

    return Column(
      children: [
        // ── Curved header ────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            widget.showBackButton ? MediaQuery.of(context).padding.top + 12 : 12,
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
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: widget.showBackButton
                      ? IconButton(
                          icon: Icon(Icons.arrow_back_rounded, size: 22, color: context.text),
                          onPressed: () => Get.back(),
                        )
                      : IconButton(
                          icon: Icon(Icons.menu_rounded, size: 22, color: context.textM),
                          onPressed: widget.onOpenDrawer ?? () => Scaffold.of(context).openDrawer(),
                        ),
                ),
                const Center(
                  child: _HeaderTitle(label: 'Models'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: _ImportButton(ctrl: ctrl),
                ),
              ],
            ),
          ),
        ),

        // ── Filter chips ─────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: context.bgPanel,
              borderRadius: BorderRadius.circular(22),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(context, 'All', _Filter.all),
                  _chip(context, 'Downloaded', _Filter.downloaded),
                  _chip(context, 'Uncensored', _Filter.uncensored),
                  _chip(context, 'Custom', _Filter.custom),
                ],
              ),
            ),
          ),
        ),

        // ── Body ─────────────────────────────────────
        Expanded(
          child: Obx(() {
            final allCatalog = ctrl.catalog.toList();
            final downloaded = manager.downloadedModels.toList();
            final _ = manager.activeDownloads.length;
            // ignore: unused_local_variable
            final tick = manager.tick.value;

            // Apply filter
            List<AiModelInfo> filtered;
            switch (_filter) {
              case _Filter.downloaded:
                filtered = allCatalog
                    .where((m) => downloaded.contains(m.filename))
                    .toList();
                break;
              case _Filter.uncensored:
                filtered = allCatalog.where((m) => m.isUncensored).toList();
                break;
              case _Filter.custom:
                filtered = allCatalog.where((m) => m.isCustom).toList();
                break;
              case _Filter.all:
                filtered = allCatalog;
            }

            // Always sort the active model to the top if it's in the filtered list
            final activeFilename = ctrl.selectedModelFilename.value;
            if (activeFilename != null) {
              filtered.sort((a, b) {
                if (a.filename == activeFilename) return -1;
                if (b.filename == activeFilename) return 1;
                return 0; // maintain relative order for the rest
              });
            }

            if (allCatalog.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.widgets_outlined,
                      size: 48,
                      color: context.textD,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No models in catalog.',
                      style: TextStyle(color: context.textD, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_off_rounded,
                      size: 40,
                      color: context.textD,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No models match this filter.',
                      style: TextStyle(color: context.textD, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                // ── Local files not in catalog ──────────
                if (_filter == _Filter.all ||
                    _filter == _Filter.downloaded) ...[
                  ...downloaded
                      .where((f) => !allCatalog.any((m) => m.filename == f))
                      .map((f) => _localFileCard(context, ctrl, f)),
                ],

                // ── Count ───────────────────────────────
                _sectionTitle(
                  context,
                  '${_filter == _Filter.all ? "Available" : _filter.name[0].toUpperCase() + _filter.name.substring(1)} Models (${filtered.length})',
                ),
                const SizedBox(height: 12),

                // ── Model cards ─────────────────────────
                ...List.generate(filtered.length, (index) {
                  final model = filtered[index];
                  final isDl = downloaded.contains(model.filename);
                  final isActiveDownload = manager.isDownloading(
                    model.filename,
                  );
                  final dlState = manager.getDownloadState(model.filename);

                  return Column(
                    children: [
                      ModelCard(
                        model: model,
                        isDownloaded: isDl,
                        isCurrentlyDownloading: isActiveDownload,
                        downloadState: dlState,
                        isLoaded:
                            ctrl.selectedModelFilename.value ==
                                model.filename &&
                            ctrl.isModelLoaded,
                        isLoadingModel:
                            ctrl.loadingModelFilename.value == model.filename,
                        loadingStatusMsg: ctrl.loadingStatusMsg.value,
                        loadingProgress: ctrl.loadingProgress.value,
                        onDownload: () => ctrl.downloadModel(model),
                        onCancelDownload: () =>
                            ctrl.cancelDownload(model.filename),
                        onLoad: () => ctrl.loadModel(model.filename),
                        onDelete: () => _confirmDelete(context, ctrl, model),
                        onRemoveCustom: () =>
                            _confirmRemoveCustom(context, ctrl, model),
                        onCancelLoad: () => ctrl.cancelLoadModel(),
                        onUnload: () => ctrl.unloadCurrentModel(),
                      ),
                    ],
                  ).animate().fadeIn(
                    delay: Duration(milliseconds: index * 50),
                    duration: 250.ms,
                  );
                }),

                const SizedBox(height: 24),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, _Filter filter) {
    final selected = _filter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? (ThemeData.estimateBrightnessForColor(context.accent) == Brightness.dark
                    ? Colors.white
                    : Colors.black)
                : context.textM,
          ),
        ),
        selected: selected,
        onSelected: (_) => setState(() => _filter = filter),
        selectedColor: context.accent,
        backgroundColor: context.bgInput,
        side: BorderSide(color: selected ? context.accent : context.borderFaint),
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _localFileCard(
    BuildContext context,
    ModelController ctrl,
    String filename,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgPanel,
        border: Border.all(color: context.borderFaint),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: 17, color: context.textD),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              filename,
              style: TextStyle(fontSize: 13, color: context.text),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => ctrl.loadModel(filename),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Load',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.textD,
        letterSpacing: 0.2,
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ModelController ctrl,
    AiModelInfo model,
  ) async {
    final confirmed = await showDialog<bool?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.bgPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Model File', style: TextStyle(color: dialogContext.text)),
        content: Text(
          'Delete ${model.name}? (${model.sizeGb} GB will be freed)',
          style: TextStyle(color: dialogContext.textM),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: TextStyle(color: dialogContext.textD)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              elevation: 0,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      ctrl.deleteModel(model.filename);
    }
  }

  Future<void> _confirmRemoveCustom(
    BuildContext context,
    ModelController ctrl,
    AiModelInfo model,
  ) async {
    final confirmed = await showDialog<bool?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.bgPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove Custom Model',
          style: TextStyle(color: dialogContext.text),
        ),
        content: Text(
          'Remove "${model.name}" from your library?\nThis will also delete the downloaded file if any.',
          style: TextStyle(color: dialogContext.textM),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: TextStyle(color: dialogContext.textD)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              elevation: 0,
            ),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      ctrl.deleteCustomModel(model);
      Get.snackbar(
        'Removed',
        '${model.name} removed from library.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

/// Pill button for the import action
class _ImportButton extends StatelessWidget {
  final ModelController ctrl;
  const _ImportButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.accent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _showImportOptions(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 15,
                color: ThemeData.estimateBrightnessForColor(context.accent) == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              const SizedBox(width: 4),
              Text(
                'Import',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ThemeData.estimateBrightnessForColor(context.accent) == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.textD,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Import Model',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.text,
                ),
              ),
              const SizedBox(height: 16),
              _importTile(
                context,
                title: 'Import .gguf File',
                subtitle: 'Select a single model file',
                onTap: () {
                  Navigator.pop(context);
                  ctrl.importModelFromFile();
                },
              ),
              _importTile(
                context,
                title: 'Import from Folder',
                subtitle: 'Scan folder for .gguf files',
                onTap: () {
                  Navigator.pop(context);
                  ctrl.importFromDirectory();
                },
              ),
              _importTile(
                context,
                title: 'Add from URL',
                subtitle: 'Download a .gguf model from a URL',
                onTap: () {
                  Navigator.pop(context);
                  _showAddUrlDialog(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _importTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: context.bgPanel,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.borderFaint),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: context.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(color: context.textD, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.textD, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddUrlDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.bgPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Model from URL',
          style: TextStyle(color: dialogContext.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: dialogContext.text, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Model Name',
                labelStyle: TextStyle(color: dialogContext.textD, fontSize: 13),
                hintText: 'e.g. Mistral 7B Uncensored',
                hintStyle: TextStyle(color: dialogContext.textD.withValues(alpha: 0.5)),
                filled: true,
                fillColor: dialogContext.bgInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: dialogContext.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: dialogContext.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: dialogContext.accent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              style: TextStyle(color: dialogContext.text, fontSize: 14),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Download URL',
                labelStyle: TextStyle(color: dialogContext.textD, fontSize: 13),
                hintText: 'https://huggingface.co/.../model.gguf',
                hintStyle: TextStyle(color: dialogContext.textD.withValues(alpha: 0.5)),
                filled: true,
                fillColor: dialogContext.bgInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: dialogContext.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: dialogContext.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: dialogContext.accent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: dialogContext.textD)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final url = urlCtrl.text.trim();
              Navigator.of(dialogContext).pop({'name': name, 'url': url});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Add Model',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    urlCtrl.dispose();

    if (result == null) return;
    final name = result['name'] ?? '';
    final url = result['url'] ?? '';
    if (name.isEmpty || url.isEmpty) {
      Get.snackbar(
        'Missing Info',
        'Please enter both name and URL.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (!url.startsWith('http')) {
      Get.snackbar(
        'Invalid URL',
        'URL must start with http:// or https://',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 16));
    ctrl.addCustomUrlModel(name: name, url: url);
  }
}
