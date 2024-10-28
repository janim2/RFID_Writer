import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert' as convert;

class RFIDWriterService {
  static const String WRITER_DEVICE_NAME = 'RMG_WRITER_2';
  static const String READER_DEVICE_NAME = 'RMG_AUTHENTICATOR_2';
  BluetoothConnection? _connection;
  StreamController<String>? _dataStreamController;
  StreamSubscription? _dataSubscription;
  String _buffer = '';

  // Add this getter near the top of the class with other properties
  Stream<String>? get dataStream => _dataStreamController?.stream;

  Future<void> connect() async {
    final BluetoothDevice? device = await _findDevice(WRITER_DEVICE_NAME);
    if (device == null) {
      throw Exception('RFID Writer not found');
    }

    _connection = await BluetoothConnection.toAddress(device.address);
    print('Connected to RFID Writer');
  }

  Future<BluetoothDevice?> _findDevice(String deviceName) async {
    List<BluetoothDevice> devices =
        await FlutterBluetoothSerial.instance.getBondedDevices();
    return devices.firstWhere((device) => device.name == deviceName,
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
    // _connection?.close();
    // _connection = null;
    // print('Disconnected from RFID Writer');

     _dataSubscription?.cancel();
    _dataStreamController?.close();
    _connection?.close();
    _connection = null;
    print('Disconnected from RFID devices');
  }

  Future<void> connectToReader() async {
    final BluetoothDevice? device = await _findDevice(READER_DEVICE_NAME);
    if (device == null) {
      throw Exception('RFID Reader not found');
    }

    _connection = await BluetoothConnection.toAddress(device.address);
    print('Connected to RFID Reader');

    // Initialize stream controller and start listening
    _dataStreamController = StreamController<String>.broadcast();
    _startListening();
  }

  void _startListening() {
    if (_connection == null) return;

    _dataSubscription =
        _connection!.input!.map((data) => utf8.decode(data)).listen((data) {
      if (data.isNotEmpty) {
        _buffer += data.trim();

        // Check if we have what looks like our data
        if (_buffer.contains('staff_id') && _buffer.contains('first_name')) {
          try {
            // Regex patterns for exact matches
            RegExp staffIdPattern = RegExp(r'"staff_id":"([^"]+)"');
            RegExp firstNamePattern = RegExp(r'"first_name":"([^"]+)"');

            var staffIdMatch = staffIdPattern.firstMatch(_buffer);
            var firstNameMatch = firstNamePattern.firstMatch(_buffer);

            if (staffIdMatch != null && firstNameMatch != null) {
              String staffId = staffIdMatch.group(1) ?? '';
              String firstName = firstNameMatch.group(1) ?? '';

              Map<String, String> result = {
                'staff_id': staffId,
                'first_name': firstName
              };

              print('Extracted data: ${result['staff_id']}'); // Debug log
              _dataStreamController?.add(jsonEncode(result));

              // Clear buffer after successful extraction
              _buffer = '';
            }
          } catch (e) {
            print('Error extracting data: $e');
          }
        }
      }
    }, onError: (error) {
      print('Error reading from device: $error');
    });
  }

  Future<void> listenForTags() async {
    final rfidService = RFIDWriterService();

    await rfidService.connect();

    _dataStreamController?.stream.listen((tagData) {
      // print('RFID Tag detected: Nothing');
      // Handle the tag data here
    });
  }

  // void disconnectReader() {
  //   _dataSubscription?.cancel();
  //   _dataStreamController?.close();
  //   _connection?.close();
  //   _connection = null;
  //   print('Disconnected from RFID Reader');
  // }

  // @override
  // void dispose() {
  //   rfidService.disconnect();
  //   super.dispose();
  // }
}
