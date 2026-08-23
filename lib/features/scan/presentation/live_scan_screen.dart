import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/app/theme/app_colors.dart';
import 'package:kami/core/database/app_database_provider.dart';
import 'package:kami/core/layout/kami_responsive.dart';
import 'package:kami/features/history/application/save_scan_result.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/scan/application/live_camera.dart';
import 'package:kami/features/scan/application/live_scan_controller.dart';
import 'package:kami/features/scan/application/live_scan_providers.dart';
import 'package:kami/features/scan/application/scan_service_providers.dart';
import 'package:kami/features/scan/data/camera/app_private_live_scan_frame_store.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

class LiveScanScreen extends ConsumerStatefulWidget {
  const LiveScanScreen({super.key});

  @override
  ConsumerState<LiveScanScreen> createState() => _LiveScanScreenState();
}

class _LiveScanScreenState extends ConsumerState<LiveScanScreen>
    with WidgetsBindingObserver {
  static const _appSettingsChannel = MethodChannel(
    'ph.fruitripeness.kami/app_settings',
  );

  late final LiveScanController _controller;
  SavedScanRecord? _savedRecord;
  String? _assignedBatchId;
  String? _reservedScanId;
  String? _saveError;
  bool _saving = false;
  bool _retryWhenResumed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = LiveScanController(
      cameraGateway: ref.read(liveCameraGatewayProvider),
      classifier: ref.read(liveScanClassifierProvider),
    )..addListener(_handleControllerChange);
    unawaited(_controller.initialize());
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_retryWhenResumed) {
          _retryWhenResumed = false;
          _retryCamera();
        } else if (_controller.phase == LiveScanPhase.suspended) {
          _resetSaveState();
          unawaited(_controller.initialize());
        }
      case AppLifecycleState.inactive:
        if (_controller.phase != LiveScanPhase.initializing) {
          unawaited(_controller.suspendForLifecycle());
        }
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_controller.suspendForLifecycle());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_handleControllerChange);
    unawaited(_controller.close());
    super.dispose();
  }

  void _resetSaveState() {
    _savedRecord = null;
    _assignedBatchId = null;
    _reservedScanId = null;
    _saveError = null;
    _saving = false;
  }

  Future<void> _saveResult() async {
    final snapshot = _controller.snapshot;
    if (snapshot == null ||
        snapshot.classification.requiresRetake ||
        _saving ||
        _savedRecord != null) {
      return;
    }

    final frameStore = ref.read(liveScanFrameStoreProvider);
    final saveResult = ref.read(saveScanResultUseCaseProvider);
    final shelfLifeAdvisor = ref.read(shelfLifeAdvisorProvider);
    final scanId = _reservedScanId ??= ref
        .read(entityIdGeneratorProvider)
        .nextId();
    setState(() {
      _saving = true;
      _saveError = null;
    });

    SelectedScanImage? temporaryImage;
    SavedScanRecord? savedRecord;
    try {
      await _controller.pause();
      if (_controller.phase != LiveScanPhase.paused) {
        throw StateError('Live Scan could not pause before saving.');
      }
      temporaryImage = await frameStore.writeTemporary(snapshot.frame);
      savedRecord = await saveResult.execute(
        preview: ScanPreview(
          image: temporaryImage,
          classification: snapshot.classification,
          shelfLife: shelfLifeAdvisor.estimate(snapshot.classification),
        ),
        scanId: scanId,
      );
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError =
              'Chami could not save this live result. Nothing was added to '
              'History. Keep the result paused and try again.';
        });
      }
      return;
    } finally {
      if (temporaryImage != null) {
        try {
          await frameStore.removeTemporary(temporaryImage);
        } on Object {
          // The operating system may still clear an orphaned cache file.
        }
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _savedRecord = savedRecord;
      _saving = false;
    });
  }

  Future<void> _openAddToBatch(String scanId) async {
    final batchId = await context.push<String>(AppRoutes.addToBatch(scanId));
    if (!mounted || batchId == null) {
      return;
    }
    setState(() => _assignedBatchId = batchId);
  }

  Future<void> _scanAnotherFruit() async {
    setState(_resetSaveState);
    if (_controller.phase == LiveScanPhase.paused) {
      await _controller.resume();
    } else {
      await _controller.initialize();
    }
  }

  void _openHistoryAfterSave() {
    context.go(
      '${AppRoutes.history}?refresh=${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  void _retryCamera() {
    // Recreate the camera controller and route after a denial. The Android
    // camera plugin owns the permission request lifecycle, so reusing the
    // failed controller can leave the next attempt without a prompt.
    context.replace(
      '${AppRoutes.scanLive}?retry=${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  Future<void> _openAppSettings() async {
    _retryWhenResumed = true;
    try {
      await _appSettingsChannel.invokeMethod<void>('open');
    } on Object {
      _retryWhenResumed = false;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Open Android Settings, choose Chami, and allow camera access.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Live Scan')),
      body: switch (_controller.phase) {
        LiveScanPhase.initializing ||
        LiveScanPhase.suspended => const _LiveScanLoading(),
        LiveScanPhase.failed => _LiveScanFailure(
          kind: _controller.failureKind,
          message:
              _controller.failureMessage ?? 'Chami could not start Live Scan.',
          onRetry: _retryCamera,
          onOpenSettings: _openAppSettings,
        ),
        LiveScanPhase.active || LiveScanPhase.paused => _LiveCameraBody(
          controller: _controller,
          saving: _saving,
          savedRecord: _savedRecord,
          assignedBatchId: _assignedBatchId,
          saveError: _saveError,
          onSave: _saveResult,
          onPause: _controller.pause,
          onResume: _controller.resume,
          onScanAnother: _scanAnotherFruit,
          onAddToBatch: _savedRecord == null
              ? null
              : () => _openAddToBatch(_savedRecord!.id),
          onViewBatch: _assignedBatchId == null
              ? null
              : () => context.push(AppRoutes.batchDetails(_assignedBatchId!)),
          onViewHistory: _openHistoryAfterSave,
        ),
      },
    );
  }
}

class _LiveScanLoading extends StatelessWidget {
  const _LiveScanLoading();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Starting rear camera…'),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveCameraBody extends StatefulWidget {
  const _LiveCameraBody({
    required this.controller,
    required this.saving,
    required this.savedRecord,
    required this.assignedBatchId,
    required this.saveError,
    required this.onSave,
    required this.onPause,
    required this.onResume,
    required this.onScanAnother,
    required this.onAddToBatch,
    required this.onViewBatch,
    required this.onViewHistory,
  });

  final LiveScanController controller;
  final bool saving;
  final SavedScanRecord? savedRecord;
  final String? assignedBatchId;
  final String? saveError;
  final Future<void> Function() onSave;
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;
  final Future<void> Function() onScanAnother;
  final VoidCallback? onAddToBatch;
  final VoidCallback? onViewBatch;
  final VoidCallback onViewHistory;

  @override
  State<_LiveCameraBody> createState() => _LiveCameraBodyState();
}

class _LiveCameraBodyState extends State<_LiveCameraBody> {
  final _previewKey = GlobalKey();
  final _targetKey = GlobalKey();
  bool _cropUpdateScheduled = false;

  @override
  void didUpdateWidget(covariant _LiveCameraBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.session != widget.controller.session) {
      _scheduleCropUpdate();
    }
  }

  void _scheduleCropUpdate() {
    if (_cropUpdateScheduled) {
      return;
    }
    _cropUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cropUpdateScheduled = false;
      _updateTargetCrop();
    });
  }

  void _updateTargetCrop() {
    final session = widget.controller.session;
    final previewContext = _previewKey.currentContext;
    final targetContext = _targetKey.currentContext;
    if (session == null || previewContext == null || targetContext == null) {
      return;
    }
    final previewBox = previewContext.findRenderObject();
    final targetBox = targetContext.findRenderObject();
    if (previewBox is! RenderBox ||
        targetBox is! RenderBox ||
        previewBox.size.isEmpty ||
        targetBox.size.isEmpty) {
      return;
    }

    final targetGlobal = targetBox.localToGlobal(Offset.zero);
    final previewGlobal = previewBox.localToGlobal(Offset.zero);
    final target = Rect.fromLTWH(
      targetGlobal.dx - previewGlobal.dx,
      targetGlobal.dy - previewGlobal.dy,
      targetBox.size.width,
      targetBox.size.height,
    );
    final cameraRatio = session.previewAspectRatio <= 0
        ? 4 / 3
        : session.previewAspectRatio;
    final displayRatio =
        MediaQuery.orientationOf(context) == Orientation.portrait
        ? 1 / cameraRatio
        : cameraRatio;
    final previewSize = previewBox.size;
    final sourceWidth = displayRatio * 1000;
    const sourceHeight = 1000.0;
    final scale = math.max(
      previewSize.width / sourceWidth,
      previewSize.height / sourceHeight,
    );
    final scaledWidth = sourceWidth * scale;
    final scaledHeight = sourceHeight * scale;
    final offsetX = (previewSize.width - scaledWidth) / 2;
    final offsetY = (previewSize.height - scaledHeight) / 2;
    final left = ((target.left - offsetX) / scaledWidth).clamp(0.0, 1.0);
    final top = ((target.top - offsetY) / scaledHeight).clamp(0.0, 1.0);
    final right = ((target.right - offsetX) / scaledWidth).clamp(0.0, 1.0);
    final bottom = ((target.bottom - offsetY) / scaledHeight).clamp(0.0, 1.0);
    final crop = NormalizedCropRect(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
    );
    if (crop.isValid) {
      widget.controller.updateTargetCrop(crop);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.session;
    if (session == null) {
      return const _LiveScanLoading();
    }
    _scheduleCropUpdate();

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            key: _previewKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CoverCameraPreview(session: session),
                _FruitFramingOverlay(targetKey: _targetKey),
                if (widget.controller.phase == LiveScanPhase.paused)
                  ColoredBox(
                    color: const Color(0x66000000),
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          child: Text(
                            'Scanning paused',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.55,
              ),
              child: SingleChildScrollView(
                child: _LiveResultPanel(
                  controller: widget.controller,
                  saving: widget.saving,
                  savedRecord: widget.savedRecord,
                  assignedBatchId: widget.assignedBatchId,
                  saveError: widget.saveError,
                  onSave: widget.onSave,
                  onPause: widget.onPause,
                  onResume: widget.onResume,
                  onScanAnother: widget.onScanAnother,
                  onAddToBatch: widget.onAddToBatch,
                  onViewBatch: widget.onViewBatch,
                  onViewHistory: widget.onViewHistory,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverCameraPreview extends StatelessWidget {
  const _CoverCameraPreview({required this.session});

  final LiveCameraSession session;

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final cameraRatio = session.previewAspectRatio <= 0
        ? 4 / 3
        : session.previewAspectRatio;
    final displayRatio = orientation == Orientation.portrait
        ? 1 / cameraRatio
        : cameraRatio;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: displayRatio * 1000,
          height: 1000,
          child: session.buildPreview(),
        ),
      ),
    );
  }
}

class _FruitFramingOverlay extends StatelessWidget {
  const _FruitFramingOverlay({required this.targetKey});

  final GlobalKey targetKey;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.66),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Text(
                  'Center one clear, well-lit fruit',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox.square(
                    dimension: 600,
                    child: DecoratedBox(
                      key: targetKey,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveResultPanel extends StatelessWidget {
  const _LiveResultPanel({
    required this.controller,
    required this.saving,
    required this.savedRecord,
    required this.assignedBatchId,
    required this.saveError,
    required this.onSave,
    required this.onPause,
    required this.onResume,
    required this.onScanAnother,
    required this.onAddToBatch,
    required this.onViewBatch,
    required this.onViewHistory,
  });

  final LiveScanController controller;
  final bool saving;
  final SavedScanRecord? savedRecord;
  final String? assignedBatchId;
  final String? saveError;
  final Future<void> Function() onSave;
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;
  final Future<void> Function() onScanAnother;
  final VoidCallback? onAddToBatch;
  final VoidCallback? onViewBatch;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final compact = KamiResponsive.isCompactPhone(context);
    final result = controller.result;
    final rejected =
        result?.recognitionStatus == RecognitionStatus.notRecognizedOrUnclear ||
        result?.requiresRetake == true;
    final paused = controller.phase == LiveScanPhase.paused;
    final saved = savedRecord != null;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 20,
            compact ? 12 : 16,
            compact ? 16 : 20,
            compact ? 12 : 18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result == null)
                Row(
                  children: [
                    if (!paused) ...[
                      const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        paused
                            ? 'No result was captured before pausing.'
                            : 'Analyzing the camera view…',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                )
              else if (rejected)
                const _LiveRejectionNotice()
              else
                _LiveClassification(result: result),
              if (savedRecord case final record?) ...[
                const SizedBox(height: 10),
                _LiveShelfLifeSummary(estimate: record.shelfLife),
              ],
              const SizedBox(height: 10),
              Text(
                'Model validation is incomplete. Treat this as decision support, not a guaranteed assessment.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              if (saveError != null) ...[
                const SizedBox(height: 10),
                Text(
                  saveError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (!saved) ...[
                if (!rejected)
                  FilledButton.icon(
                    onPressed: saving ? null : () => unawaited(onSave()),
                    icon: saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              semanticsLabel: 'Saving live result',
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Saving...' : 'Save Result'),
                  ),
                if (!rejected) const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : paused
                      ? () => unawaited(onResume())
                      : () => unawaited(onPause()),
                  icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                  label: Text(paused ? 'Resume scanning' : 'Pause result'),
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: () => unawaited(onScanAnother()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan another fruit'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: assignedBatchId == null
                      ? onAddToBatch
                      : onViewBatch,
                  icon: Icon(
                    assignedBatchId == null
                        ? Icons.playlist_add
                        : Icons.inventory_2_outlined,
                  ),
                  label: Text(
                    assignedBatchId == null ? 'Add to Batch' : 'View batch',
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onViewHistory,
                  icon: const Icon(Icons.history),
                  label: const Text('View in History'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveClassification extends StatelessWidget {
  const _LiveClassification({required this.result});

  final ClassificationResult result;

  @override
  Widget build(BuildContext context) {
    final color = switch (result.ripeness) {
      RipenessStage.unripe => AppColors.unripeGreen,
      RipenessStage.ripe => const Color(0xFF8A6500),
      RipenessStage.overripe => AppColors.overripeOrange,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 54,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.ripeness.displayName} ${result.fruit.displayName}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${(result.modelConfidence * 100).round()}% model confidence',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveRejectionNotice extends StatelessWidget {
  const _LiveRejectionNotice();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Fruit not recognized or unclear. No final result yet.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No final result yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Fruit not recognized or unclear. Center one clear supported fruit '
            'inside the target frame.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveShelfLifeSummary extends StatelessWidget {
  const _LiveShelfLifeSummary({required this.estimate});

  final ShelfLifeEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = KamiResponsive.isCompactPhone(context);
    final (estimateLabel, storageGuidance) = switch (estimate) {
      ShelfLifeRange(
        :final minimum,
        :final maximum,
        :final unit,
        :final storageGuidance,
      ) =>
        ('Estimated shelf life: $minimum-$maximum $unit', storageGuidance),
      ShelfLifeConsumeImmediately(:final storageGuidance) => (
        'Estimated shelf life: Consume immediately',
        storageGuidance,
      ),
      ShelfLifeUnavailable(:final reason) => (
        'Estimated shelf life: Unavailable',
        reason,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 8 : 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              estimateLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Storage: $storageGuidance',
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 3),
            Text(
              'Based on provisional literature-informed rules. Actual quality may vary.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveScanFailure extends StatelessWidget {
  const _LiveScanFailure({
    required this.kind,
    required this.message,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final LiveCameraFailureKind? kind;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final permissionFailure =
        kind == LiveCameraFailureKind.permissionDenied ||
        kind == LiveCameraFailureKind.permissionPermanentlyDenied;
    final permanentlyBlocked =
        kind == LiveCameraFailureKind.permissionPermanentlyDenied;
    final title = switch (kind) {
      LiveCameraFailureKind.permissionDenied ||
      LiveCameraFailureKind.permissionPermanentlyDenied =>
        'Camera permission needed',
      LiveCameraFailureKind.noRearCamera => 'Rear camera unavailable',
      LiveCameraFailureKind.unsupportedStreaming =>
        'Live camera frames unavailable',
      LiveCameraFailureKind.streaming => 'Live Scan stopped',
      LiveCameraFailureKind.initialization ||
      null => 'Could not start Live Scan',
    };
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      permissionFailure
                          ? Icons.no_photography_outlined
                          : Icons.camera_alt_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    if (permanentlyBlocked) ...[
                      FilledButton.icon(
                        onPressed: onOpenSettings,
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Open settings'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ] else
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
