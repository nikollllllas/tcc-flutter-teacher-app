import 'dart:async';
import 'dart:io';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class BeaconController extends GetxController {
  RxBool isTransmitting = false.obs;
  RxBool bluetoothEnabled = false.obs;
  RxBool authorizationStatusOk = false.obs;
  RxBool locationServiceEnabled = false.obs;

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Request location permissions
      final locationWhenInUse = await Permission.locationWhenInUse.request();
      if (!locationWhenInUse.isGranted) {
        await AppSettings.openAppSettings(type: AppSettingsType.location);
        return false;
      }

      // Request Bluetooth permissions
      await Permission.bluetoothScan.request();
      await Permission.bluetoothAdvertise.request();
      await Permission.bluetoothConnect.request();
    }
    return true;
  }

  Future<void> initializeBeacon() async {
    try {
      if (!await _requestPermissions()) {
        print("Required permissions not granted");
        return;
      }

      await flutterBeacon.initializeScanning;

      final bluetoothState = await flutterBeacon.bluetoothState;
      updateBluetoothState(bluetoothState);

      final authorizationStatus = await flutterBeacon.authorizationStatus;
      updateAuthorizationStatus(authorizationStatus);

      final locationEnabled =
          await flutterBeacon.checkLocationServicesIfEnabled;
      updateLocationService(locationEnabled);
    } catch (e) {
      print("Error initializing beacon: $e");
    }
  }

  Future<void> startBroadcasting() async {
    try {
      final isBroadcasting = await flutterBeacon.isBroadcasting();
      if (isBroadcasting) {
        await stopBroadcasting();
      }

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
      if (e.toString().contains('code: 3')) {
        await _retryBroadcast();
      }
    }
  }

  Future<void> _retryBroadcast() async {
    try {
      await stopBroadcasting();
      await Future.delayed(const Duration(seconds: 1));
      await startBroadcasting();
    } catch (e) {
      print('Retry failed: $e');
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

  @override
  void onClose() {
    stopBroadcasting();
    super.onClose();
  }
}
