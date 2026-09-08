import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A Row that synchronizes the height of two children to match the taller one.
/// This avoids IntrinsicHeight which conflicts with LayoutBuilder.
class SyncedHeightRow extends StatefulWidget {
  final Widget left;
  final Widget right;
  final double spacing;

  const SyncedHeightRow({
    super.key,
    required this.left,
    required this.right,
    this.spacing = 12,
  });

  @override
  State<SyncedHeightRow> createState() => _SyncedHeightRowState();
}

class _SyncedHeightRowState extends State<SyncedHeightRow> {
  final GlobalKey _leftKey = GlobalKey();
  final GlobalKey _rightKey = GlobalKey();
  double? _syncedHeight;

  @override
  void initState() {
    super.initState();
    _measureAfterFrame();
  }

  @override
  void didUpdateWidget(SyncedHeightRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-measure if children actually changed identity
    // Keep existing height during remeasure to prevent blinking
    if (oldWidget.left != widget.left || oldWidget.right != widget.right) {
      // DON'T null out _syncedHeight - keep old value to prevent blink
      _measureAfterFrame();
    }
  }

  void _measureAfterFrame() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final leftBox = _leftKey.currentContext?.findRenderObject() as RenderBox?;
      final rightBox = _rightKey.currentContext?.findRenderObject() as RenderBox?;
      
      if (leftBox != null && rightBox != null) {
        final leftHeight = leftBox.size.height;
        final rightHeight = rightBox.size.height;
        final maxHeight = leftHeight > rightHeight ? leftHeight : rightHeight;
        
        if (_syncedHeight != maxHeight) {
          setState(() {
            _syncedHeight = maxHeight;
          });
        } else {
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always use cached height if available to prevent blinking during remeasure
    final hasHeight = _syncedHeight != null;
    
    Widget buildChild(Widget child, GlobalKey key) {
      // Wrap in KeyedSubtree for measurement
      final keyed = KeyedSubtree(key: key, child: child);
      // If we have a cached height, constrain it to prevent blink
      if (hasHeight) {
        return SizedBox(height: _syncedHeight, child: keyed);
      }
      return keyed;
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: buildChild(widget.left, _leftKey)),
        SizedBox(width: widget.spacing),
        Expanded(child: buildChild(widget.right, _rightKey)),
      ],
    );
  }
}
