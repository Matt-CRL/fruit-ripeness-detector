import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/app/theme/app_colors.dart';
import 'package:kami/core/database/app_database_provider.dart';
import 'package:kami/core/layout/kami_responsive.dart';
import 'package:kami/features/history/application/save_scan_result.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/scan/application/scan_service_providers.dart';
import 'package:kami/features/scan/data/image_picker_scan_image_picker.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/scan/presentation/ripeness_stage_style.dart';
import 'package:kami/features/scan/presentation/scan_image_provider.dart';
import 'package:kami/features/scan/presentation/model_confidence_indicator.dart';
import 'package:kami/features/scan/presentation/shelf_life_guidance_card.dart';
import 'package:kami/features/scan/presentation/grad_cam_view.dart';

enum LowConfidenceAction { uploadNewPhoto }

final class LowConfidencePreview {
  const LowConfidencePreview({
    required this.image,
    required this.classification,
  });

  final SelectedScanImage image;
  final ClassificationResult classification;
}

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({this.openedFromRescan = false, super.key});

  final bool openedFromRescan;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  SelectedScanImage? _selectedImage;
  String _errorTitle = 'Gallery unavailable';
  String? _errorMessage;
  bool _isPicking = false;
  bool _isClassifying = false;
  bool _previewReady = false;

  bool get _isBusy => _isPicking || _isClassifying;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _recoverLostSelection(),
    );
  }

  Future<void> _recoverLostSelection() async {
    try {
      final recovered = await ref
          .read(scanImagePickerProvider)
          .recoverLostSelection();
      if (mounted && recovered != null) {
        _applySelection(recovered);
      }
    } on Object {
      if (mounted) {
        setState(() {
          _errorTitle = 'Gallery unavailable';
          _errorMessage =
              'An interrupted gallery selection could not be recovered.';
        });
      }
    }
  }

  Future<void> _chooseFromGallery() async {
    setState(() {
      _isPicking = true;
      _errorTitle = 'Gallery unavailable';
      _errorMessage = null;
    });

    try {
      final selected = await ref
          .read(scanImagePickerProvider)
          .pickFromGallery();
      if (mounted && selected != null) {
        _applySelection(selected);
      }
    } on Object {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Chami could not open that image. Please choose another one.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  void _applySelection(SelectedScanImage selected) {
    setState(() {
      _selectedImage = selected;
      _previewReady = true;
      _errorMessage = null;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedImage = null;
      _previewReady = false;
      _errorMessage = null;
    });
  }

  void _setPreviewReady(bool ready) {
    if (_previewReady == ready || !mounted) {
      return;
    }
    setState(() => _previewReady = ready);
  }

  Future<void> _usePhoto() async {
    final image = _selectedImage;
    if (image == null || !_previewReady) {
      return;
    }

    setState(() {
      _isClassifying = true;
      _errorTitle = 'Assessment unavailable';
      _errorMessage = null;
    });

    try {
      final classifier = ref.read(ripenessClassifierProvider);
      final result = await classifier.classify(image.path);

      if (!mounted) {
        return;
      }

      if (result.requiresRetake) {
        await _openLowConfidenceResult(image, result);
        return;
      }

      final advisor = ref.read(shelfLifeAdvisorProvider);
      final preview = ScanPreview(
        image: image,
        classification: result,
        shelfLife: advisor.estimate(result),
      );

      await context.push(AppRoutes.scanResult, extra: preview);
    } on RipenessClassificationException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.userMessage;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Chami could not assess that image. Please choose another photo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isClassifying = false);
      }
    }
  }

  Future<void> _openLowConfidenceResult(
    SelectedScanImage image,
    ClassificationResult result,
  ) async {
    final action = await context.push<LowConfidenceAction>(
      AppRoutes.scanRetake,
      extra: LowConfidencePreview(
        image: image,
        classification: result,
      ),
    );
    if (!mounted) {
      return;
    }
    if (action == LowConfidenceAction.uploadNewPhoto) {
      await _chooseFromGallery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedImage = _selectedImage;
    final selectedImageProvider = selectedImage == null
        ? null
        : ref.watch(scanImageProviderFactoryProvider)(selectedImage.path);

    void leaveRescanFlow() => context.go(AppRoutes.scan, extra: true);

    return PopScope(
      canPop: !widget.openedFromRescan,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.openedFromRescan && context.mounted) {
          leaveRescanFlow();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: widget.openedFromRescan
              ? IconButton(
                  onPressed: leaveRescanFlow,
                  tooltip: 'Back to scan methods',
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
          title: const Text('Upload image'),
        ),
        body: ListView(
          padding: KamiResponsive.pagePadding(context, top: 8, bottom: 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Upload one fruit image',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Choose one clear photo with one fruit centered in the '
                      'frame.',
                    ),
                    const SizedBox(height: 24),
                    if (selectedImage == null)
                      _EmptyUploadPanel(
                        busy: _isBusy,
                        isPicking: _isPicking,
                        onChoose: _chooseFromGallery,
                      )
                    else
                      _SelectedImagePanel(
                        image: selectedImage,
                        imageProvider: selectedImageProvider!,
                        busy: _isBusy,
                        previewReady: _previewReady,
                        onPreviewStateChanged: _setPreviewReady,
                        onChange: _chooseFromGallery,
                        onClear: _clearSelection,
                        onUse: _usePhoto,
                      ),
                    if (_isPicking) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(
                        semanticsLabel: 'Opening Android photo picker',
                      ),
                    ],
                    if (_errorMessage case final message?) ...[
                      const SizedBox(height: 16),
                      _InlineError(title: _errorTitle, message: message),
                    ],
                    const SizedBox(height: 20),
                    const _PreviewOnlyNotice(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyUploadPanel extends StatelessWidget {
  const _EmptyUploadPanel({
    required this.busy,
    required this.isPicking,
    required this.onChoose,
  });

  final bool busy;
  final bool isPicking;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.softBrandGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.brandGreen,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Choose a fruit photo',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use a bright, steady photo. Keep the fruit clear and '
              'unobstructed.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: busy ? null : onChoose,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                isPicking ? 'Opening gallery...' : 'Choose from gallery',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewOnlyNotice extends StatelessWidget {
  const _PreviewOnlyNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: const ListTile(
        leading: Icon(Icons.offline_bolt_outlined, color: AppColors.brandGreen),
        title: Text('Private, offline assessment'),
        subtitle: Text(
          'Chami evaluates the selected image on this device. Model validation '
          'is still in progress, so use the result as guidance only.',
        ),
      ),
    );
  }
}

class _SelectedImagePanel extends StatelessWidget {
  const _SelectedImagePanel({
    required this.image,
    required this.imageProvider,
    required this.busy,
    required this.previewReady,
    required this.onPreviewStateChanged,
    required this.onChange,
    required this.onClear,
    required this.onUse,
  });

  final SelectedScanImage image;
  final ImageProvider<Object> imageProvider;
  final bool busy;
  final bool previewReady;
  final ValueChanged<bool> onPreviewStateChanged;
  final VoidCallback onChange;
  final VoidCallback onClear;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: _SelectedImagePreview(
              key: ValueKey(image.path),
              imageProvider: imageProvider,
              onStateChanged: onPreviewStateChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.brandGreen,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    image.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: busy || !previewReady ? null : onUse,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(busy ? 'Assessing photo...' : 'Use photo'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: busy ? null : onClear,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : onChange,
                        child: const Text('Change'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedImagePreview extends StatefulWidget {
  const _SelectedImagePreview({
    required this.imageProvider,
    required this.onStateChanged,
    super.key,
  });

  final ImageProvider<Object> imageProvider;
  final ValueChanged<bool> onStateChanged;

  @override
  State<_SelectedImagePreview> createState() => _SelectedImagePreviewState();
}

class _SelectedImagePreviewState extends State<_SelectedImagePreview> {
  bool? _reportedState;

  void _report(bool ready) {
    if (_reportedState == ready) {
      return;
    }
    _reportedState = ready;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onStateChanged(ready);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Selected fruit image preview',
      child: Image(
        image: widget.imageProvider,
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          final ready = wasSynchronouslyLoaded || frame != null;
          if (ready) {
            _report(true);
            return child;
          }
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Loading selected image preview',
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          _report(false);
          return const _UnreadableImage();
        },
      ),
    );
  }
}

class _UnreadableImage extends StatelessWidget {
  const _UnreadableImage();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.errorContainer,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, size: 48),
              SizedBox(height: 12),
              Text(
                'This image could not be previewed. Choose another image.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: ListTile(
          leading: const Icon(Icons.error_outline),
          title: Text(title),
          subtitle: Text(message),
        ),
      ),
    );
  }
}

