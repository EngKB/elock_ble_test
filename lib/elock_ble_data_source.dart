import 'dart:typed_data';

import 'package:elock_ble/constants.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

final iv = IV.fromLength(16);

class ElockBleDataSource {
  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();
  getElockBleTokenCommand(
    String deviceId,
    List<int> key,
  ) {
    List<int> buffer = [
      0x06,
      0x01,
      0x01,
      0x01,
    ];
    return _sendElockBleCommand(
      deviceId,
      buffer,
      key,
    );
  }

  void eLockBleTimeSynchronization(
    String deviceId,
    List<int> token,
    List<int> key,
  ) {
    int unixTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    List<int> buffer = [0x06, 0x03, 0x04] +
        Uint8List.fromList([
          unixTime >> 24,
          unixTime >> 16,
          unixTime >> 8,
          unixTime,
        ]) +
        token;
    _sendElockBleCommand(
      deviceId,
      buffer,
      key,
    );
  }

  void checkElockBleStatusCommand(
    String deviceId,
    List<int> token,
    List<int> key,
  ) {
    List<int> buffer = [
          0x05,
          0x0E,
          0x01,
          0x01,
        ] +
        token;
    _sendElockBleCommand(
      deviceId,
      buffer,
      key,
    );
  }

  void unlockElockBleCommand(
    String deviceId,
    List<int> token,
    List<int> key,
    String password,
  ) {
    List<int> buffer = [
          0x05,
          0x01,
          0x06,
        ] +
        _getElockPassword(password) +
        token;
    _sendElockBleCommand(
      deviceId,
      buffer,
      key,
    );
  }

  List<int> _encryptElockBleCommand(List<int> buffer, List<int> key) {
    final encrypter = Encrypter(
      AES(
        Key(Uint8List.fromList(key)),
        mode: AESMode.ecb,
      ),
    );
    return encrypter.encryptBytes(buffer, iv: iv).bytes;
  }

  List<int> decryptElockBleResponse(List<int> buffer, List<int> key) {
    final encrypter = Encrypter(
      AES(
        Key(Uint8List.fromList(key)),
        mode: AESMode.ecb,
      ),
    );
    return encrypter.decryptBytes(
      Encrypted(
        Uint8List.fromList(buffer),
      ),
      iv: iv,
    );
  }

  List<int> _getElockPassword(String password) {
    List<int> pass = [];
    for (int i = 0; i < password.length; i++) {
      pass.add(password.codeUnitAt(i));
    }
    return pass;
  }

  void _sendElockBleCommand(
    final String deviceId,
    List<int> buffer,
    List<int> key,
  ) async {
    buffer = _encryptElockBleCommand(buffer, key);
    buffer = buffer + List.generate(16 - buffer.length, (index) => 0);
    print('length ' + buffer.length.toString());
    await flutterReactiveBle.writeCharacteristicWithoutResponse(
      QualifiedCharacteristic(
        characteristicId: elockBleWriteUuid,
        serviceId: elockBleServiceUuid,
        deviceId: deviceId,
      ),
      value: buffer,
    );
  }
}
