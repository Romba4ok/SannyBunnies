import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadPage extends StatefulWidget {
  const LoadPage({Key? key}) : super(key: key);

  @override
  State<LoadPage> createState() => _LoadPageState();
}

class _LoadPageState extends State<LoadPage> {
  late VideoPlayerController _controller;
  bool _isVideoError = false;
  bool _isReadyToPlay = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/images/loadPage/sunny.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        _controller.setLooping(true);
        _controller.setVolume(0);
        setState(() {
          _isReadyToPlay = true;
        });
        _controller.play();
      }).catchError((error) {
        debugPrint("❌ Ошибка загрузки видео: $error");
        if (mounted) {
          setState(() {
            _isVideoError = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    double targetAspectRatio = _controller.value.isInitialized
        ? _controller.value.aspectRatio
        : 1.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FractionallySizedBox(
          widthFactor: 0.6,
          child: AspectRatio(
            aspectRatio: targetAspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1B191B), 
                borderRadius: BorderRadius.circular(25),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/loadPage/sunny.svg',
                        fit: BoxFit.cover, 
                        
                      ),
                    ),

                    
                    if (!_isVideoError && _controller.value.isInitialized && _isReadyToPlay)
                      Positioned.fill(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                    
                    
                    if (_isVideoError)
                      const Center(
                        child: Icon(Icons.videocam_off_outlined, color: Colors.white24, size: 30),
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


