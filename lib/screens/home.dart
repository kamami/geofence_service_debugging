import 'package:flutter/material.dart';

import 'package:geofence_service/geofence_service.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _geofenceList = <Geofence>[
    Geofence(
      id: 'place_1',
      latitude: 35.103422,
      longitude: 129.036023,
      radius: [
        GeofenceRadius(id: 'radius_100m', length: 100),
        GeofenceRadius(id: 'radius_25m', length: 25),
        GeofenceRadius(id: 'radius_250m', length: 250),
        GeofenceRadius(id: 'radius_200m', length: 200),
      ],
    ),
    Geofence(
      id: 'place_2',
      latitude: 35.104971,
      longitude: 129.034851,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 25),
        GeofenceRadius(id: 'radius_100m', length: 100),
        GeofenceRadius(id: 'radius_200m', length: 200),
      ],
    ),
  ];

  final geofenceService = GeofenceService.instance.setup(
      interval: 5000,
      accuracy: 100,
      loiteringDelayMs: 60000,
      statusChangeDelayMs: 10000,
      useActivityRecognition: false,
      allowMockLocations: true,
      geofenceRadiusSortType: GeofenceRadiusSortType.DESC);

  void _askPermissionAlways() async {
    var status = await Permission.locationAlways.status;

    if (status.isGranted) {
      openAppSettings();
    } else {
      await Permission.locationWhenInUse.request();

      Permission.locationAlways.request();
    }
  }

  Future<void> _onGeofenceStatusChanged(
      Geofence geofence,
      GeofenceRadius geofenceRadius,
      GeofenceStatus geofenceStatus,
      Location location) async {
    print('geofence: ${geofence.toJson()}');
    print('geofenceRadius: ${geofenceRadius.toJson()}');
    print('geofenceStatus: ${geofenceStatus.toString()}');
  }

  // This function is to be called when the activity has changed.
  void _onActivityChanged(Activity prevActivity, Activity currActivity) {
    print('prevActivity: ${prevActivity.toJson()}');
    print('currActivity: ${currActivity.toJson()}');
  }

  // This function is to be called when the location has changed.
  void _onLocationChanged(Location location) {
    print('location: ${location.toJson()}');
  }

  // This function is to be called when a location services status change occurs
  // since the service was started.
  void _onLocationServicesStatusChanged(bool status) {
    print('isLocationServicesEnabled: $status');
  }

  // This function is used to handle errors that occur in the service.
  void _onError(error) {
    final errorCode = getErrorCodesFromError(error);
    if (errorCode == null) {
      print('Undefined error: $error');
      return;
    }

    print('ErrorCode: $errorCode');
  }

  @override
  void initState() {
    _askPermissionAlways();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
      geofenceService.addLocationChangeListener(_onLocationChanged);
      geofenceService.addLocationServicesStatusChangeListener(
          _onLocationServicesStatusChanged);
      geofenceService.addActivityChangeListener(_onActivityChanged);
      geofenceService.addStreamErrorListener(_onError);
      geofenceService.start(_geofenceList).catchError(_onError);
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillStartForegroundTask(
        onWillStart: () {
          print("START");
          // You can add a foreground task start condition.
          return geofenceService.isRunningService;
        },
        androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'geofence_service_notification_channel',
            channelName: 'Geofence Service Notification',
            channelDescription:
                'This notification appears when the geofence service is running in the background.',
            isSticky: false,
            channelImportance: NotificationChannelImportance.HIGH,
            priority: NotificationPriority.HIGH),
        iosNotificationOptions: IOSNotificationOptions(),
        notificationTitle: 'Aschaffenburger Geheimnisse läuft im Hintergrund',
        notificationText: 'Klicke, um in die App zurückzukehren!',
        child: Scaffold(
            body: Center(
                child: ElevatedButton(
          onPressed: () {
            print(geofenceService.isRunningService);
          },
          child: Text("Test"),
        ))));
  }
}
