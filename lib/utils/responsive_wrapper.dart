import 'package:flutter/material.dart';
import 'package:hooko_v20/utils/app_constants.dart';

/// Wrapper that constrains app to phone dimensions on tablet/desktop.
/// 
/// Maintains phone aspect ratio (9:19.5) so UI looks identical on tablets.
/// IMPORTANT: Injects corrected MediaQuery so all child widgets using
/// MediaQuery.of(context).size will get the constrained dimensions.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  
  /// Maximum width for content. Defaults to [AppBreakpoints.maxContentWidth].
  final double maxWidth;
  
  /// Phone aspect ratio (width:height). Default is ~9:19.5 (iPhone style).
  static const double phoneAspectRatio = 9 / 19.5;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final shortestSide = size.shortestSide;
    
    // Only apply phone constraints on tablets (shortestSide >= 600)
    final isTablet = shortestSide >= 600;
    
    if (!isTablet) {
      // Phone - no constraints, use full screen
      return child;
    }
    
    // Tablet - constrain to phone aspect ratio, centered
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate the phone-sized container dimensions
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;
            
            // Calculate size maintaining phone aspect ratio
            double phoneWidth;
            double phoneHeight;
            
            if (availableWidth / availableHeight > phoneAspectRatio) {
              // Height is the constraint
              phoneHeight = availableHeight;
              phoneWidth = phoneHeight * phoneAspectRatio;
            } else {
              // Width is the constraint
              phoneWidth = availableWidth;
              phoneHeight = phoneWidth / phoneAspectRatio;
            }
            
            // Apply max width constraint
            if (phoneWidth > maxWidth) {
              phoneWidth = maxWidth;
              phoneHeight = phoneWidth / phoneAspectRatio;
            }
            
            // Create new MediaQueryData with constrained size
            // This makes all child widgets that use MediaQuery.of(context).size
            // get the phone-like dimensions instead of full tablet screen
            final constrainedMediaQuery = mediaQuery.copyWith(
              size: Size(phoneWidth, phoneHeight),
              // Keep safe area padding but scale down if needed
              padding: EdgeInsets.only(
                top: mediaQuery.padding.top.clamp(0, 50),
                bottom: mediaQuery.padding.bottom.clamp(0, 34),
              ),
              viewPadding: EdgeInsets.only(
                top: mediaQuery.viewPadding.top.clamp(0, 50),
                bottom: mediaQuery.viewPadding.bottom.clamp(0, 34),
              ),
            );
            
            return SizedBox(
              width: phoneWidth,
              height: phoneHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MediaQuery(
                  data: constrainedMediaQuery,
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
