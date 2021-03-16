import 'package:flutter/material.dart';
import 'package:key_value_store_flutter/key_value_store_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slap/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
    return Scaffold(
        body: SingleChildScrollView(
          padding:  EdgeInsets.only(left: 12, right: 12, top: 20, bottom: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Text('ERROR', style: TextStyle(fontSize: 24)),
              Divider(height:20),
              Text(errorDetails.exception.toString(), style: TextStyle(height:2, fontSize: 16),),
              Divider(height:40),
              Container(
                height: 174,
                child: Text(errorDetails.stack.toString(),style: TextStyle(height:1.5)),
              ),
            ],
          ),
        )
    );
  };

  runApp(
    SlapApp(
      kvs: FlutterKeyValueStore(await SharedPreferences.getInstance()),
    ),
  );
}
