import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:teacher_app/src/beacon/beacon_controller.dart';
import 'package:get/get.dart';

class BeaconView extends StatefulWidget {
  const BeaconView({super.key});

  static const routeName = '/beacon';

  @override
  State<BeaconView> createState() => _BeaconViewState();
}

class _BeaconViewState extends State<BeaconView> with WidgetsBindingObserver {
  final BeaconController controller = BeaconController();
  StreamSubscription<RangingResult>? _streamRanging;
  StreamSubscription<MonitoringResult>? _streamMonitoring;
  final regions = <Region>[];
  RxBool isTransmitting = false.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initBeacon();

    ever(isTransmitting, (bool transmitting) {
      if (transmitting) {
        startBroadcasting();
      } else {
        stopBroadcasting();
      }
    });
  }

  Future<void> initBeacon() async {
    try {
      await flutterBeacon.initializeAndCheckScanning;

      if (Platform.isIOS) {
        regions.add(Region(
          identifier: 'iBeacon',
          proximityUUID: '702F0AFC-B84B-4F2E-BC8A-B0808FC98C8C',
        ));
      } else {
        regions.add(Region(
          identifier: 'iBeacon',
          proximityUUID: '702F0AFC-B84B-4F2E-BC8A-B0808FC98C8C',
          major: 1,
          minor: 100,
        ));
      }

      flutterBeacon
          .bluetoothStateChanged()
          .listen((BluetoothState state) async {
        controller.updateBluetoothState(state);
        await checkAllRequirements();
      });

      await checkAllRequirements();
    } on PlatformException catch (e) {
      print("Error initializing: ${e.code} - ${e.message}");
    }
  }

  Future<void> checkAllRequirements() async {
    final bluetoothState = await flutterBeacon.bluetoothState;
    controller.updateBluetoothState(bluetoothState);

    final authorizationStatus = await flutterBeacon.authorizationStatus;
    controller.updateAuthorizationStatus(authorizationStatus);

    final locationServiceEnabled =
        await flutterBeacon.checkLocationServicesIfEnabled;
    controller.updateLocationService(locationServiceEnabled);

    if (controller.bluetoothEnabled &&
        controller.authorizationStatusOk &&
        controller.locationServiceEnabled) {
      print('Requirements met - ready to scan');
      controller.startScanning();
    } else {
      print('Requirements not met');
      controller.pauseScanning();
      await stopScanning();
    }
  }

  Future<void> startBroadcasting() async {
    try {
      await flutterBeacon.startBroadcast(BeaconBroadcast(
        identifier: 'TeacherBeacon',
        proximityUUID: '702F0AFC-B84B-4F2E-BC8A-B0808FC98C8C',
        major: 1,
        minor: 100,
        txPower: -59,
      ));
      isTransmitting.value = true;
    } catch (e) {
      print('Error broadcasting: $e');
      isTransmitting.value = false;
    }
  }

  Future<void> stopBroadcasting() async {
    try {
      await flutterBeacon.stopBroadcast();
      isTransmitting.value = false;
    } catch (e) {
      print('Error stopping broadcast: $e');
    }
  }

  Future<void> pauseScanning() async {
    await _streamRanging?.cancel();
    await _streamMonitoring?.cancel();
    setState(() {
      isTransmitting = false.obs;
      controller.beacons.clear();
    });
  }

  Future<void> stopScanning() async {
    await pauseScanning();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (isTransmitting.isTrue) {
        await checkAllRequirements();
      }
    } else if (state == AppLifecycleState.paused) {
      await stopScanning();
    }
  }

  @override
  void dispose() {
    stopScanning();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chamadas'),
      ),
      body: Obx(
        () => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Beacons Found: ${controller.beacons.length}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: controller.beacons.length,
                itemBuilder: (context, index) {
                  final beacon = controller.beacons[index];
                  return ListTile(
                    title: Text('UUID: ${beacon.proximityUUID}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Major: ${beacon.major}, Minor: ${beacon.minor}'),
                        Text(
                            'RSSI: ${beacon.rssi}, Distance: ${beacon.accuracy.toStringAsFixed(2)}m'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isTransmitting.isTrue ? stopBroadcasting : startBroadcasting,
        child: Icon(isTransmitting.isTrue ? Icons.stop : Icons.play_arrow),
      ),
    );
  }
}
