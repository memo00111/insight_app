import 'package:flutter/material.dart';
import '../services/insight_api_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String text;
  final InsightApiService apiService;

  const AudioPlayerWidget({
    super.key,
    required this.text,
    required this.apiService,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.volume_up,
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'تشغيل صوتي',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  onPressed: _playAudio,
                  icon: Icon(
                    _isPlaying ? Icons.stop : Icons.play_arrow,
                    color: Colors.blue[600],
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _playAudio() async {
    if (_isPlaying) {
      setState(() => _isPlaying = false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.apiService.formTextToSpeech(widget.text);
      
      setState(() {
        _isPlaying = true;
        _isLoading = false;
      });

      // Simulate audio playback duration
      await Future.delayed(Duration(seconds: widget.text.length ~/ 10));
      
      setState(() => _isPlaying = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تشغيل الصوت: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