class ScanResultScreen extends ConsumerStatefulWidget {
  const ScanResultScreen({required this.preview, super.key});

  final ScanPreview? preview;

  @override
  ConsumerState<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends ConsumerState<ScanResultScreen> {
  late ScanPreview? _preview = widget.preview;
  late ClassificationResult? _initialClassification = widget.preview?.classification;
  RipenessStage? _userOverriddenStage;
  SavedScanRecord? _savedRecord;
  String? _assignedBatchId;
  String? _reservedScanId;
  String? _saveError;
  bool _saving = false;

  @override
  void didUpdateWidget(covariant ScanResultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preview != widget.preview) {
      _preview = widget.preview;
      _initialClassification = widget.preview?.classification;
      _userOverriddenStage = null;
      _resetSaveState();
    }
  }

  void _resetSaveState() {
    _savedRecord = null;
    _assignedBatchId = null;
    _reservedScanId = null;
    _saveError = null;
    _saving = false;
  }

  Future<void> _openRipenessIntervention() async {
    final preview = _preview;
    final initial = _initialClassification;
    if (preview == null || initial == null || _saving || _savedRecord != null) {
      return;
    }

    final selectedStage = await showModalBottomSheet<RipenessStage>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => RipenessInterventionSheet(
        currentRipeness: preview.classification.ripeness,
        modelRipeness: initial.ripeness,
        fruit: initial.fruit,
        modelConfidence: initial.modelConfidence,
        onDiscard: _discardScan,
      ),
    );

