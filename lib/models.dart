import 'dart:async';

typedef PlayItem = void Function(String id);
typedef CancelTimeout = void Function();
typedef LoveItem = void Function(SleepItem item);
typedef HateItem = void Function(SleepItem item);
typedef UnloveItem = void Function(SleepItem item);
typedef UnhateItem = void Function(SleepItem item);
typedef SetShowHates = void Function(bool value);
typedef SetRepeatPlay = void Function(bool value);
typedef SetAutoStart = void Function(bool value);
typedef SetTimeoutMinutes = void Function(int value);
typedef ReloadFiles = void Function();
typedef StartTimeout = void Function(int);
typedef PauseTimeout = void Function();

class AppState {
  String appName = 'Sleep like a Pancake!';
  String legalese = '\u{a9}'+DateTime.now().year.toString()+' Ryan Lathouwers\n<ryanlath@gmail.com>';
  String version;
  bool isLoading;

  List<SleepItem> mediaItems;
  String currentID;
  String storageDirectory;
  String assetPackDirectory;

  List<String> loveIDs;
  List<String> hateIDs;

  int timeoutMinutes;
  bool repeatPlay;
  bool autoStart;
  bool showHates;

  Timer timer;
  int timerSeconds = 0;

  AppState({
    this.version,
    this.storageDirectory,
    this.assetPackDirectory,
    this.mediaItems = const [],
    this.timeoutMinutes,
    this.repeatPlay,
    this.autoStart,
    this.currentID,
    this.hateIDs,
    this.loveIDs,
    this.showHates,
    this.isLoading = false,
  });

  factory AppState.loading() => AppState(isLoading: true);

  List<SleepItem> filteredMediaItems(bool showAll) =>
    mediaItems.where((item) {
       return (showAll) ? true : item.rating != 0;
    }).toList();
/*
  List<SleepItem> filteredMediaItems(String filter) =>
    mediaItems.where((item) {
      switch (filter) {
        case "hate":
         return item.rating == 0;
        case "love":
          return item.rating == 5;
        case "all-hate":
          return item.rating != 0;
        case "all":
        default:
          return true;
      }
    }).toList();
 */
}

class SleepItem {
  String id;
  String title;
  String album;
  int rating;

  SleepItem({this.id, this.title, this.album, this.rating});

  @override
  String toString() {
    return 'SleepItem{id: $id, title: $title, album: $album, rating: $rating}';
  }

  factory SleepItem.fromJson(Map<String, dynamic> json) {
    return SleepItem(
        id: json['id'] as String,
        title: json['title'] as String,
        album: json['album'] as String,
        rating: json['rating'] as int
    );
  }

  Map<String, Object> toJson() {
    return {
      'id': id,
      'title': title,
      'album': album,
      'rating': rating
    };
  }
}