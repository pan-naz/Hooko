import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hooko_v20/components/animated_fire_gradient.dart';
import 'package:hooko_v20/components/app_toast.dart';
import 'package:hooko_v20/components/primary_button.dart';
import 'package:hooko_v20/components/secondary_button.dart';
import 'package:hooko_v20/components/small_icon_button.dart';
import 'package:hooko_v20/services/revenuecat_service.dart';
import 'package:hooko_v20/state/app_state.dart';
import 'package:hooko_v20/theme.dart';

/// Hooko Plus paywall modal.
/// Presented as a full-screen modal with animated fire gradient background.
class HookoPlusPaywall extends StatefulWidget {
  /// Optional initial plan to highlight. If null, the selection defaults to
  /// the user's current subscription tier (or Plus 10 if none).
  final SubscriptionTier? initialPlan;
  const HookoPlusPaywall({super.key, this.initialPlan});

  /// Shows the paywall as a full-screen modal sliding up from bottom.
  static Future<String?> show(BuildContext context, {SubscriptionTier? initialPlan}) {
    return Navigator.of(context, rootNavigator: true).push<String>(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => HookoPlusPaywall(initialPlan: initialPlan),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<HookoPlusPaywall> createState() => _HookoPlusPaywallState();
}

class _HookoPlusPaywallState extends State<HookoPlusPaywall> {
  // 0 = Plus 10, 1 = Plus 20
  int _selectedPlan = 0;

  Package? _plus10Package;
  Package? _plus20Package;
  bool _loadingOfferings = true;
  bool _purchasing = false;
  bool _restoring = false;
  bool _initialPlanSet = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialPlanSet) {
      final override = widget.initialPlan;
      if (override != null) {
        _selectedPlan = override == SubscriptionTier.plus20 ? 1 : 0;
      } else {
        final appState = AppStateProvider.of(context);
        if (appState.subscriptionTier == SubscriptionTier.plus20) {
          _selectedPlan = 1;
        } else {
          _selectedPlan = 0;
        }
      }
      _initialPlanSet = true;
    }
  }

  SubscriptionTier _currentTierFor(int planIndex) =>
      planIndex == 0 ? SubscriptionTier.plus10 : SubscriptionTier.plus20;

  Future<void> _onCancelSubscription() async {
    await RevenueCatService.showManageSubscriptions();
  }

  Future<void> _loadOfferings() async {
    final offerings = await RevenueCatService.getOfferings();
    if (!mounted) return;
    final current = offerings?.current;
    Package? p10;
    Package? p20;
    if (current != null) {
      for (final pkg in current.availablePackages) {
        final id = pkg.storeProduct.identifier;
        if (id == RevenueCatService.productPlus10) p10 = pkg;
        if (id == RevenueCatService.productPlus20) p20 = pkg;
      }
    }
    setState(() {
      _plus10Package = p10;
      _plus20Package = p20;
      _loadingOfferings = false;
    });
  }

  Future<void> _onContinue() async {
    if (_purchasing) return;
    final pkg = _selectedPlan == 0 ? _plus10Package : _plus20Package;
    if (pkg == null) {
      AppToast.show(
        context,
        message: 'Subscription isn\'t available right now.',
        variant: AppToastVariant.error,
      );
      return;
    }
    setState(() => _purchasing = true);
    final appState = AppStateProvider.read(context);
    final ok = await RevenueCatService.purchasePackage(pkg, appState);
    if (!mounted) return;
    setState(() => _purchasing = false);
    if (ok) {
      Navigator.of(context).pop(_selectedPlan == 0 ? 'plus_10' : 'plus_20');
    }
    // If !ok, the purchase either failed or the user cancelled. The service
    // silently swallows cancellations; for other failures we stay on the
    // paywall so the user can retry. No toast needed — errors are already
    // surfaced by the store's native UI.
  }

  Future<void> _onRestore() async {
    if (_restoring) return;
    setState(() => _restoring = true);
    final appState = AppStateProvider.read(context);
    final result = await RevenueCatService.restorePurchases(appState);
    if (!mounted) return;
    setState(() => _restoring = false);

    switch (result) {
      case RestoreResult.restored:
        AppToast.show(
          context,
          message: 'Subscription restored.',
          variant: AppToastVariant.success,
        );
        Navigator.of(context).pop('restored');
        break;
      case RestoreResult.noSubscription:
        AppToast.show(
          context,
          message: 'No active subscription found on this account.',
          variant: AppToastVariant.info,
        );
        break;
      case RestoreResult.error:
        AppToast.show(
          context,
          message: 'Couldn\'t restore. Check your connection and try again.',
          variant: AppToastVariant.error,
        );
        break;
      case RestoreResult.unsupported:
        AppToast.show(
          context,
          message: 'Restore isn\'t available on this device.',
          variant: AppToastVariant.error,
        );
        break;
    }
  }

