import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:get/get.dart';
import 'package:teacher_app/src/beacon/beacon_controller.dart';

class BeaconView extends StatefulWidget {
  const BeaconView({super.key});

  static const routeName = '/beacon';

  @override
  State<BeaconView> createState() => _BeaconViewState();
}

class _BeaconViewState extends State<BeaconView> with WidgetsBindingObserver {
  final controller = Get.put(BeaconController());
  Color backgroundColor = const Color(0xFF182026);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAndCheckPermissions();
  }

  Future<void> _initializeAndCheckPermissions() async {
    try {
      await controller.initializeBeacon();
      await flutterBeacon.initializeAndCheckScanning;
      await checkAllRequirements();
    } on PlatformException catch (e) {
      print("Error initializing: ${e.code} - ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization error: ${e.message}')),
        );
      }
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

    await flutterBeacon.requestAuthorization;

    if (controller.bluetoothEnabled.value &&
        controller.authorizationStatusOk.value &&
        controller.locationServiceEnabled.value) {
      print('Requirements met');
    } else {
      print('Requirements not met');
      controller.stopBroadcasting();
    }
  }

  @override
  void dispose() {
    controller.stopBroadcasting();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Chamadas'),
        backgroundColor: backgroundColor,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 24),
      ),
      body: Obx(
        () => Column(
          children: [
            if (!controller.bluetoothEnabled.value ||
                !controller.authorizationStatusOk.value ||
                !controller.locationServiceEnabled.value)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Aguardando permissões necessárias...',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            Center(
              child: ElevatedButton(
                style: ButtonStyle(
                  minimumSize:
                      WidgetStateProperty.all<Size>(const Size(300, 600)),
                  backgroundColor:
                      WidgetStateProperty.all<Color>(Colors.blue.shade300),
                  shape: WidgetStateProperty.all<OutlinedBorder>(
                    const CircleBorder(),
                  ),
                ),
                onPressed: () async {
                  if (controller.isTransmitting.value) {
                    await controller.stopBroadcasting();
                  } else {
                    await controller.startBroadcasting();
                  }
                },
                child: Icon(
                  controller.isTransmitting.value
                      ? Icons.stop
                      : Icons.play_arrow,
                  size: 64,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 16),
              child: Text(
                controller.isTransmitting.value
                    ? 'Transmitindo...'
                    : 'Toque pare iniciar!',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }
}
