import 'dart:async';
import 'dart:io';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class BeaconController extends GetxController {
  RxBool isTransmitting = false.obs;
  RxBool bluetoothEnabled = false.obs;
  RxBool authorizationStatusOk = false.obs;
  RxBool locationServiceEnabled = false.obs;

  final _uuid = Uuid();

  Future<void> initializeBeacon() async {
    try {
      if (Platform.isAndroid) {
        await Permission.bluetoothScan.request();
        await Permission.bluetoothAdvertise.request();
        await Permission.bluetoothConnect.request();
      }

      await flutterBeacon.initializeScanning;
    } catch (e) {
      print("Error initializing beacon: $e");
    }
  }

  Future<void> startBroadcasting() async {
    try {
      // Check if already broadcasting
      final isBroadcasting = await flutterBeacon.isBroadcasting();
      if (isBroadcasting) {
        await stopBroadcasting();
      }

      await Future.delayed(const Duration(milliseconds: 100));

      await flutterBeacon.startBroadcast(BeaconBroadcast(
        identifier: 'TeacherBeacon',
        proximityUUID: _uuid.v4(),
        major: 1,
        minor: 100,
        txPower: -59,
      ));

      isTransmitting.value = true;
    } catch (e) {
      print('Error broadcasting: $e');
      isTransmitting.value = false;

      if (e.toString().contains('code: 3')) {
        await _retryBroadcast();
      }
    }
  }

  Future<void> _retryBroadcast() async {
    try {
      await stopBroadcasting();
      await Future.delayed(const Duration(seconds: 1));

      await flutterBeacon.startBroadcast(BeaconBroadcast(
        identifier: 'TeacherBeacon',
        proximityUUID: _uuid.v4(),
        major: 1,
        minor: 100,
        txPower: -59,
      ));

      isTransmitting.value = true;
    } catch (retryError) {
      print('Retry failed: $retryError');
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

  void updateBluetoothState(BluetoothState state) {
    bluetoothEnabled.value = state == BluetoothState.stateOn;
  }

  void updateAuthorizationStatus(AuthorizationStatus status) {
    authorizationStatusOk.value = status == AuthorizationStatus.allowed;
  }

  void updateLocationService(bool flag) {
    locationServiceEnabled.value = flag;
  }
}
