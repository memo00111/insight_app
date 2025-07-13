import 'package:flutter/material.dart';
import 'providers/app_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Provider Test',
      home: ProviderTestWidget(),
    );
  }
}

class ProviderTestWidget extends StatefulWidget {
  @override
  _ProviderTestWidgetState createState() => _ProviderTestWidgetState();
}

class _ProviderTestWidgetState extends State<ProviderTestWidget> {
  late AppProvider appProvider;

  @override
  void initState() {
    super.initState();
    appProvider = AppProvider();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Provider Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Provider initialized successfully!'),
            ElevatedButton(
              onPressed: () {
                appProvider.setVoiceAssistantEnabled(!appProvider.isVoiceAssistantEnabled);
              },
              child: Text('Toggle Voice Assistant: ${appProvider.isVoiceAssistantEnabled}'),
            ),
            Text('Connection Status: ${appProvider.isOnline ? "Online" : "Offline"}'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    appProvider.dispose();
    super.dispose();
  }
}
