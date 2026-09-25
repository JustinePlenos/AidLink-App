import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/providers/app_provider.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late final TextEditingController _controller;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<AppProvider>().apiUrl,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    setState(() => _working = true);
    final provider = context.read<AppProvider>();
    try {
      await provider.saveApiUrl(_controller.text);
      _controller.text = provider.apiUrl;
      await provider.testApiConnection();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Connection saved.')));
    } on FormatException catch (error) {
      _showError(error.message);
    } on Exception {
      _showError('Connection failed. Check the address and try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connection settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.dns_outlined, size: 56, color: Color(0xFF1E5E7B)),
          const SizedBox(height: 16),
          const Text(
            'AidLink connection',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Change this only if AidLink support gives you a new address.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            enabled: !_working,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Service address',
              hintText: 'http://192.168.1.5:5000',
              prefixIcon: Icon(Icons.link),
            ),
            onSubmitted: (_) => _saveAndTest(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _working ? null : _saveAndTest,
            icon: _working
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find),
            label: Text(_working ? 'Testing connection...' : 'Save and test'),
          ),
          const SizedBox(height: 16),
          const Text(
            'If the connection fails, check your network or contact AidLink support.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