    if (!mounted || selectedStage == null) {
      return;
    }

    final advisor = ref.read(shelfLifeAdvisorProvider);
    if (selectedStage == initial.ripeness) {
      // Revert to initial AI prediction
      setState(() {
        _userOverriddenStage = null;
        _preview = ScanPreview(
          image: preview.image,
          classification: initial,
          shelfLife: advisor.estimate(initial),
        );
      });
    } else {
      // Apply user-verified stage
      final updatedClassification = ClassificationResult(
        fruit: initial.fruit,
        ripeness: selectedStage,
        modelConfidence: initial.modelConfidence,
        modelVersion: '${initial.modelVersion} (adjusted by user)',
        origin: initial.origin,
        requiresRetake: false,
        recognitionStatus: initial.recognitionStatus,
        heatmap: initial.heatmap,
        isolatedImageBytes: initial.isolatedImageBytes,
        gradCamImageBytes: initial.gradCamImageBytes,
      );
      setState(() {
        _userOverriddenStage = selectedStage;
        _preview = ScanPreview(
          image: preview.image,
          classification: updatedClassification,
          shelfLife: advisor.estimate(updatedClassification),
        );
      });
    }
  }

  Future<void> _discardScan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this scan?'),
        content: const Text(
          'This fruit assessment will be discarded. It will not be saved to History or any batches.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      context.go(AppRoutes.scan);
    }
  }

  void _rescan() {
    // Replace the current result instead of pushing a nested rescan route.
    // A fresh upload therefore has no "Return to previous result" affordance,
    // and Android Back returns to the scan method rather than looping through
    // earlier assessment results.
    context.pushReplacement(AppRoutes.scanUpload, extra: true);
  }

  Future<void> _chooseSaveResult() async {
    if (_saving || _savedRecord != null) {
      return;
    }
    final choice = await showModalBottomSheet<_SaveResultChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _SaveResultOptionsSheet(),
    );
    if (!mounted || choice == null) {
      return;
    }
    await _saveResult(addToBatch: choice == _SaveResultChoice.saveAndAdd);
  }

  Future<void> _saveResult({required bool addToBatch}) async {
    final preview = _preview;
    if (preview == null || _saving || _savedRecord != null) {
      return;
    }

    final scanId = _reservedScanId ??= ref
        .read(entityIdGeneratorProvider)
        .nextId();
    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      final record = await ref
          .read(saveScanResultUseCaseProvider)
          .execute(preview: preview, scanId: scanId);
      if (!mounted) {
        return;
      }
      setState(() {
        _savedRecord = record;
        _saving = false;
      });
      if (addToBatch) {
        await _openAddToBatch(record.id);
      }
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _saveError =
            'Chami could not save this result. Nothing was added to History. '
            'Check that the photo is still available, then try again.';
      });
    }
  }

  Future<void> _openAddToBatch(String scanId) async {
    final batchId = await context.push<String>(AppRoutes.addToBatch(scanId));
    if (!mounted || batchId == null) {
      return;
    }
    setState(() => _assignedBatchId = batchId);
  }

  @override
  Widget build(BuildContext context) {
    final value = _preview;
    if (value == null) {
      return const _MissingPreviewScreen();
    }

    final classification = value.classification;
    final shelfLife = value.shelfLife;
    final imageProvider = ref.watch(scanImageProviderFactoryProvider)(
      value.image.path,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Assessment result')),
      body: ListView(
        padding: KamiResponsive.pagePadding(context, top: 8, bottom: 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ResultImageCard(
                    imageName: value.image.name,
                    imageProvider: imageProvider,
                    isolatedImageBytes: null,
                    gradCamImageBytes: classification.gradCamImageBytes,
                    heatmap: classification.heatmap,
                  ),
                  const SizedBox(height: 16),
                  if (classification.origin == ResultOrigin.demo) ...[
                    const _FakePreviewNotice(),
                    const SizedBox(height: 16),
                  ],
                  _ResultSummaryCard(
                    classification: classification,
                    onVerifyOrChange: _savedRecord == null ? _openRipenessIntervention : null,
                    isUserVerified: _userOverriddenStage != null,
                    originalRipeness: _initialClassification?.ripeness,
                  ),
                  const SizedBox(height: 16),
                  ShelfLifeGuidanceCard(
                    estimate: shelfLife,
                    ripeness: classification.ripeness,
                    isUserAdjusted: _userOverriddenStage != null,
                  ),
                  const SizedBox(height: 16),
                  if (_saving ||
                      _savedRecord != null ||
                      _saveError != null) ...[
                    _SaveStatusNotice(
                      saving: _saving,
                      saved: _savedRecord != null,
                      errorMessage: _saveError,
                      origin: classification.origin,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_savedRecord == null) ...[
                    FilledButton.icon(
                      onPressed: _saving ? null : _chooseSaveResult,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                semanticsLabel: 'Saving result',
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving...' : 'Save Result'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _rescan,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Rescan'),
                    ),
                  ] else ...[
                    FilledButton.icon(
                      onPressed: _rescan,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('New Scan'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _assignedBatchId == null
                          ? _openAddToBatch(_savedRecord!.id)
                          : context.push(
                              AppRoutes.batchDetails(_assignedBatchId!),
                            ),
                      icon: Icon(
                        _assignedBatchId == null
                            ? Icons.playlist_add
                            : Icons.inventory_2_outlined,
                      ),
                      label: Text(
                        _assignedBatchId == null
                            ? 'Add to Batch'
                            : 'View batch',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => context.go(AppRoutes.history),
                      icon: const Icon(Icons.history),
                      label: const Text('View in History'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SaveResultChoice { historyOnly, saveAndAdd }

class _SaveResultOptionsSheet extends StatelessWidget {
  const _SaveResultOptionsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How would you like to save?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Both options safely store the result in History on this device.',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(_SaveResultChoice.historyOnly),
              icon: const Icon(Icons.history),
              label: const Text('Save to History'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(_SaveResultChoice.saveAndAdd),
              icon: const Icon(Icons.playlist_add),
              label: const Text('Save & Add to Batch'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ResultViewMode { isolated, original, gradCam }

class _ResultImageCard extends StatefulWidget {
  const _ResultImageCard({
    required this.imageName,
    required this.imageProvider,
    this.rejected = false,
    this.isolatedImageBytes,
    this.gradCamImageBytes,
    this.heatmap,
    this.initialViewMode,
  });

  final String imageName;
  final ImageProvider<Object> imageProvider;
  final bool rejected;
  final Uint8List? isolatedImageBytes;
  final Uint8List? gradCamImageBytes;
  final ActivationHeatmap? heatmap;
  final _ResultViewMode? initialViewMode;

  @override
  State<_ResultImageCard> createState() => _ResultImageCardState();
}

class _ResultImageCardState extends State<_ResultImageCard> {
  late _ResultViewMode _viewMode;

  @override
  void initState() {
    super.initState();
    final hasGradCam =
        widget.gradCamImageBytes != null || widget.heatmap != null;
    final requestedMode = widget.initialViewMode;
    _viewMode = requestedMode == _ResultViewMode.gradCam && !hasGradCam
        ? _ResultViewMode.original
        : requestedMode ??
            (widget.isolatedImageBytes != null
                ? _ResultViewMode.isolated
                : _ResultViewMode.original);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final ImageProvider<Object> activeProvider;
    switch (_viewMode) {
      case _ResultViewMode.isolated:
        activeProvider = widget.isolatedImageBytes != null
            ? MemoryImage(widget.isolatedImageBytes!)
            : widget.imageProvider;
      case _ResultViewMode.original:
        activeProvider = widget.imageProvider;
      case _ResultViewMode.gradCam:
        activeProvider = widget.gradCamImageBytes != null
            ? MemoryImage(widget.gradCamImageBytes!)
            : widget.imageProvider;
    }

    final hasGradCam =
        widget.gradCamImageBytes != null || widget.heatmap != null;
    final hasMultiView = widget.rejected
        ? hasGradCam
        : widget.isolatedImageBytes != null || hasGradCam;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            image: true,
            label: 'Assessment result image preview',
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(
                      key: ValueKey(activeProvider),
                      image: activeProvider,
                      fit: BoxFit.contain,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded || frame != null) {
                              return child;
                            }
                            return const Center(
                              child: CircularProgressIndicator(
                                semanticsLabel: 'Loading result image',
                              ),
                            );
                          },
                      errorBuilder: (context, error, stackTrace) {
                        return const _UnreadableImage();
                      },
                    ),
                    if (widget.heatmap != null &&
                        widget.gradCamImageBytes == null &&
                        _viewMode == _ResultViewMode.gradCam)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            key: const Key('rejected-gradcam-overlay'),
                            painter: ActivationHeatmapPainter(widget.heatmap!),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (hasMultiView) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: SegmentedButton<_ResultViewMode>(
                segments: [
                  if (!widget.rejected && widget.isolatedImageBytes != null)
                    const ButtonSegment(
                      value: _ResultViewMode.isolated,
                      label: Text('Isolated'),
                      icon: Icon(Icons.crop_outlined, size: 16),
                    ),
                  const ButtonSegment(
                    value: _ResultViewMode.original,
                    label: Text('Original'),
                    icon: Icon(Icons.photo_outlined, size: 16),
                  ),
                  if (hasGradCam)
                    const ButtonSegment(
                      value: _ResultViewMode.gradCam,
                      label: Text('Grad-CAM'),
                      icon: Icon(Icons.visibility_outlined, size: 16),
                    ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (selected) {
                  setState(() => _viewMode = selected.first);
                },
              ),
            ),
            if (_viewMode == _ResultViewMode.gradCam)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GradCamExplanationCard(),
              ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.imageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FakePreviewNotice extends StatelessWidget {
  const _FakePreviewNotice();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Demo preview warning. This is not a real fruit assessment.',
      child: Card(
        margin: EdgeInsets.zero,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.science_outlined, color: AppColors.brandGreen),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo preview only',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'This is not a real assessment. The image was not '
                      'evaluated by a model, so do not use this preview to '
                      'judge fruit quality.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultSummaryCard extends StatelessWidget {
  const _ResultSummaryCard({
    required this.classification,
    this.eyebrow,
    this.onVerifyOrChange,
    this.isUserVerified = false,
    this.originalRipeness,
  });

  final ClassificationResult classification;
  final String? eyebrow;
  final VoidCallback? onVerifyOrChange;
  final bool isUserVerified;
  final RipenessStage? originalRipeness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stageStyle = ripenessStageStyle(
      classification.ripeness,
      brightness: theme.brightness,
    );
    final confidencePercent = (classification.modelConfidence * 100).round();
    final isDemo = classification.origin == ResultOrigin.demo;
    final resultEyebrow = isUserVerified
        ? 'Final assessment'
        : (eyebrow ?? (isDemo ? 'Demo result' : 'On-device model result'));

    return Semantics(
      container: true,
      label:
          '$resultEyebrow. ${classification.fruit.displayName}, '
          '${classification.ripeness.displayName}, model confidence '
          '$confidencePercent percent.',
      child: Card(
        margin: EdgeInsets.zero,
        color: stageStyle.background,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: stageStyle.accent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      stageStyle.icon,
                      color: stageStyle.foreground,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              resultEyebrow,
                              style: theme.textTheme.labelLarge,
                            ),
                            if (isUserVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_note,
                                      size: 14,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Adjusted by user',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          classification.ripeness.displayName,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.eco_outlined, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      classification.fruit.displayName,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                key: const Key('model-confidence-card'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ModelConfidenceIndicator(
                      confidence: classification.modelConfidence,
                      accentColor: stageStyle.accent,
                      label: isDemo
                          ? 'Model confidence (demo)'
                          : 'Model confidence',
                      semanticsLabel: isDemo
                          ? 'Demo model confidence $confidencePercent percent'
                          : 'Model confidence $confidencePercent percent',
                    ),
                    if (isUserVerified && originalRipeness != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.psychology_outlined,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Model result: ${originalRipeness!.displayName} – $confidencePercent% confidence',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Your correction: ${classification.ripeness.displayName}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: AppColors.brandGreen,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Final assessment: ${classification.ripeness.displayName} – Adjusted by user',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (onVerifyOrChange != null) ...[
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: onVerifyOrChange,
                        icon: Icon(
                          isUserVerified ? Icons.edit_outlined : Icons.tune_outlined,
                          size: 18,
                        ),
                        label: Text(
                          isUserVerified ? 'Change adjustment' : 'Adjust ripeness',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _CompactDetail(
                      label: isDemo ? 'Demo classifier' : 'Model version',
                      value: classification.modelVersion,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactDetail extends StatelessWidget {
  const _CompactDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        const SizedBox(width: 16),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    );
  }
}

class _SaveStatusNotice extends StatelessWidget {
  const _SaveStatusNotice({
    required this.saving,
    required this.saved,
    required this.errorMessage,
    required this.origin,
  });

  final bool saving;
  final bool saved;
  final String? errorMessage;
  final ResultOrigin origin;

  @override
  Widget build(BuildContext context) {
    final isDemo = origin == ResultOrigin.demo;
    final title = saved
        ? 'Saved offline'
        : errorMessage != null
        ? 'Save failed'
        : saving
        ? 'Saving this result'
        : 'Not saved yet';
    final message = saved
        ? isDemo
              ? 'This Demo result and its compressed image are available in History.'
              : 'This on-device model result and its compressed image are available in History.'
        : errorMessage ??
              (saving
                  ? 'Chami is creating a private compressed copy and saving the '
                        'record on this device.'
                  : isDemo
                  ? 'Save this Demo result to test local History. It will '
                        'remain clearly labeled as Demo.'
                  : 'Save this on-device model result and its private '
                        'compressed image to local History.');
    final icon = saved
        ? Icons.check_circle_outline
        : errorMessage != null
        ? Icons.error_outline
        : saving
        ? Icons.hourglass_top
        : Icons.info_outline;

    return Semantics(
      container: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            icon,
            color: errorMessage != null
                ? AppColors.overripeOrange
                : AppColors.brandGreen,
          ),
          title: Text(title),
          subtitle: Text(message),
        ),
      ),
    );
  }
}

class LowConfidenceResultScreen extends ConsumerWidget {
  const LowConfidenceResultScreen({required this.preview, super.key});

  final LowConfidencePreview? preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = preview;
    if (value == null) {
      return const _MissingLowConfidenceScreen();
    }

    final imageProvider = ref.watch(scanImageProviderFactoryProvider)(
      value.image.path,
    );
    final rejected =
        value.classification.recognitionStatus ==
        RecognitionStatus.notRecognizedOrUnclear;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          rejected
              ? 'Fruit not recognized or unclear'
              : 'Low-confidence result',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: KamiResponsive.pagePadding(context, top: 8, bottom: 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ResultImageCard(
                    imageName: value.image.name,
                    imageProvider: imageProvider,
                    rejected: rejected,
                    isolatedImageBytes: value.classification.isolatedImageBytes,
                    gradCamImageBytes: value.classification.gradCamImageBytes,
                    heatmap: rejected ? value.classification.heatmap : null,
                    initialViewMode: rejected
                        ? value.classification.gradCamImageBytes != null ||
                                value.classification.heatmap != null
                            ? _ResultViewMode.gradCam
                            : _ResultViewMode.original
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _LowAccuracyNotice(
                    origin: value.classification.origin,
                    rejected: rejected,
                  ),
                  if (!rejected) ...[
                    _ResultSummaryCard(
                      classification: value.classification,
                      eyebrow: value.classification.origin == ResultOrigin.demo
                          ? 'Tentative demo result'
                          : 'Tentative on-device result',
                    ),
                    const SizedBox(height: 16),
                    const _WithheldShelfLifeNotice(),
                    const SizedBox(height: 16),
                  ],
                  const _ClearerPhotoTips(),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () =>
                        context.pop(LowConfidenceAction.uploadNewPhoto),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Upload a new photo'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to selected image'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowAccuracyNotice extends StatelessWidget {
  const _LowAccuracyNotice({required this.origin, required this.rejected});

  final ResultOrigin origin;
  final bool rejected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Card(
        margin: EdgeInsets.zero,
        color: colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rejected
                          ? 'Fruit not recognized or unclear'
                          : 'Low confidence - this result may not be accurate',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rejected
                          ? 'Chami could not confidently identify the fruit or its ripeness stage. '
                                'The Grad-CAM view above shows what the model focused on — try '
                                'uploading a clearer, well-lit photo of one fruit against a plain background.'
                          : origin == ResultOrigin.demo
                          ? 'Chami is showing the tentative demo prediction so '
                                'you can decide whether to upload a clearer '
                                'photo. It is not a confirmed assessment.'
                          : 'Chami is showing the tentative on-device prediction '
                                'so you can decide whether to upload a clearer '
                                'photo. It is not a confirmed assessment.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _WithheldShelfLifeNotice extends StatelessWidget {
  const _WithheldShelfLifeNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: const ListTile(
        leading: Icon(Icons.schedule_outlined),
        title: Text('Shelf-life guidance not shown'),
        subtitle: Text(
          'Chami does not provide shelf-life guidance for a low-confidence '
          'result.',
        ),
      ),
    );
  }
}

class _ClearerPhotoTips extends StatelessWidget {
  const _ClearerPhotoTips();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Try a clearer photo',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const _PhotoTip(text: 'Use bright, even lighting.'),
            const SizedBox(height: 8),
            const _PhotoTip(text: 'Keep one fruit centered and unobstructed.'),
            const SizedBox(height: 8),
            const _PhotoTip(text: 'Hold the device steady to avoid blur.'),
          ],
        ),
      ),
    );
  }
}

class _PhotoTip extends StatelessWidget {
  const _PhotoTip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _MissingLowConfidenceScreen extends StatelessWidget {
  const _MissingLowConfidenceScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Low-confidence result')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 64),
              const SizedBox(height: 20),
              Text(
                'Result details unavailable',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload another image to try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.scanUpload),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Open Upload image'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingPreviewScreen extends StatelessWidget {
  const _MissingPreviewScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment result')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 20),
              Text(
                'Result unavailable',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'This result is no longer available. Start a new scan to '
                'choose another image.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.scan),
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Start a new scan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RipenessInterventionSheet extends StatefulWidget {
  const RipenessInterventionSheet({
    required this.currentRipeness,
    required this.modelRipeness,
    required this.fruit,
    required this.modelConfidence,
    this.onDiscard,
    super.key,
  });

  final RipenessStage currentRipeness;
  final RipenessStage modelRipeness;
  final FruitIdentifier fruit;
  final double modelConfidence;
  final VoidCallback? onDiscard;

  @override
  State<RipenessInterventionSheet> createState() =>
      _RipenessInterventionSheetState();
}

class _RipenessInterventionSheetState
    extends State<RipenessInterventionSheet> {
  late RipenessStage _selected = widget.currentRipeness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidencePercent = (widget.modelConfidence * 100).round();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.tune_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Adjust Ripeness',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The AI model predicted ${widget.modelRipeness.displayName} with $confidencePercent% confidence. '
              'You can adjust the operational stage below for shelf-life and batches while preserving the original prediction for traceability.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            ...RipenessStage.values.map((stage) {
              final isSelected = _selected == stage;
              final isModelPrediction = widget.modelRipeness == stage;
              final style = ripenessStageStyle(
                stage,
                brightness: theme.brightness,
              );

              String description;
              switch (stage) {
                case RipenessStage.unripe:
                  description =
                      'Firm texture, mostly green peel, needs more time.';
                case RipenessStage.ripe:
                  description =
                      'Optimal sweetness and aroma, fully colored skin.';
                case RipenessStage.overripe:
                  description =
                      'Soft texture, dark sugar spots, consume immediately.';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: InkWell(
                  onTap: () => setState(() => _selected = stage),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? style.background
                          : theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? style.accent
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: style.accent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            style.icon,
                            color: style.foreground,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    stage.displayName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isModelPrediction) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'AI Pick',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? style.accent
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_selected != widget.modelRipeness)
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(widget.modelRipeness),
                      child: const Text('Reset to AI'),
                    ),
                  ),
                if (_selected != widget.modelRipeness)
                  const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: const Text('Apply Adjustment'),
                  ),
                ),
              ],
            ),
            if (widget.onDiscard != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDiscard!();
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Discard scan / Not a supported fruit'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
