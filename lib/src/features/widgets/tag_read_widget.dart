import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/provider/rfid_provider.dart';

class TagReadWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RFIDProvider>(
      builder: (context, rfidProvider, child) {
        return Column(
          children: [
            Text('Last Tag Read: ${rfidProvider.lastTagRead ?? "None"}'),
            ElevatedButton(
              onPressed: () => rfidProvider.startReading(),
              child: Text('Start Reading'),
            ),
          ],
        );
      },
    );
  }
}