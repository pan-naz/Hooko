import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:hooko_v20/nav.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/components/primary_button.dart';
import 'package:hooko_v20/components/app_bar_with_analysis.dart';
import 'package:hooko_v20/components/main_shell.dart';
import 'package:hooko_v20/state/app_state.dart';
import 'package:hooko_v20/screens/video_picker_screen.dart';
import 'package:hooko_v20/utils/analysis_gate.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ResponsiveSize.horizontalPadding(context),
        ResponsiveSize.horizontalPadding(context),
        ResponsiveSize.horizontalPadding(context),
        ResponsiveSize.horizontalPadding(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBarWithAnalysis(
            usedCount: appState.dailyAnalysisUsed,
            totalCount: appState.dailyAnalysisTotal,
            usageLoaded: !appState.isProSubscribed || appState.dailyUsageLoaded,
            usageFailed: appState.isProSubscribed && appState.dailyUsageFailed,
            badgeLabel: appState.subscriptionBadgeLabel,
            badgeAsset: appState.subscriptionBadgeAsset,
          ),
          SizedBox(height: ResponsiveSize.verticalSpacing(context, 30)),
          const HomeTitle(),
          const Spacer(),
          const UploadCard(),
        ],
      ),
    );
  }
}

class HomeTitle extends StatelessWidget {
  const HomeTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final titleSize = ResponsiveSize.text(context, 42);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Upload ',
              style: TextStyle(
                fontFamily: 'Geom',
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: offWhite,
                height: 1.1,
              ),
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFFF3D7F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds.inflate(6)),
              child: const _GradientTitleText('Analyze'),
            ),
          ],
        ),
        Text(
          'Grow',
          style: TextStyle(
            fontFamily: 'Geom',
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: offWhite,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

/// Text used inside ShaderMask to avoid edge artifacts on descenders like 'y'.
class _GradientTitleText extends StatelessWidget {
  final String text;
  const _GradientTitleText(this.text);

  @override
  Widget build(BuildContext context) {
    final titleSize = ResponsiveSize.text(context, 42);
    return Text(
      text,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: true,
      ),
      style: TextStyle(
        fontFamily: 'Geom',
        fontSize: titleSize,
        fontWeight: FontWeight.w700,
        color: Colors.white, // solid white for clean srcIn mask
        height: 1.15, // slightly larger to ensure descender space
      ),
    );
  }
}

class UploadCard extends StatefulWidget {
  const UploadCard({super.key});

  @override
  State<UploadCard> createState() => _UploadCardState();
}

class _UploadCardState extends State<UploadCard> {
  bool _isPicking = false;

  Future<void> _pickVideoFile() async {
    if (_isPicking) return;
    _isPicking = true;

    try {
      // Gate: must be subscribed AND under today's daily limit to start an analysis.
      final canAnalyze = await AnalysisGate.ensureCanAnalyze(context);
      if (!mounted || !canAnalyze) return;

      // Check current permission state first. On iOS, the system permission
      // dialog only appears once (when state is notDetermined). If the user
      // previously denied, requesting again silently returns denied — so we
      // skip the in-app message and send them straight to Settings.
      final currentState = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(),
      );

      PermissionState permission;
      if (currentState == PermissionState.notDetermined) {
        permission = await PhotoManager.requestPermissionExtend();
      } else {
        permission = currentState;
      }

      if (!permission.hasAccess) {
        if (currentState == PermissionState.notDetermined) {
          // First-time denial — show a brief hint.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo library permission required')),
            );
          }
        } else {
          // Previously denied — jump directly to iOS Settings.
          await PhotoManager.openSetting();
        }
        return;
      }

      if (!mounted) return;

      // Get scaffold key from MainShellScope
      final scaffoldKey = MainShellScope.of(context);
      if (scaffoldKey == null) return;

      // Show video picker modal with background shrinking effect
      final AssetEntity? selectedVideo = await showVideoPickerModalWithScaffold(scaffoldKey);

      if (!mounted || selectedVideo == null) return;

      // Store the asset directly
      final appState = AppStateProvider.read(context);
      appState.selectedVideoAsset = selectedVideo;

      context.push(AppRoutes.uploadedVideo);
    } catch (e) {
      debugPrint('Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e')),
        );
      }
    } finally {
      _isPicking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.spacing(context, 40)),
      decoration: BoxDecoration(
        color: const Color(0x1FFEFEFE),
        borderRadius:
            BorderRadius.circular(ResponsiveSize.spacing(context, 60)),
      ),
      child: Column(
        children: [
          PrimaryButton(
            label: 'Upload Video',
            iconPath: 'assets/icons/upload.svg',
            onTap: _pickVideoFile,
          ),
          SizedBox(height: ResponsiveSize.verticalSpacing(context, 20)),
          Text(
            'Get 3 data-driven hook alternatives proven to increase engagement.',
            textAlign: TextAlign.center,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            style: TextStyle(
              fontFamily: 'Geom',
              fontSize: ResponsiveSize.text(context, 14),
              fontWeight: FontWeight.w300,
              color: offWhite,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
