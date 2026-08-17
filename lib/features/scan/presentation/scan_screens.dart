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

enum ScanEntryMode { standard, rescan }

enum LowConfidenceAction { uploadNewPhoto, returnToPreviousResult }

final class LowConfidencePreview {
  const LowConfidencePreview({
    required this.image,
    required this.classification,
    required this.entryMode,
  });

  final SelectedScanImage image;
  final ClassificationResult classification;
  final ScanEntryMode entryMode;
}

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({this.entryMode = ScanEntryMode.standard, super.key});

  final ScanEntryMode entryMode;

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

      if (widget.entryMode == ScanEntryMode.rescan) {
        context.pop(preview);
        return;
      }

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
        entryMode: widget.entryMode,
      ),
    );
    if (!mounted) {
      return;
    }
    if (action == LowConfidenceAction.uploadNewPhoto) {
      await _chooseFromGallery();
    } else if (action == LowConfidenceAction.returnToPreviousResult &&
        widget.entryMode == ScanEntryMode.rescan) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedImage = _selectedImage;
    final selectedImageProvider = selectedImage == null
        ? null
        : ref.watch(scanImageProviderFactoryProvider)(selectedImage.path);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload image')),
      body: ListView(
        padding: KamiResponsive.pagePadding(context, top: 8, bottom: 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.entryMode == ScanEntryMode.rescan) ...[
                    OutlinedButton.icon(
                      onPressed: _isBusy ? null : () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Return to previous result'),
                    ),
                    const SizedBox(height: 24),
                  ],
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

  Future<void> _rescan() async {
    final replacement = await context.push<ScanPreview>(
      AppRoutes.scanUpload,
      extra: ScanEntryMode.rescan,
    );
    if (!mounted || replacement == null) {
      return;
    }
    setState(() {
      _preview = replacement;
      _resetSaveState();
    });
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
                  ),
                  const SizedBox(height: 16),
                  if (classification.origin == ResultOrigin.demo) ...[
                    const _FakePreviewNotice(),
                    const SizedBox(height: 16),
                  ],
                  _ResultSummaryCard(classification: classification),
                  const SizedBox(height: 16),
                  ShelfLifeGuidanceCard(
                    estimate: shelfLife,
                    ripeness: classification.ripeness,
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
                    const SizedBox(height: 16),
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

class _ResultImageCard extends StatelessWidget {
  const _ResultImageCard({
    required this.imageName,
    required this.imageProvider,
  });

  final String imageName;
  final ImageProvider<Object> imageProvider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            image: true,
            label: 'Selected image used for this assessment',
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Image(
                  image: imageProvider,
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
              ),
            ),
          ),
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
                    imageName,
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
  const _ResultSummaryCard({required this.classification, this.eyebrow});

  final ClassificationResult classification;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stageStyle = ripenessStageStyle(
      classification.ripeness,
      brightness: theme.brightness,
    );
    final confidencePercent = (classification.modelConfidence * 100).round();
    final isDemo = classification.origin == ResultOrigin.demo;
    final resultEyebrow =
        eyebrow ?? (isDemo ? 'Demo result' : 'On-device model result');

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
                        Text(resultEyebrow, style: theme.textTheme.labelLarge),
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
    final canReturnToPreviousResult = value.entryMode == ScanEntryMode.rescan;

    return Scaffold(
      appBar: AppBar(title: const Text('Low-confidence result')),
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
                  ),
                  const SizedBox(height: 12),
                  _LowConfidenceWarning(origin: value.classification.origin),
                  const SizedBox(height: 16),
                  _ResultSummaryCard(
                    classification: value.classification,
                    eyebrow: value.classification.origin == ResultOrigin.demo
                        ? 'Tentative demo result'
                        : 'Tentative on-device result',
                  ),
                  const SizedBox(height: 16),
                  const _WithheldShelfLifeNotice(),
                  const SizedBox(height: 16),
                  const _ClearerPhotoTips(),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () =>
                        context.pop(LowConfidenceAction.uploadNewPhoto),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Upload a new photo'),
                  ),
                  const SizedBox(height: 12),
                  if (canReturnToPreviousResult)
                    OutlinedButton.icon(
                      onPressed: () => context.pop(
                        LowConfidenceAction.returnToPreviousResult,
                      ),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Return to previous result'),
                    )
                  else
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

class _LowConfidenceWarning extends StatelessWidget {
  const _LowConfidenceWarning({required this.origin});

  final ResultOrigin origin;

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
                    const Text(
                      'Low confidence - this result may not be accurate',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      origin == ResultOrigin.demo
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
