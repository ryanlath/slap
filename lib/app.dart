import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:audio_service/audio_service.dart';
import "package:collection/collection.dart";
import 'package:key_value_store_flutter/key_value_store_flutter.dart';
import 'package:package_info/package_info.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:slap/audio_player.dart';
import 'package:slap/models.dart';
import 'package:slap/screens/home.dart';
import 'package:slap/screens/settings.dart';


class SlapApp extends StatefulWidget {
  final FlutterKeyValueStore kvs;

  SlapApp({@required this.kvs});

  @override
  State<StatefulWidget> createState() {
    return SlapAppState();
  }
}

class SlapAppState extends State<SlapApp> {
  AppState appState = AppState.loading();
  List<String> loveIDs;
  List<String> hateIDs;

  static const MethodChannel methodChannel = MethodChannel('slap.pancake.org/assetpack');

  @override
  void initState() {
    super.initState();

    String _storageDirectory;
    String _assetPackDirectory;
    String _version;

    loveIDs = widget.kvs.getStringList('loveIDs') ?? List<String>();
    hateIDs = widget.kvs.getStringList('hateIDs') ?? List<String>();

    //TODO: find better way
    //TODO: make "loading assets...???  first time only?"
    getAssetPackDirectory().then((assetPackDirectory) {
      _assetPackDirectory = assetPackDirectory;  
      
      getStorageDirectory().then((storageDirectory) {
        _storageDirectory = storageDirectory;

        getVersion().then((version) {
          _version = version;

          loadMediaItems(loveIDs, hateIDs, _assetPackDirectory).then((loadedItems) {
            setState(() {
              appState = AppState(
                version: _version,
                storageDirectory: _storageDirectory,
                assetPackDirectory: _assetPackDirectory,
                mediaItems: loadedItems,
                timeoutMinutes: loadTimeout(),
                repeatPlay: widget.kvs.getBool('repeatPlay') ?? true,
                autoStart: widget.kvs.getBool('autoStart') ?? false,
                currentID: widget.kvs.getString('currentID') ?? null,
                loveIDs: loveIDs,
                hateIDs: hateIDs,
                showHates: widget.kvs.getBool('showHates') ?? false,
              );
            });

            if (appState.autoStart && appState.currentID != null) {
              playItem(appState.currentID);
            }
          }).catchError((err) {
            setState(() {
              appState.isLoading = false;
            });
            print("LOADING ERROR:" + err.toString());
            //throw("LOADING ERROR:" + err.toString());
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: AudioServiceWidget(
        child: HomeScreen(
          appState: appState,
          playItem: playItem,
          cancelTimeout: cancelTimeout,
          loveItem: loveItem,
          hateItem: hateItem,
          unloveItem: unloveItem,
          unhateItem: unhateItem,
          pauseTimeout: pauseTimeout,
        )
      ),
      routes: {
        '/settings' : (context) => SettingsScreen(
          appState: appState,
          setShowHates: setShowHates,
          setRepeatPlay: setRepeatPlay,
          setTimeoutMinutes: setTimeoutMinutes,
          setAutoStart: setAutoStart,
          reloadFiles: reloadFiles,
          startTimeout: startTimeout,
        ),
      },
    );
  }

 Future<String> getAssetPackDirectory() async {
    String assetPackDirectory;
    try {
      final String result = await methodChannel.invokeMethod('getAssetPackDirectory', 'assetsaudio');
      assetPackDirectory = result;
    } catch(e)  {
      debugPrint('SlapMain : failed:'+e.toString());
      // throw Exception() ?
    }
    return assetPackDirectory;
  }

  Future<String> getVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version+'+'+info.buildNumber;
  }

  void playItem(String itemID) async {
    if (!AudioService.running) {
      await AudioService.start(
        backgroundTaskEntrypoint: backgroundTaskEntrypoint,
        androidNotificationChannelName: 'Sleep like a Pancake',
        // Enable this if you want the Android service to exit the foreground state on pause.
        //androidStopForegroundOnPause: true,
        androidNotificationColor: 0xFF2196f3,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidEnableQueue: true,
      );
      
      if (appState.repeatPlay) {
        AudioService.setRepeatMode(AudioServiceRepeatMode.one);
      } else {
        AudioService.setRepeatMode(AudioServiceRepeatMode.none);
      }
    }

    final bool playing = AudioService.playbackState?.playing ?? false;
    final bool noChange = (itemID == appState.currentID);
   
    if (!playing || !noChange) {
      if (noChange && AudioService.currentMediaItem != null) {
        // resume
        AudioService.play();
        resumeTimeout();
      } else {
        // load new item
        try {
          SleepItem item = appState.mediaItems.singleWhere((SleepItem item) => item.id.contains(itemID), orElse: () => null);
          //TODO: IF NOT ITEM...???
          //throw "!@#$";
          MediaItem mediaItem = MediaItem(
            id: item.id,
            title: item.title,
            album: item.album,
            rating: (item.rating == -1) ? null : Rating.newStarRating(RatingStyle.range5stars, item.rating)
          );

          AudioService.playMediaItem(mediaItem);

          widget.kvs.setString('currentID', itemID);
          setState((){
            appState.currentID = itemID;
          });

        } catch(e) {
          //TOOD:    
          print("playMediaItem failed.");
        }
        startTimeout(appState.timeoutMinutes * 60);
      }
    }
  }

  pauseTimeout() {
      cancelTimeout();
  }

  resumeTimeout() {
    if (appState.timerSeconds > 0) {
      startTimeout(appState.timerSeconds);
    } else {
      startTimeout(appState.timeoutMinutes * 60);
    }
  }

  startTimeout(int timeoutSeconds) {
    if (timeoutSeconds == 0) {
      return;
    }

    cancelTimeout();

    setState(() {
      appState.timerSeconds = timeoutSeconds;  
    }); 
    
    appState.timer = Timer.periodic(
      Duration(seconds: 1),
      (Timer timer) { 
        if (appState.timerSeconds <= 0) {
          appState.timer.cancel();
          AudioService.stop();
        } else {
          setState(() {
            appState.timerSeconds--;  
          });
        }
      }
    );
  }

  cancelTimeout() {
    if (appState.timer != null) {
      appState.timer.cancel();
    }
  }

  int loadTimeout() {
   return widget.kvs.getInt('timeoutMinutes') ?? 120;
  }

  void setTimeoutMinutes(int value) {
    setState(() {
      appState.timeoutMinutes = value;
    });
    widget.kvs.setInt('timeoutMinutes', value);
  }

  void setShowHates(bool value) {
    setState(() {
      appState.showHates = value;
    });
    widget.kvs.setBool('showHates', value);
  }

  void setRepeatPlay(bool value) {
    setState(() {
      appState.repeatPlay = value;
    });
    widget.kvs.setBool('repeatPlay', value);
  }

  void setAutoStart(bool value) {
    setState(() {
      appState.autoStart = value;
    });
    widget.kvs.setBool('autoStart', value);
  }

  void loveItem(SleepItem mediaItem) {
    if (appState.loveIDs.contains(mediaItem.id)) {
      return;
    }

    int index  = appState.mediaItems.indexWhere((SleepItem item) =>
        item.id.contains(mediaItem.id));
    if (index == -1) {
      print("TODO: not found");
      return;
    }

    setState(() {
      appState.mediaItems[index].rating = 5;
      appState.loveIDs.add(mediaItem.id);
    });

    widget.kvs.setStringList('loveIDs', appState.loveIDs);
    widget.kvs.setString('mediaItems', json.encode(appState.mediaItems));
  }

  void unloveItem(SleepItem mediaItem) {
    if (!appState.loveIDs.contains(mediaItem.id)) {
      //throw error?
      return;
    }

    int index  = appState.mediaItems.indexWhere((SleepItem item) =>
        item.id.contains(mediaItem.id));
    if (index == -1) {
      print("TODO: not found");
      return;
    }

    setState(() {
      appState.mediaItems[index].rating = -1;
      appState.loveIDs.remove(mediaItem.id);
    });

    widget.kvs.setStringList('loveIDs', appState.loveIDs);
    widget.kvs.setString('mediaItems', json.encode(appState.mediaItems));
  }

  void hateItem(SleepItem mediaItem) {
    if (appState.hateIDs.contains(mediaItem.id)) {
      return;
    }

    int index = appState.mediaItems.indexWhere((SleepItem item) =>
        item.id.contains(mediaItem.id));
    if (index == -1) {
      print("TODO: not found");
      return;
    }

    setState(() {
      appState.mediaItems[index].rating = 0;
      appState.hateIDs.add(mediaItem.id);
    });

    widget.kvs.setStringList('hateIDs', appState.hateIDs);
    widget.kvs.setString('mediaItems', json.encode(appState.mediaItems));
  }

  void unhateItem(SleepItem mediaItem) {
    if (!appState.hateIDs.contains(mediaItem.id)) {
      return;
    }

    int index = appState.mediaItems.indexWhere((SleepItem item) =>
        item.id.contains(mediaItem.id));
    if (index == -1) {
      print("TODO: not found");
      return;
    }

    setState(() {
      appState.mediaItems[index].rating = -1;
      appState.hateIDs.remove(mediaItem.id);
    });

    widget.kvs.setStringList('hateIDs', appState.hateIDs);
    widget.kvs.setString('mediaItems', json.encode(appState.mediaItems));
  }
  
  Future<String> getStorageDirectory() async {
    Directory storageDir = await _getStorageDirectory();

    return storageDir.toString();
  }

  //TODO: allow settable 
  Future<Directory> _getStorageDirectory() async {
    Directory storageDir = await getExternalStorageDirectory();
    return Directory(join(storageDir.path, 'Music'));
  }

  void reloadFiles() {
    loadMediaItems(appState.loveIDs, appState.hateIDs, appState.assetPackDirectory, reload:true).then((loadedItems) {
      setState(() {
        appState.mediaItems = loadedItems;
      });
    });
  }

  Future <List<SleepItem>> loadMediaItems(loveIDs, hateIDs, assetPackDirectory, {reload: false}) async {
    List<SleepItem> mediaItems;

    final init =  widget.kvs.getBool('initialized') ?? false;

    if (init && !reload) {
      try {
        final parsed = jsonDecode(widget.kvs.getString('mediaItems')).cast<Map<String, dynamic>>();
        mediaItems = parsed.map<SleepItem>((json) => SleepItem.fromJson(json)).toList();
     } catch(e) {
        //TODO:
        print(e);
      }
      return mediaItems;
    }

    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final assetFiles = manifestMap.keys
        .where((String key) => key.contains('audio/'))
        .toList();

    Directory storageDir = await _getStorageDirectory();
    if (await storageDir.exists() == false) {
      //TODO: try/catch
      await storageDir.create(recursive: true);
    }

    List<String> storageFiles = [];
    var files =  storageDir.list(recursive: true, followLinks: false);
    await for (FileSystemEntity file in files) {
      storageFiles.add(file.path);
    }

    //String assetPackDirectory = appState.assetPackDirectory;
    if (assetPackDirectory != null) {
       debugPrint('SlapMain : assetPackDirectory:'+assetPackDirectory);

      Directory packDir = Directory(assetPackDirectory);

      files = packDir.list(recursive: true, followLinks: false);
      await for (FileSystemEntity file in files) {
        storageFiles.add(file.path);
      }
    } else {
      debugPrint('SlapMain : AP is NULL!');
    }

    mediaItems = [
      ..._loadFiles(assetFiles, loveIDs, hateIDs),
      ..._loadFiles(storageFiles, loveIDs, hateIDs),
    ];

    mediaItems.sort((a, b) {
      return compareAsciiUpperCase(a.title, b.title);
    });
/*
    TODO: make opts?

    // sort: album, title
    mediaItems.sort((a, b) {
      int cmp = compareAsciiUpperCase(a.album, b.album);
      if (cmp != 0) return cmp;
      return compareAsciiUpperCase(a.title, b.title);
    });

    // sort favs, title
    mediaItems.sort((a, b) {
      int cmp = b.rating.compareTo(a.rating);
      if (cmp != 0) return cmp;
      return compareAsciiUpperCase(a.title, b.title);
    });
*/

    widget.kvs.setString('mediaItems', json.encode(mediaItems));
    widget.kvs.setBool('initialized', true);

    return mediaItems;
  }

  List<SleepItem> _loadFiles(List<String> files, loveIDs, hateIDs) { 
    List<String> extensions = ['.mp3', '.ogg', '.wav', '.flac'];
    List<SleepItem> mediaItems = [];

    for (String file in files) {
      if (extensions.indexOf(extension(file)) == -1) {
        continue;
      }

      String album = basename(dirname(file));

      int rating = -1;
      if (loveIDs.contains(file)) {
        rating = 5;
      } else if (hateIDs.contains(file)) {
        rating = 0;
      }

      mediaItems.add(SleepItem(
        id: file,
        album: album,
        title: basenameWithoutExtension(file).replaceAll('_', ' ').replaceAll('%20', ' '),
        rating: rating,
      ));
    }

    return mediaItems;
  }
}