import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rfid_writer/core/services/rfid_writer_service.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class RFIDMainScreen extends StatefulWidget {
  @override
  _RFIDMainScreenState createState() => _RFIDMainScreenState();
}

class _RFIDMainScreenState extends State<RFIDMainScreen> {
  final RFIDWriterService _rfidService = RFIDWriterService();
  String _status = 'Disconnected';
  String _readData = '';
  TextEditingController _writeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('RFID Writer')),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: $_status'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _connect,
                child: Text('Connect'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _read,
                child: Text('Read'),
              ),
              SizedBox(height: 10),
              Text('Read Data: $_readData'),
              SizedBox(height: 20),
              TextField(
                controller: _writeController,
                decoration: InputDecoration(labelText: 'Data to Write'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _write,
                child: Text('Write'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _disconnect,
                child: Text('Disconnect'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resetConnection,
                child: Text('Reset Connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connect() async {
    setState(() => _status = 'Connecting...');
    try {
      await Future.delayed(Duration(seconds: 2)); // Add a delay
      await _rfidService.connect();
      setState(() => _status = 'Connected');
    } on PlatformException catch (e) {
      developer.log('RFID connection error', error: e, name: 'RFIDMainScreen');
      setState(
          () => _status = 'Connection failed: ${e.message}. Code: ${e.code}');
    } catch (e) {
      developer.log('Unexpected error during RFID connection',
          error: e, name: 'RFIDMainScreen');
      setState(() => _status = 'Connection failed: $e');
    }
  }

  Future<void> _read() async {
    try {
      final data = await _rfidService.readData();
      setState(() => _readData = data);
    } catch (e) {
      setState(() => _readData = 'Read failed: $e');
    }
  }

  Future<void> _write() async {
    setState(() => _status = 'Writing...');
    try {
      final dataToWrite = _writeController.text;
      if (dataToWrite.isEmpty) {
        throw Exception('No data to write');
      }
      developer.log('Starting write operation with data: $dataToWrite',
          name: 'RFIDMainScreen');

      // Send exactly what's in the text field
      await _rfidService.writeData(dataToWrite);

      developer.log('Write operation completed', name: 'RFIDMainScreen');
      setState(() => _status = 'Write successful');
    } catch (e) {
      developer.log('Error during RFID write',
          error: e, name: 'RFIDMainScreen');
      setState(() => _status = 'Write failed: ${e.toString()}');
    } finally {
      developer.log('Write operation finished', name: 'RFIDMainScreen');
    }
  }

  Future<void> _resetConnection() async {
    _rfidService.disconnect();
    setState(() => _status = 'Disconnected');
    await Future.delayed(Duration(seconds: 1)); // Give it a moment
    await _connect();
  }

  void _disconnect() {
    _rfidService.disconnect();
    setState(() => _status = 'Disconnected');
  }

  @override
  void dispose() {
    _rfidService.disconnect();
    _writeController.dispose();
    super.dispose();
  }
}
