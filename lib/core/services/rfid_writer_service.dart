import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class RFIDWriterService {
  static const String DEVICE_NAME = 'RMG_WRITER_2';
  BluetoothConnection? _connection;

  Future<void> connect() async {
    final BluetoothDevice? device = await _findDevice();
    if (device == null) {
      throw Exception('RFID Writer not found');
    }

    _connection = await BluetoothConnection.toAddress(device.address);
    print('Connected to RFID Writer');
  }

  Future<BluetoothDevice?> _findDevice() async {
    List<BluetoothDevice> devices =
        await FlutterBluetoothSerial.instance.getBondedDevices();
    return devices.firstWhere((device) => device.name == DEVICE_NAME,
        orElse: () => BluetoothDevice(address: ''));
  }

  Future<String> readData() async {
    if (_connection == null) {
      throw Exception('Not connected to RFID Writer');
    }

    // Send read command
    _connection!.output.add(Uint8List.fromList(utf8.encode('READ\r\n')));

    // Wait for the write operation to complete
    await _connection!.output.allSent;

    // Wait for and return the response
    return await _connection?.input?.map((data) => utf8.decode(data)).first ??
        '';
  }

  Future<void> writeData(String data) async {
    if (_connection == null) {
      throw Exception('Not connected to RFID Writer');
    }

    try {
      // Send the exact data without any additional characters
      _connection!.output.add(Uint8List.fromList(utf8.encode(data)));
      await _connection!.output.allSent;

      // Wait for acknowledgement if your device sends one
      // Use a timeout to prevent hanging
      final response = await _connection!.input
          ?.map((data) => utf8.decode(data))
          .firstWhere((element) => element.isNotEmpty)
          .timeout(Duration(seconds: 5), onTimeout: () => '');

      if (response?.trim().toLowerCase() != 'ok') {
        print('Unexpected response: $response');
      }
    } catch (e) {
      print('Error writing data: $e');
      throw Exception('Failed to write data: $e');
    }
  }

  void disconnect() {
    _connection?.close();
    _connection = null;
    print('Disconnected from RFID Writer');
  }
}
