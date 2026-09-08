import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/components/app_bar_with_analysis.dart';
import 'package:hooko_v20/components/hooko_plus_paywall.dart';
import 'package:hooko_v20/state/app_state.dart';

const String kTermsOfServiceUrl = 'https://www.hooko.app/terms';
const String kPrivacyPolicyUrl = 'https://www.hooko.app/privacy';
const String kContactEmail = 'nazariosnz@gmail.com';

const String kAppStoreId = '6758728094';

Future<void> _rateHooko() async {
  // Open the App Store review composer directly. This avoids
  // SKStoreReviewController rate limits (max 3 prompts/year) that silently
  // suppress the in-app prompt for App Store builds.
  final uri = Uri.parse(
    'https://apps.apple.com/app/id$kAppStoreId?action=write-review',
  );
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Failed to open App Store review page: $e');
  }
}

Future<void> _openContactEmail() async {
  final uri = Uri(
    scheme: 'mailto',
    path: kContactEmail,
    queryParameters: {'subject': 'Hooko Support'},
  );
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Failed to open contact email: $e');
  }
}

Future<void> _openTermsOfService() async {
  final uri = Uri.parse(kTermsOfServiceUrl);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Failed to open Terms of Service URL: $e');
  }
}

Future<void> _openPrivacyPolicy() async {
  final uri = Uri.parse(kPrivacyPolicyUrl);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Failed to open Privacy Policy URL: $e');
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/images/city.jpg',
            fit: BoxFit.contain,
          ),
        ),
        // Content
        Padding(
          padding: EdgeInsets.fromLTRB(
            ResponsiveSize.horizontalPadding(context),
            ResponsiveSize.horizontalPadding(context),
            ResponsiveSize.horizontalPadding(context),
            0,
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBarWithAnalysis(rightTitle: 'Profile'),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Subscribe / Current plan box
                  Builder(
                    builder: (ctx) {
                      final appState = AppStateProvider.of(ctx);
                      if (appState.isProSubscribed) {
                        return _CurrentPlanBox(
                          tier: appState.subscriptionTier,
                          onTap: () => HookoPlusPaywall.show(ctx),
                        );
                      }
                      return _ProSubscriptionBox(
                        onTap: () => HookoPlusPaywall.show(ctx),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Rate Hooko
                  _ProfileMenuItem(
                    title: 'Rate Hooko',
                    iconPath: 'assets/icons/star.svg',
                    onTap: () => _rateHooko(),
                  ),
                  const SizedBox(height: 16),
                  // Contact
                  _ProfileMenuItem(
                    title: 'Contact',
                    iconPath: 'assets/icons/chat.svg',
                    onTap: () => _openContactEmail(),
                  ),
                  const SizedBox(height: 16),
                  // Privacy Policy
                  _ProfileMenuItem(
                    title: 'Privacy Policy',
                    iconPath: 'assets/icons/arrow_upright.svg',
                    onTap: () => _openPrivacyPolicy(),
                  ),
                  const SizedBox(height: 16),
                  // Terms of Service
                  _ProfileMenuItem(
                    title: 'Terms of Service',
                    iconPath: 'assets/icons/arrow_upright.svg',
                    onTap: () => _openTermsOfService(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
        ),
      ],
    );
  }

}

class _ProSubscriptionBox extends StatefulWidget {
  final VoidCallback onTap;
  const _ProSubscriptionBox({required this.onTap});

  @override
  State<_ProSubscriptionBox> createState() => _ProSubscriptionBoxState();
}

class _ProSubscriptionBoxState extends State<_ProSubscriptionBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) => _controller.forward();
  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }
  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFED6A17),
                Color(0xFFFF2EC9),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFEFE).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/icon_logo.svg',
                    width: 32,
                    height: 32,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upgrade to Hooko Plus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload any video. Analyze it and get 3 data-driven hook alternatives proven to increase engagement.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
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

/// Non-interactive card shown in Profile once the user has an active
/// subscription. Mirrors the gradient/layout of [_ProSubscriptionBox] but
/// swaps the logo for the tier badge SVG (plus10 / plus20).
class _CurrentPlanBox extends StatefulWidget {
  final SubscriptionTier tier;
  final VoidCallback onTap;
  const _CurrentPlanBox({required this.tier, required this.onTap});

  @override
  State<_CurrentPlanBox> createState() => _CurrentPlanBoxState();
}

class _CurrentPlanBoxState extends State<_CurrentPlanBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _tierLabel =>
      widget.tier == SubscriptionTier.plus20 ? 'Plus20' : 'Plus10';
  String get _badgeAsset => widget.tier == SubscriptionTier.plus20
      ? 'assets/icons/plus20.svg'
      : 'assets/icons/plus10.svg';

  void _handleTapDown(TapDownDetails details) => _controller.forward();
  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFED6A17),
                Color(0xFFFF2EC9),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFEFE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: SvgPicture.asset(
                    _badgeAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription $_tierLabel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to switch between Plus10 and Plus20, or manage your subscription.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
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

class _ProfileMenuItem extends StatefulWidget {
  final String title;
  final String iconPath;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.title,
    required this.iconPath,
    required this.onTap,
  });

  @override
  State<_ProfileMenuItem> createState() => _ProfileMenuItemState();
}

class _ProfileMenuItemState extends State<_ProfileMenuItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) => _controller.forward();
  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }
  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFEFE).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _ProfileIconButton(iconPath: widget.iconPath),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileIconButton extends StatelessWidget {
  final String iconPath;

  const _ProfileIconButton({required this.iconPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE).withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.asset(
          iconPath,
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
