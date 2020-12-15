import 'package:flutter/material.dart';
import 'dart:async';

import 'package:background_location_tracker/background_location_tracker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void _onLocationUpdate() {
  BackgroundLocationTrackerManager.setLogging(true);
  BackgroundLocationTrackerManager.handleBackgroundUpdated((data) => Repo().update(data));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundLocationTrackerManager.setLogging(true);
  await BackgroundLocationTrackerManager.initialize(_onLocationUpdate);
  runApp(MyApp());
}

@override
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var isTracking = false;

  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            MaterialButton(
              child: Text('Start Tracking'),
              onPressed: isTracking
                  ? null
                  : () {
                      BackgroundLocationTrackerManager.startTracking();
                      setState(() => isTracking = true);
                    },
            ),
            MaterialButton(
              child: Text('Stop Tracking'),
              onPressed: isTracking
                  ? () {
                      BackgroundLocationTrackerManager.stopTracking();
                      setState(() => isTracking = false);
                    }
                  : null,
            ),
            Expanded(
              child: Center(
                child: StreamBuilder<List<BackgroundLocationUpdateData>>(
                  stream: Repo().stream,
                  builder: (context, value) {
                    if (!value.hasData || value.data.isEmpty) {
                      return Text('Empty');
                    }
                    return ListView.builder(
                      itemCount: value.data.length,
                      itemBuilder: (BuildContext context, int index) {
                        final item = value.data[index];
                        return Text('Lat: ${item.lat}, Lon: ${item.lon}');
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Repo {
  static Repo _instance;
  final _list = List<BackgroundLocationUpdateData>();
  final _controller = StreamController<List<BackgroundLocationUpdateData>>.broadcast();

  Stream<List<BackgroundLocationUpdateData>> get stream => _controller.stream;

  Repo._();

  factory Repo() {
    if (_instance == null) {
      _instance = Repo._();
    }
    return _instance;
  }

  void update(BackgroundLocationUpdateData data) {
    _list.add(data);
    _controller.add(_list);
    sendNotification('Location Update: Lat: ${data.lat} Lon: ${data.lon}');
  }
}

Future<void> sendNotification(String body) async {
  final settings = InitializationSettings(android: AndroidInitializationSettings('app_icon'));
  await FlutterLocalNotificationsPlugin().initialize(settings, onSelectNotification: (payload) async {});
  FlutterLocalNotificationsPlugin().show(
    DateTime.now().hashCode,
    'Update received in Flutter',
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'flutter_location_updates',
        'Location updated in flutter',
        'Location updates from flutter',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      ),
    ),
  );
}