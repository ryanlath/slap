import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';


void backgroundTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class AudioPlayerTask extends BackgroundAudioTask {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlaybackEvent> _eventSubscription;

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());

    _eventSubscription = _audioPlayer.playbackEventStream.listen((event) {
      _broadcastState();
    });

    _audioPlayer.processingStateStream.listen((state) {
      switch (state) {
        case ProcessingState.completed:
          _audioPlayer.stop();
          _broadcastState();
          break;
        default:
          break;
      }
    });
  }

  @override
  Future<void> onPlayMediaItem(MediaItem mediaItem) async {
    try {
      if (mediaItem.id[0] == '/') {
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse('file:///${mediaItem.id}')),
            initialPosition: Duration.zero, preload: true);
      } else {
        await _audioPlayer.setAsset(mediaItem.id);
      }
      AudioServiceBackground.setMediaItem(mediaItem);
      _audioPlayer.play();
    } catch (e) {
      print(e); //TODO:
      _audioPlayer.stop();
      throw 'TODO: Could not load audio file.';
    }
  }

  @override
  Future<void> onPlay() => _audioPlayer.play();

  @override
  Future<void> onPause() => _audioPlayer.pause();

  @override
  Future<void> onStop() async {
    await _audioPlayer.dispose();
    _eventSubscription.cancel();
    await _broadcastState();
    await super.onStop();
  }

  @override
  Future<void> onSetRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _audioPlayer.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _audioPlayer.setLoopMode(LoopMode.all);
        break;
    }
  }
/*
//stop playback on swipe away in task manmger>?
  void onTaskRemoved() {
    onStop();
  }
 */

 /// Broadcasts the current state to all clients.
  Future<void> _broadcastState() async {
    await AudioServiceBackground.setState(
      controls: [
        if (_audioPlayer.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      //androidCompactActions: [0, 1, 3],
      processingState: _getProcessingState(),
      playing: _audioPlayer.playing,
      position: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      speed: _audioPlayer.speed,
    );
  }

  /// Map just_audio's processing state into into audio_service's playing state.
  AudioProcessingState _getProcessingState() {
    switch (_audioPlayer.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.stopped;
      case ProcessingState.loading:
        return AudioProcessingState.connecting;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        throw Exception("Invalid state: ${_audioPlayer.processingState}");
    }
  }
}