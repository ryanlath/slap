import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:slap/models.dart';

class AudioControls extends StatelessWidget {
  final PlayItem playItem;
  final CancelTimeout cancelTimeout;
  final String currentID;
  final PauseTimeout pauseTimeout;

  AudioControls({
    @required this.playItem,
    @required this.currentID,
    @required this.cancelTimeout,
    @required this.pauseTimeout,
    Key key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Container(
        height:140,
        child: Column(
          children: [
            Container(
              color: Theme.of(context).primaryColor,
              height:50,
              child:Center(
                child: nowPlaying(),
              )
            ),
            Container(
              color: Colors.black,
              height:90,
              child:Center(
                child: audioControls(),
              )
            ),
          ]
        )
      )
    );
  }

  Widget nowPlaying() {
    return StreamBuilder<MediaItem>(
      stream: AudioService.currentMediaItemStream,
      builder: (context, snapshot) {
        return AnimatedSwitcher(
          duration: const Duration(seconds: 1),
          child: snapshot.hasData
            ? Text(snapshot.data.title)
            : Center(),
        );
      }
    );
  }

  Widget audioControls() {
    return StreamBuilder<bool>(
      stream: AudioService.playbackStateStream
        .map((state) => state.playing)
        .distinct(),
      builder: (context, snapshot) {
        final playing = snapshot.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (playing)
              pauseButton()
            else
              playButton(),

            stopButton(),
          ],
        );
      },
    );
  }

  IconButton playButton() =>
    IconButton(
      icon: Icon(Icons.play_arrow),
      iconSize: 64.0,
      onPressed: currentID == null ? null : () async {
        playItem(currentID);
      },
    );

  IconButton pauseButton() =>
    IconButton(
      icon: Icon(Icons.pause),
      iconSize: 64.0,
      onPressed: () {
        pauseTimeout();
        AudioService.pause();
      },
    );

  stopButton() => StreamBuilder<bool>(
      stream: AudioService.runningStream,
      builder: (context, snapshot) {
        final running = snapshot.data ?? false;
        return (running) ? _stopButton() : Container(child:Text(''));
      },
    );

  IconButton _stopButton() =>
    IconButton(
      icon: Icon(Icons.stop),
      iconSize: 64.0,
      onPressed: () {
        AudioService.stop();
        cancelTimeout();
      },
    );
}
