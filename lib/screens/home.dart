import 'package:flutter/material.dart';
import 'package:slap/models.dart';
import 'package:slap/widgets/file_list.dart';
import 'package:slap/widgets/audio_controls.dart';

class HomeScreen extends StatefulWidget  {
  final AppState appState;
  final PlayItem playItem;
  final CancelTimeout cancelTimeout;
  final LoveItem loveItem;
  final HateItem hateItem;
  final UnloveItem unloveItem;
  final UnhateItem unhateItem;
  final PauseTimeout pauseTimeout;

  HomeScreen({
    @required this.appState,
    @required this.playItem,
    @required this.cancelTimeout,
    @required this.loveItem,
    @required this.hateItem,
    @required this.unloveItem,
    @required this.unhateItem,
    @required this.pauseTimeout,
    Key key
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Sleep like a Pancake", style: TextStyle(color: Colors.blue[700]),), // use a var?  get from somewhere
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          )
        ],
      ),

      body: FileList(
        mediaItems: widget.appState.filteredMediaItems(widget.appState.showHates),
        loading: widget.appState.isLoading,
        playItem: widget.playItem,
        currentID: widget.appState.currentID,
        loveItem: widget.loveItem,
        hateItem: widget.hateItem,
        unloveItem: widget.unloveItem,
        unhateItem: widget.unhateItem,
      ),

      bottomNavigationBar: AudioControls(
        playItem: widget.playItem,
        currentID: widget.appState.currentID,
        cancelTimeout: widget.cancelTimeout,
        pauseTimeout: widget.pauseTimeout,
      ),
    );
  }
}