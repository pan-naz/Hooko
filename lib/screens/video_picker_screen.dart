import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/components/small_icon_button.dart';
import 'package:hooko_v20/components/ios_modal_sheet.dart';

/// Custom video picker modal that matches the app's iOS-style modal design
class VideoPickerScreen extends StatefulWidget {
  final VoidCallback onDismiss;
  final void Function(AssetEntity video) onVideoSelected;

  const VideoPickerScreen({
    super.key,
    required this.onDismiss,
    required this.onVideoSelected,
  });

  @override
  State<VideoPickerScreen> createState() => _VideoPickerScreenState();
}

class _VideoPickerScreenState extends State<VideoPickerScreen> {
  List<AssetEntity> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        filterOption: FilterOptionGroup(
          videoOption: const FilterOption(
            durationConstraint: DurationConstraint(
              min: Duration.zero,
              max: Duration(hours: 24),
            ),
          ),
        ),
      );

      if (albums.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final allVideosAlbum = albums.first;
      final videos = await allVideosAlbum.getAssetListRange(start: 0, end: 500);

      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading videos: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectVideo(AssetEntity video) {
    widget.onVideoSelected(video);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [modalGradientTop, modalGradientBottom],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveSize.spacing(context, 24),
                ResponsiveSize.spacing(context, 16),
                ResponsiveSize.spacing(context, 16),
                ResponsiveSize.spacing(context, 8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Video',
                      style: TextStyle(
                        fontFamily: 'Geom',
                        fontSize: ResponsiveSize.text(context, 18),
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                  ),
                  SmallIconButton(
                    iconPath: 'assets/icons/close.svg',
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF3D7F)),
                    )
                  : _videos.isEmpty
                      ? Center(
                          child: Text(
                            'No videos found',
                            style: TextStyle(
                              fontFamily: 'Geom',
                              fontSize: ResponsiveSize.text(context, 16),
                              color: ink,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(ResponsiveSize.spacing(context, 16)),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: ResponsiveSize.spacing(context, 8),
                            crossAxisSpacing: ResponsiveSize.spacing(context, 8),
                            childAspectRatio: 9 / 16,
                          ),
                          itemCount: _videos.length,
                          itemBuilder: (context, index) {
                            final video = _videos[index];
                            return VideoThumbnailTile(
                              video: video,
                              onTap: () => _selectVideo(video),
                              durationText: _formatDuration(video.duration),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoThumbnailTile extends StatefulWidget {
  final AssetEntity video;
  final VoidCallback onTap;
  final String durationText;

  const VideoThumbnailTile({
    super.key,
    required this.video,
    required this.onTap,
    required this.durationText,
  });

  @override
  State<VideoThumbnailTile> createState() => _VideoThumbnailTileState();
}

class _VideoThumbnailTileState extends State<VideoThumbnailTile> {
  ImageProvider? _thumbnail;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final data = await widget.video.thumbnailDataWithSize(
      const ThumbnailSize(300, 400),
      quality: 80,
    );
    if (mounted && data != null) {
      setState(() => _thumbnail = MemoryImage(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ResponsiveSize.spacing(context, 12)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_thumbnail != null)
              Image(
                image: _thumbnail!,
                fit: BoxFit.cover,
              )
            else
              const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFF3D7F),
                ),
              ),
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.durationText,
                  style: TextStyle(
                    fontFamily: 'Geom',
                    fontSize: ResponsiveSize.text(context, 11),
                    color: offWhite,
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

/// Helper function to show the video picker as a modal using IosModalScaffold
/// This will trigger the background shrinking effect
Future<AssetEntity?> showVideoPickerModalWithScaffold(
  GlobalKey<IosModalScaffoldState> scaffoldKey,
) async {
  AssetEntity? selectedVideo;
  
  await IosModalScaffold.show<void>(
    scaffoldKey: scaffoldKey,
    isDismissible: true,
    builder: (context, dismiss) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: VideoPickerScreen(
          onDismiss: dismiss,
          onVideoSelected: (video) {
            selectedVideo = video;
            dismiss();
          },
        ),
      );
    },
  );
  
  return selectedVideo;
}

/// Legacy helper function - kept for backwards compatibility
Future<AssetEntity?> showVideoPickerModal(BuildContext context) async {
  AssetEntity? selectedVideo;
  
  await showModalBottomSheet<AssetEntity>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    enableDrag: true,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        snap: true,
        snapSizes: const [0.4, 0.75, 0.9],
        builder: (context, scrollController) {
          return _DismissibleVideoPickerWrapper(
            onDismiss: () => Navigator.of(context).pop(),
            onVideoSelected: (video) {
              selectedVideo = video;
              Navigator.of(context).pop(video);
            },
          );
        },
      );
    },
  );
  
  return selectedVideo;
}

/// Wrapper that adds swipe-to-dismiss functionality
class _DismissibleVideoPickerWrapper extends StatefulWidget {
  final VoidCallback onDismiss;
  final void Function(AssetEntity video) onVideoSelected;

  const _DismissibleVideoPickerWrapper({
    required this.onDismiss,
    required this.onVideoSelected,
  });

  @override
  State<_DismissibleVideoPickerWrapper> createState() => _DismissibleVideoPickerWrapperState();
}

class _DismissibleVideoPickerWrapperState extends State<_DismissibleVideoPickerWrapper> {
  double _dragOffset = 0;
  final double _dismissThreshold = 150;
  final double _velocityThreshold = 500;

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, double.infinity);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > _velocityThreshold || _dragOffset > _dismissThreshold) {
      widget.onDismiss();
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, _dragOffset, 0),
        child: VideoPickerScreen(
          onDismiss: widget.onDismiss,
          onVideoSelected: widget.onVideoSelected,
        ),
      ),
    );
  }
}