  static const List<String> _features = [
    'Full video breakdown, what works, what kills it',
    'Viral score + audio, visual and pacing breakdown',
    '3 alternatives per analysis with rewritten scripts and captions that convert',
    'Pro tips and trending hashtags for your niche',
    'Niche-specific real video examples',
    'Multi language analyses',
  ];

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topPadding = media.padding.top;
    final screenH = media.size.height;

    // Adaptive scaling: aggressively shrink so everything fits without scrolling
    final bool isCompact = screenH < 820;
    final bool isVeryCompact = screenH < 740;
    final double sBase = isVeryCompact ? 0.80 : (isCompact ? 0.88 : 0.95);

    final double hPad = isVeryCompact ? 18 : 22;
    final double titleSize = isVeryCompact ? 22 : (isCompact ? 24 : 26);
    final double featureSize = isVeryCompact ? 12.5 : (isCompact ? 13 : 14);
    final double featureGap = (isVeryCompact ? 8 : (isCompact ? 10 : 12));
    final double sectionGap = (isVeryCompact ? 12 : (isCompact ? 16 : 20));
    final double afterHeader = (isVeryCompact ? 8 : (isCompact ? 10 : 14));
    final double planGap = isVeryCompact ? 8 : 10;
    final double beforeButton = isVeryCompact ? 12 : (isCompact ? 14 : 18);
    final double afterButton = isVeryCompact ? 8 : (isCompact ? 10 : 12);
    final double afterRestore = isVeryCompact ? 6 : 8;

