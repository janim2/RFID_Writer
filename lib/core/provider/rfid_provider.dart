import 'package:flutter/material.dart';
import '../services/rfid_writer_service.dart';

class RFIDProvider extends ChangeNotifier {
  final RFIDWriterService _rfidService = RFIDWriterService();
  String? lastTagRead;
  bool isConnected = false;

  Future<void> startReading() async {
    try {
      await _rfidService.connectToReader();
      isConnected = true;

      _rfidService.dataStream?.listen((tagData) {
        lastTagRead = tagData;
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      print('Error starting RFID reader: $e');
      isConnected = false;
      notifyListeners();
    }
  }

  void dispose() {
    _rfidService.disconnect();
    super.dispose();
  }
}
