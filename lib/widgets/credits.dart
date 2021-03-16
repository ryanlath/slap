import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class Credits extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.notes),
      title: Text('Sound Credits'),
      onTap: () {
        showCredits(context);
      },
    );
  }
}

void showCredits(context) {
  showGeneralDialog(
      context: context,
      transitionDuration: Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Sound Credits"),
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: (){
                  Navigator.pop(context);
                }
            ),
          ),
          body: FutureBuilder(

            future: rootBundle.loadString("CREDITS.md"),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.hasData) {
                return Markdown(
                  data: snapshot.data,
                  onTapLink: (text, url, title) {
                    launch(url);
                  },
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                   .copyWith(a: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.blue[300]))
                  ,
                );
              }

              return Center(
                child: CircularProgressIndicator(),
              );
            }
          ),
        );
      }
  );
}