    return Scaffold(
      backgroundColor: const Color(0xFF110A1D),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedFireGradient()),
          Positioned.fill(
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  hPad,
                  topPadding + (isCompact ? 12 : 16),
                  hPad,
                  hPad,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PaywallHeader(
                      onClose: () => Navigator.of(context).pop(),
                      titleSize: titleSize,
                    ),
                    SizedBox(height: afterHeader),
                    Text(
                      'Get deep video analysis, viral scoring, and personalized rewrites that turn flat videos into shares, saves, and follows.',
                      style: TextStyle(
                        fontFamily: 'Geom',
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFFFEFEFE).withValues(alpha: 0.30),
                      ),
                    ),
                    SizedBox(height: sectionGap),
                    ..._features.map(
                      (f) => Padding(
                        padding: EdgeInsets.only(bottom: featureGap),
                        child: _FeatureRow(
                          text: f,
                          fontSize: featureSize,
                          iconSize: isVeryCompact ? 18 : (isCompact ? 20 : 22),
                        ),
                      ),
                    ),
                    SizedBox(height: isCompact ? 2 : 6),
                    Text(
                      'Cancel anytime. No hidden fees.',
                      style: TextStyle(
                        fontFamily: 'Geom',
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFFFEFEFE).withValues(alpha: 0.30),
                      ),
                    ),
                    const Spacer(),
                    Container(
                        padding: EdgeInsets.all(isVeryCompact ? 14 : (isCompact ? 16 : 20)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEFEFE).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Builder(builder: (ctx) {
                              final activeTier = AppStateProvider.of(ctx).subscriptionTier;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _PlanCard(
                                    title: 'Plus 10',
                                    subtitleBold: '10 analyses',
                                    price: _plus10Package?.storeProduct.priceString ?? '\$10.99',
                                    selected: _selectedPlan == 0,
                                    isCurrent: activeTier == SubscriptionTier.plus10,
                                    onTap: () => setState(() => _selectedPlan = 0),
                                    scale: sBase,
                                  ),
                                  SizedBox(height: planGap),
                                  _PlanCard(
                                    title: 'Plus 20',
                                    subtitleBold: '20 analyses',
                                    price: _plus20Package?.storeProduct.priceString ?? '\$18.99',
                                    selected: _selectedPlan == 1,
                                    isCurrent: activeTier == SubscriptionTier.plus20,
                                    onTap: () => setState(() => _selectedPlan = 1),
                                    scale: sBase,
                                  ),
                                ],
                              );
                            }),
                            SizedBox(height: beforeButton),
                            Builder(builder: (ctx) {
                              final appState = AppStateProvider.of(ctx);
                              final activeTier = appState.subscriptionTier;
                              final selectedTier = _currentTierFor(_selectedPlan);
                              final isActiveSelected =
                                  activeTier != SubscriptionTier.none &&
                                      activeTier == selectedTier;
                              final String label;
                              final VoidCallback onTap;
                              if (_purchasing) {
                                label = 'Processing...';
                                onTap = () {};
                              } else if (_loadingOfferings) {
                                label = 'Loading...';
                                onTap = () {};
                              } else if (isActiveSelected) {
                                return SecondaryButton(
                                  text: 'Cancel subscription',
                                  onPressed: _onCancelSubscription,
                                );
                              } else {
                                label = 'Continue';
                                onTap = _onContinue;
                              }
                              return PrimaryButton(label: label, onTap: onTap);
                            }),
                            SizedBox(height: afterButton),
                            Center(
                              child: GestureDetector(
                                onTap: _restoring ? null : _onRestore,
                                behavior: HitTestBehavior.opaque,
                                child: Text(
                                  _restoring ? 'Restoring...' : 'Restore Purchase',
                                  style: TextStyle(
                                    fontFamily: 'Geom',
                                    fontSize: isCompact ? 14 : 15,
                                    fontWeight: FontWeight.w500,
                                    color: offWhite,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: afterRestore),
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _FooterLink(
                                    label: 'Privacy Policy',
                                    onTap: () async {
                                      final uri = Uri.parse('https://www.hooko.app/privacy');
                                      try {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      } catch (e) {
                                        debugPrint('Failed to open Privacy Policy URL: $e');
                                      }
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Container(
                                      width: 3,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: offWhite.withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ),
                                  _FooterLink(
                                    label: 'Terms of Service',
                                    onTap: () async {
                                      final uri = Uri.parse('https://www.hooko.app/terms');
                                      try {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      } catch (e) {
                                        debugPrint('Failed to open Terms of Service URL: $e');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaywallHeader extends StatelessWidget {
  final VoidCallback onClose;
  final double titleSize;
  const _PaywallHeader({required this.onClose, this.titleSize = 28});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Upgrade to Hooko Plus',
            style: TextStyle(
              fontFamily: 'Geom',
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: offWhite,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SmallIconButton(
          onPressed: onClose,
          iconPath: 'assets/icons/close.svg',
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  final double fontSize;
  final double iconSize;
  const _FeatureRow({required this.text, this.fontSize = 15, this.iconSize = 22});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/icons/checked.svg',
          width: iconSize,
          height: iconSize,
          colorFilter: const ColorFilter.mode(offWhite, BlendMode.srcIn),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Geom',
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: offWhite,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatefulWidget {
  final String title;
  final String subtitleBold;
  final String price;
  final bool selected;
  final bool isCurrent;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.subtitleBold,
    required this.price,
    required this.selected,
    required this.onTap,
    this.isCurrent = false,
    this.scale = 1.0,
  });

  final double scale;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  double _pressScale = 1.0;

  void _setPressed(bool pressed) {
    if (widget.selected) return;
    setState(() => _pressScale = pressed ? 1.05 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.scale.clamp(0.78, 1.0);
    final double hPad = 18 * s;
    final double vPad = 14 * s;
    final double titleSize = 19 * s;
    final double subSize = 13 * s;
    final double priceSize = 21 * s;
    final double monthSize = 12 * s;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressScale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: offWhite.withValues(alpha: widget.selected ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: widget.selected ? offWhite : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _PlanRadio(selected: widget.selected),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      color: offWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Geom',
                        fontSize: subSize,
                        fontWeight: FontWeight.w400,
                        color: offWhite.withValues(alpha: 0.75),
                      ),
                      children: [
                        const TextSpan(text: 'Daily limit: '),
                        TextSpan(
                          text: widget.subtitleBold,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: offWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.price,
                  style: TextStyle(
                    fontFamily: 'Geom',
                    fontSize: priceSize,
                    fontWeight: FontWeight.w700,
                    color: offWhite,
                  ),
                ),
                Text(
                  '/month',
                  style: TextStyle(
                    fontFamily: 'Geom',
                    fontSize: monthSize,
                    fontWeight: FontWeight.w400,
                    color: offWhite.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
            if (widget.isCurrent)
              Positioned(
                top: -10 * s,
                right: 18 * s,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * s,
                    vertical: 4 * s,
                  ),
                  decoration: BoxDecoration(
                    color: offWhite,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Current plan',
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontSize: 10 * s,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF110A1D),
                      height: 1.1,
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

class _PlanRadio extends StatelessWidget {
  final bool selected;
  const _PlanRadio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: offWhite, width: 1.8),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: selected ? 12 : 0,
          height: selected ? 12 : 0,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: offWhite,
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Geom',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: offWhite.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
