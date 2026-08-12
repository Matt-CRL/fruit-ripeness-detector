import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/core/layout/kami_responsive.dart';
import 'package:kami/features/auth/application/auth_providers.dart';
import 'package:kami/features/startup/domain/startup_preferences.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _slides = [
    _OnboardingContent(
      icon: Icons.document_scanner_outlined,
      title: 'Scan or upload a fruit',
      description: 'Choose the easiest way to check one supported fruit.',
      points: [
        'Use Live Scan with your camera',
        'Upload a clear photo from your device',
        'Scan one fruit at a time',
      ],
    ),
    _OnboardingContent(
      icon: Icons.fact_check_outlined,
      title: 'Understand the assessment',
      description: 'Kami estimates ripeness from the fruit image you provide.',
      points: [
        'See Unripe, Ripe, or Overripe',
        'See how sure Kami is about the result',
        'View shelf-life recommendations when available',
        'Use the result as guidance, not a guarantee',
      ],
    ),
    _OnboardingContent(
      icon: Icons.inventory_2_outlined,
      title: 'Organize fruits into batches',
      description: 'Keep scans of the same fruit together as you work.',
      points: [
        'Create a batch from a scan or the Batches page',
        'Add only the same fruit type to a batch',
        'See quantity and ripeness summaries',
        'Add more unassigned scans later',
      ],
    ),
  ];

  late final PageController _pageController;
  int _currentPage = 0;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showPage(int page) {
    return _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goBack() async {
    if (_currentPage > 0) {
      await _showPage(_currentPage - 1);
      return;
    }

    final currentAccount = ref.read(currentAccountProvider);
    if (currentAccount != null) {
      await ref.read(authRepositoryProvider).signOut(localOnly: true);
    }
    if (mounted) {
      context.go(AppRoutes.accountChoice);
    }
  }

  Future<void> _complete() async {
    setState(() => _isCompleting = true);

    try {
      final currentAccount = ref.read(currentAccountProvider);
      if (currentAccount == null) {
        await ref.read(startupPreferencesProvider).completeGuestOnboarding();
      } else {
        await ref
            .read(startupPreferencesProvider)
            .completeAccountOnboarding(currentAccount.id);
      }
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Onboarding could not be completed. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  Future<void> _advance() async {
    if (_currentPage < _slides.length - 1) {
      await _showPage(_currentPage + 1);
      return;
    }

    await _complete();
  }

  @override
  Widget build(BuildContext context) {
    final compact = KamiResponsive.isCompactPhone(context);
    final isLastPage = _currentPage == _slides.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _isCompleting ? null : _goBack,
            tooltip: _currentPage == 0
                ? 'Back to account options'
                : 'Previous slide',
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Getting started'),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  itemBuilder: (context, index) {
                    return _OnboardingSlide(
                      key: ValueKey('onboarding-slide-$index'),
                      content: _slides[index],
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 12 : 20,
                  compact ? 6 : 12,
                  compact ? 12 : 20,
                  compact ? 12 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      liveRegion: true,
                      label: 'Slide ${_currentPage + 1} of ${_slides.length}',
                      child: ExcludeSemantics(
                        child: Column(
                          children: [
                            Text(
                              '${_currentPage + 1} of ${_slides.length}',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            _PageIndicator(
                              count: _slides.length,
                              selectedIndex: _currentPage,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isCompleting ? null : _advance,
                        child: _isCompleting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isLastPage ? 'Start using Kami' : 'Next',
                                maxLines: 1,
                              ),
                      ),
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

class _OnboardingContent {
  const _OnboardingContent({
    required this.icon,
    required this.title,
    required this.description,
    required this.points,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> points;
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.content, super.key});

  final _OnboardingContent content;

  @override
  Widget build(BuildContext context) {
    final compact = KamiResponsive.isCompactPhone(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 20,
        compact ? 8 : 16,
        compact ? 12 : 20,
        compact ? 4 : 8,
      ),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 600.0;
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SizedBox(
                height: cardHeight,
                child: Card(
                  child: SingleChildScrollView(
                    key: ValueKey('onboarding-slide-scroll-${content.title}'),
                    padding: EdgeInsets.fromLTRB(
                      compact ? 12 : 20,
                      compact ? 8 : 28,
                      compact ? 12 : 20,
                      compact ? 8 : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: compact ? 56 : 88,
                            height: compact ? 56 : 88,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              content.icon,
                              size: compact ? 30 : 46,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 10 : 24),
                        Text(
                          content.title,
                          style: compact
                              ? Theme.of(context).textTheme.titleLarge
                              : Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: compact ? 4 : 12),
                        Text(content.description, textAlign: TextAlign.center),
                        SizedBox(height: compact ? 8 : 24),
                        for (final point in content.points)
                          _OnboardingPoint(text: point),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingPoint extends StatelessWidget {
  const _OnboardingPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final compact = KamiResponsive.isCompactPhone(context);
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 4 : 10),
      padding: EdgeInsets.all(compact ? 6 : 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.primary,
            size: compact ? 18 : 24,
          ),
          SizedBox(width: compact ? 6 : 12),
          Expanded(
            child: Text(
              text,
              style: compact ? Theme.of(context).textTheme.bodySmall : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.selectedIndex});

  final int count;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = index == selectedIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: selected ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
