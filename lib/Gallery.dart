import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class Gallery extends StatefulWidget {
  final DateTime start,end;

  const Gallery({Key key, this.start, this.end}) : super(key: key);

  @override
  _GalleryState createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  // This will hold all the assets we fetched
  List<AssetEntity> assets = [];
  FilterOptionGroup _makeOption({
    minWidth = '0',
    maxWidth = '10000',
    minHeight = '0',
    maxHeight = '10000',
    ignoreSize = false,
    minDuration = Duration.zero,
    maxDuration = const Duration(hours: 1),
    needTitle = false,
    startDt,
    endDt,
  }) {
    startDt ??= widget.start;
    endDt ??= widget.end;
    SizeConstraint sizeConstraint;
    try {
      final minW = int.tryParse(minWidth);
      final maxW = int.tryParse(maxWidth);
      final minH = int.tryParse(minHeight);
      final maxH = int.tryParse(maxHeight);
      sizeConstraint = SizeConstraint(
        minWidth: minW,
        maxWidth: maxW,
        minHeight: minH,
        maxHeight: maxH,
        ignoreSize: ignoreSize,
      );
    } catch (e) {
      return null;
    }
    final durationConstraint = DurationConstraint(
      min: minDuration,
      max: maxDuration,
    );

    final option = FilterOption(
      sizeConstraint: sizeConstraint,
      durationConstraint: durationConstraint,
      needTitle: needTitle,
    );
    final dateTimeCond = DateTimeCond(
      min: startDt,
      max: endDt,
//      asc: false,
    );

    return FilterOptionGroup()
      ..setOption(AssetType.image, option)
      ..createTimeCond = dateTimeCond;
  }

  @override
  void initState() {
    _fetchAssets();
    super.initState();
  }

  _fetchAssets() async {
    // Set onlyAll to true, to fetch only the 'Recent' album
    // which contains all the photos/videos in the storage
    final option = _makeOption();
    final albums = await PhotoManager.getAssetPathList(onlyAll: true,filterOption:option);
    final recentAlbum = albums.first;

    // Now that we got the album, fetch all the assets it contains
    final recentAssets = await recentAlbum.getAssetListRange(

      start: 0, // start at index 0

      end: 1000000, // end at a very big index (to get all the assets)
    );

    // Update the state and notify UI
    setState(() => assets = recentAssets);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

        body:Column(
          children: [
            RaisedButton(
              color: Colors.pinkAccent,
              onPressed: () async {
                final permitted = await PhotoManager.requestPermission();
                if (!permitted) return;

                Navigator.pushNamed(context, '/W2');
              },
              child: Text('Show Photos'),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  // A grid view with 3 items per row
                  crossAxisCount: 3,
                  crossAxisSpacing: 8, mainAxisSpacing: 4,
                ),
                itemCount: assets.length,
                itemBuilder: (_, index) {
                  return AssetThumbnail(asset: assets[index]);
                },
              ),
            ),
          ],)
    );
  }
}
class AssetThumbnail extends StatelessWidget {
  const AssetThumbnail({
    Key key,
    @required this.asset,
  }) : super(key: key);

  final AssetEntity asset;

  @override
  Widget build(BuildContext context) {
    // We're using a FutureBuilder since thumbData is a future
    return FutureBuilder<Uint8List>(
      future: asset.thumbData,
      builder: (_, snapshot) {
        final bytes = snapshot.data;
        // If we have no data, display a spinner
        if (bytes == null) return Container(width:20,height: 20,child: CircularProgressIndicator());
        // If there's data, display it as an image
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) {
                  if (asset.type == AssetType.image) {
                    // If this is an image, navigate to ImageScreen
                    return ImageScreen(imageFile: asset.file);
                  } else {
                    // if it's not, navigate to VideoScreen
                    return VideoScreen(videoFile: asset.file);
                  }
                },
              ),
            );
          },
          child: Stack(
            children: [
              // Wrap the image in a Positioned.fill to fill the space
              Positioned.fill(
                child: Image.memory(bytes, fit: BoxFit.cover),
              ),
              // Display a Play icon if the asset is a video
              if (asset.type == AssetType.video)
                Center(
                  child: Container(
                    color: Colors.blue,
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ImageScreen extends StatelessWidget {
  const ImageScreen({
    Key key,
    @required this.imageFile,
  }) : super(key: key);

  final Future<File> imageFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: FutureBuilder<File>(
        future: imageFile,
        builder: (_, snapshot) {
          final file = snapshot.data;
          if (file == null) return Container();
          return Image.file(file);
        },
      ),
    );
  }
}

class VideoScreen extends StatefulWidget {
  const VideoScreen({
    Key key,
    @required this.videoFile,
  }) : super(key: key);

  final Future<File> videoFile;

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  VideoPlayerController _controller;
  bool initialized = false;

  @override
  void initState() {
    _initVideo();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _initVideo() async {
    final video = await widget.videoFile;
    _controller = VideoPlayerController.file(video)
    // Play the video again when it ends
      ..setLooping(true)
    // initialize the controller and notify UI when done
      ..initialize().then((_) => setState(() => initialized = true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: initialized
      // If the video is initialized, display it
          ? Scaffold(
        body: Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            // Use the VideoPlayer widget to display the video.
            child: VideoPlayer(_controller),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Wrap the play or pause in a call to `setState`. This ensures the
            // correct icon is shown.
            setState(() {
              // If the video is playing, pause it.
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                // If the video is paused, play it.
                _controller.play();
              }
            });
          },
          // Display the correct icon depending on the state of the player.
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
      )
      // If the video is not yet initialized, display a spinner
          : Center(child: CircularProgressIndicator()),
    );
  }
}