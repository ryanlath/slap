import 'package:flutter/material.dart';
import 'package:slap/models.dart';

class FileList extends StatelessWidget {
  final List<SleepItem> mediaItems;
  final bool loading;
  final PlayItem playItem;
  final String currentID;
  final LoveItem loveItem;
  final HateItem hateItem;
  final UnloveItem unloveItem;
  final UnhateItem unhateItem;

  FileList({
    @required this.mediaItems,
    @required this.loading,
    @required this.playItem,
    @required this.currentID,
    @required this.loveItem,
    @required this.hateItem,
    @required this.unloveItem,
    @required this.unhateItem,

    Key key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: loading
        ? Center(child: CircularProgressIndicator())
        : ListView.separated(
            
          itemCount: mediaItems.length,
          itemBuilder: (context, index) {
            SleepItem mediaItem = mediaItems[index];
            return ListTile(
              selectedTileColor: Colors.blue[900],
              contentPadding: EdgeInsets.only(left: 12, right: 0, top: 0, bottom: 0),
              title: Text(
                mediaItem.title,
                style: (mediaItem.id == currentID) ?
                  TextStyle(fontWeight: FontWeight.bold)
                  :
                  null,
              ),
              selected: mediaItem.id == currentID,
              subtitle: Text(mediaItem.album),
              onTap: () async {
                playItem(mediaItem.id);
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  showRating(mediaItem.rating),
                  popupMenuLocal(index, mediaItems[index], loveItem, hateItem),
                ],
              )
            );
          },
          separatorBuilder: (context, index) {
            return Divider(height:0);
          },
        ),
    );
  }

  showRating(rating) {
    if (rating == 5)
      return Icon(Icons.favorite, color: Colors.red,);
    else if  (rating == 0)
      return Icon(Icons.sentiment_very_dissatisfied);
    else
      return SizedBox.shrink();
  }

  Widget popupMenuLocal(index, mediaItem, loveItem, hateItem) {
    return PopupMenuButton(
      //onTap overrides..
      onSelected: (value) {
        if (value == "hate") {
          unloveItem(mediaItem);
          hateItem(mediaItem);
        } else if (value == "love") {
          unhateItem(mediaItem);
          loveItem(mediaItem);
        } else if (value == "unlove") {
          unloveItem(mediaItem);
        } else if (value == "unhate") {
          unhateItem(mediaItem);
        } else {
          //throw error?
        }
      },
      offset: Offset(0, 100),
      itemBuilder: (BuildContext context) =>
      <PopupMenuEntry<Object>>[
        (mediaItem.rating == 5)
        ?
        PopupMenuItem<String>(
          value: "unlove",
          child: ListTile(
            leading: Icon(Icons.favorite_border),
            title: Text('Un-Love It'),
          ),
        )
        :
        PopupMenuItem<String>(
          value: "love",
          child: ListTile(
            leading: Icon(Icons.thumb_up),
            title: Text('Love It'),
          ),
        ),
        PopupMenuDivider(height: 1),
        (mediaItem.rating == 0) 
        ?
        PopupMenuItem<String>(
          value: "unhate",
          child: ListTile(
            leading: Icon(Icons.sentiment_very_dissatisfied_outlined),
            title: Text('Un-Hate It'),
          ),
        )
        :
        PopupMenuItem<String>(
          value: "hate",
          child: ListTile(
            leading: Icon(Icons.thumb_down),
            title: Text('Hate It'),
          ),
        ),
      ],
    );
  }
}