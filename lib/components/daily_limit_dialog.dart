import 'package:flutter/material.dart';
import 'package:hooko_v20/components/hooko_plus_paywall.dart';
import 'package:hooko_v20/components/primary_button.dart';
import 'package:hooko_v20/components/secondary_button.dart';
import 'package:hooko_v20/state/app_state.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';

/// Bottom-sheet style dialog shown when the user has used all their daily
/// analyses for the day.
///
/// - For Plus 20 users: just a "come back tomorrow" message.
/// - For Plus 10 users: same message + an upgrade CTA that opens the paywall
///   so they can double their daily analyses by moving to Plus 20.
class DailyLimitReachedDialog extends StatelessWidget {
  final int limit;
  final SubscriptionTier tier;
  const DailyLimitReachedDialog({
    super.key,
    required this.limit,
    required this.tier,
  });

  static Future<void> show(
    BuildContext context, {
    required int limit,
    required SubscriptionTier tier,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => DailyLimitReachedDialog(limit: limit, tier: tier),
    );
  }

  bool get _canUpgrade => tier == SubscriptionTier.plus10;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ResponsiveSize.spacing(context, 36));
    final sidePadding = ResponsiveSize.horizontalPadding(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.bottomCenter,
      insetPadding: EdgeInsets.fromLTRB(sidePadding, sidePadding, sidePadding, sidePadding),
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFF110A1D), borderRadius: radius),
          padding: EdgeInsets.all(ResponsiveSize.spacing(context, 28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: ResponsiveSize.spacing(context, 56),
                  height: ResponsiveSize.spacing(context, 56),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: visualAccent.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.hourglass_bottom_rounded,
                    color: visualAccent,
                    size: ResponsiveSize.spacing(context, 30),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveSize.verticalSpacing(context, 16)),
              Text(
                'Daily limit reached',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: offWhite,
                ),
              ),
              SizedBox(height: ResponsiveSize.verticalSpacing(context, 10)),
              Text(
                _canUpgrade
                    ? "You've used all $limit of your analyses for today.\n\nUpgrade to Plus 20 to get 10 more analyses per day, or come back tomorrow when your limit resets at midnight."
                    : "You've used all $limit of your analyses for today.\n\nYour limit resets at midnight — come back tomorrow to keep analyzing.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  height: 1.4,
                  color: offWhite.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: ResponsiveSize.verticalSpacing(context, 24)),
              if (_canUpgrade) ...[
                PrimaryButton(
                  label: 'Upgrade to Plus 20',
                  onTap: () async {
                    Navigator.of(context).pop();
                    await HookoPlusPaywall.show(context, initialPlan: SubscriptionTier.plus20);
                  },
                ),
                SizedBox(height: ResponsiveSize.verticalSpacing(context, 10)),
                SecondaryButton(
                  text: 'Maybe later',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ] else
                PrimaryButton(
                  label: 'Got it',
                  onTap: () => Navigator.of(context).pop(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
