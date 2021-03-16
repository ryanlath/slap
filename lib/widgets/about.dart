import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:slap/models.dart';
import 'package:slap/widgets/credits.dart';


class About extends StatelessWidget {
  final AppState appState;

  About({
    @required this.appState,
    Key key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.info),
      title: Text('About'),
      onTap: () {
        _showAbout(context);
      },
    );
  }

  _showAbout(context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          actions: [
            TextButton(
              child: Text('SOUND CREDITS'),
              onPressed: () {
                showCredits(context);
              },
            ),
            TextButton(
              child: Text('LICENSES'),
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationIcon:   Image(
                    image: AssetImage('android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png'),
                    height: 96,
                    width: 96,
                  ),
                  applicationName: appState.appName,
                  applicationVersion: 'Version: '+ appState.version,
                  applicationLegalese: appState.legalese,
                );
              },
            ),
            TextButton(
              child: Text('CLOSE'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          content: SingleChildScrollView(                  
            child: Container(
              padding: const EdgeInsets.only(left: 4, right:4, top:0, bottom:0),
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right:12, top:0, bottom:0),
                        child: Image(
                          image: AssetImage('android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png'),
                          height: 96,
                          width: 96,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appState.appName, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold ),),
                          SizedBox(height:8),
                          Text('Version: '+ appState.version,
                            style: TextStyle(fontSize: 12)),
                          Text(appState.legalese,
                            style: TextStyle(fontSize: 11, color: Colors.grey),),
                        ],
                      ),
                    ],
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: FutureBuilder(
                      future: rootBundle.loadString("ABOUT.md"),
                      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                        if (snapshot.hasData) {
                          return Markdown(
                            data: snapshot.data,
                            onTapLink: (text, url, title) {
                              launch(url);
                            },
                            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                                .copyWith(p: TextStyle(height:1.5), a: TextStyle(color:Colors.blue[300]), textScaleFactor: 1.2,)
                            ,
                          );
                        }

                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),
          )
        );
      }
    );
  }
}