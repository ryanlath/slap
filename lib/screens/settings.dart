import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:slap/models.dart';
import 'package:slap/widgets/about.dart';
import 'package:slap/widgets/credits.dart';

class SettingsScreen extends StatefulWidget {
  final AppState appState;
  final SetShowHates setShowHates;
  final SetRepeatPlay setRepeatPlay;
  final SetTimeoutMinutes setTimeoutMinutes;
  final SetAutoStart setAutoStart;
  final ReloadFiles reloadFiles;
  final StartTimeout startTimeout;

  SettingsScreen({
    @required this.appState,
    @required this.setShowHates,
    @required this.setRepeatPlay,
    @required this.setTimeoutMinutes,
    @required this.setAutoStart,
    @required this.reloadFiles,
    @required this.startTimeout,
    Key key
  }) : super(key: key);

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Slap! Settings'),
      ),
      body: settingsList(),
    );
  }

  Widget settingsList() {
    return ListView(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left:16, top:16, bottom:8),
          child: Text(
            "Settings",
            style: TextStyle(

              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        autoStartSetting(),
        Divider(height:1),
        repeat(),
        Divider(height:1),
        showHates(),
        Divider(height:1),
        timeOut(),
        Divider(height:1),
        userDirectory(),

        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            "Actions",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        reload(),

        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            "About",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Credits(),
        Divider(height:1),
        About(appState: widget.appState),
      ],
    );
  }

  Widget reload() {
    return ListTile(
      leading: Icon(Icons.refresh),
      title: Text('Reload library'),
      subtitle: Text('If you add files to your Audio Folder...'),
      onTap: () {
        widget.reloadFiles();
      },
    );
  }

  Widget autoStartSetting() {
    return SwitchListTile(
      title: Text('Auto Start Playing'),
      value: widget.appState.autoStart,
      onChanged: (bool value) {
        widget.setAutoStart(value);
      },
      secondary: const Icon(Icons.play_circle_outline),
    );
  }

  Widget showHates() {
    return SwitchListTile(
      title: Text('Show "Thumbs Down" Items'),
      value: widget.appState.showHates,
      onChanged: (bool value) {
        widget.setShowHates(value);
      },
      secondary: const Icon(Icons.thumb_down),
    );
  }

  //TODO: make configable...
  Widget userDirectory() {
    return ListTile(
      leading: Icon(Icons.folder_special_outlined),
      title: Text("User's Audio Folder"),
      subtitle: TextFormField (
        readOnly: true,
        initialValue: widget.appState.storageDirectory,
        decoration: const InputDecoration(
          labelText: 'Put files here, then Reload below.',
        ),
      ),
    );
  }

  Widget timeOut() {
    return ListTile(
      leading: Icon(Icons.timer),
      title: Text('Timeout in minutes: '+formatTime(widget.appState.timerSeconds)),
      subtitle: Text('Set at 0 to disable.'),
      trailing: Container(
        width:100,
        height: 40,
        child: TextFormField(
          initialValue: widget.appState.timeoutMinutes.toString(),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(8),
            border: OutlineInputBorder(),
          ),
          autovalidateMode: AutovalidateMode.always,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly
          ],
          onChanged: (value) {
            final intVal = num.parse(value);
            widget.setTimeoutMinutes(intVal);
            if (AudioService.running) {
              if (intVal == 0) {
                widget.appState.timer?.cancel();
              } else {
                final bool playing = AudioService.playbackState?.playing ?? false;
                if (playing) {
                  widget.startTimeout(intVal * 60);
                }
              }
            }
          },
          validator: (value) {
            final n = num.tryParse(value);

            if (value.isEmpty || n == null) {
              return 'Invalid timeout value!';
            }
            return null;
          },
        )
      )
    );
  }

  formatTime(int seconds) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    String output = '';

    int hour = seconds ~/ 3600;
    int minute = seconds % 3600 ~/ 60;
    int second = seconds % 60;

    if (hour > 0) {
      output = twoDigits(hour)+':';
    }
    if (minute > 0) {
      output += twoDigits(minute)+":";
    }
    
    return output += twoDigits(second);
  }

  Widget repeat() {
    return SwitchListTile(
      secondary: Icon(Icons.repeat),
      title: Text('Repeat/Loop'),
      value: widget.appState.repeatPlay,
      onChanged: (bool value) {
        widget.setRepeatPlay(value);
        if (AudioService.running) {
          if (value) {
            AudioService.setRepeatMode(AudioServiceRepeatMode.one);
          } else {
            AudioService.setRepeatMode(AudioServiceRepeatMode.none);
          }
        }
      },
    );
  }
}