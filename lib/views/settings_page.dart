import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('Default Portal URL'),
            subtitle: const Text('http://10.10.0.1/eportal/InterFace.do'),
            trailing: const Icon(Icons.edit),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: const Text('Default Printer IP'),
            subtitle: const Text('10.10.0.50'),
            trailing: const Icon(Icons.edit),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: const Text('LPD Port Number'),
            subtitle: const Text('515'),
            trailing: const Icon(Icons.lock),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
