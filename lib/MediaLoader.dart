import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaLoader extends StatelessWidget {
  final String fileImgOrVideo;

  MediaLoader({required this.fileImgOrVideo});

  @override
  Widget build(BuildContext context) {
    bool isVideo = fileImgOrVideo.endsWith('.mp4');

    return isVideo ? _buildVideoPlayer() : _buildImage();
  }

  Widget _buildImage() {
    return Image.network(
      fileImgOrVideo,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(child: Text('Không thể tải hình ảnh.'));
      },
    );
  }

  Widget _buildVideoPlayer() {
    return FutureBuilder<VideoPlayerController>(
      future: _initializeVideoPlayerController(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AspectRatio(
            aspectRatio: snapshot.data!.value.aspectRatio,
            child: VideoPlayer(snapshot.data!),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<VideoPlayerController> _initializeVideoPlayerController() async {
    VideoPlayerController controller = VideoPlayerController.network(fileImgOrVideo);
    await controller.initialize();
    controller.setLooping(true);
    return controller;
  }
}
