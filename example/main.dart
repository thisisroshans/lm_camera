import 'package:flutter/material.dart';
import 'package:lm_camera/lm_camera.dart';

// Minimal example app demonstrating how to call the service.
// Note: When running on device ensure camera & location permissions are allowed.
void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  String? _status;

  Future<void> _capture() async {
    setState(() => _status = 'Capturing...');
    try {
      final res = await capture();
      setState(() => _status = 'Saved: ${res.imagePath}');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('lm_camera example')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(onPressed: _capture, child: const Text('Capture')),
            const SizedBox(height: 12),
            if (_status != null) Text(_status!),
          ],
        ),
      ),
    );
  }
}
