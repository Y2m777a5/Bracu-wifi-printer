import 'package:flutter/material.dart';

class PrintHistoryPage extends StatelessWidget {
  const PrintHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Print History')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text('Assignment_02.pdf'),
              subtitle: Text('Sent to 10.10.0.50'),
              trailing: Text('Queued', style: TextStyle(color: Colors.green)),
            ),
          ),
        ],
      ),
    );
  }
}
