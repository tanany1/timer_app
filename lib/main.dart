import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

void main() {
  runApp(TimerApp());
}

class TimerApp extends StatelessWidget {
  const TimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TimerScreen(),
      theme: ThemeData(
        primaryColor: Color(0xFF6B4E99), // Dark purple from image
        hintColor: Color(0xFF9B59B6), // Lighter purple
        scaffoldBackgroundColor: Color(0xFF8E55A6), // Mid purple
      ),
    );
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _timeInSeconds = 0;
  bool _isRunning = false;
  late Timer _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmPlaying = false;
  bool _showControls = true;

  void _startTimer() {
    if (!_isRunning) {
      _isRunning = true;
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_timeInSeconds > 0) {
            _timeInSeconds--;
          } else {
            _stopTimer();
            _playAlarm();
          }
        });
      });
    }
  }

  void _stopTimer() {
    _isRunning = false;
    _timer.cancel();
    if (_isAlarmPlaying) {
      _stopAlarm();
    }
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _timeInSeconds = 0;
    });
  }

  void _addTime(int seconds) {
    if (!_isRunning) {
      setState(() {
        _timeInSeconds += seconds;
      });
    }
  }

  void _playAlarm() async {
    if (!_isAlarmPlaying) {
      _isAlarmPlaying = true;
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3')); // Add alarm.mp3 to assets
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
    }
  }

  void _stopAlarm() async {
    if (_isAlarmPlaying) {
      _isAlarmPlaying = false;
      await _audioPlayer.stop();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Container(
              padding: EdgeInsets.all(16.0),
              constraints: BoxConstraints(maxWidth: 1000),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(_timeInSeconds ~/ 3600).toString().padLeft(2, '0')}:' +
                        '${((_timeInSeconds % 3600) ~/ 60).toString().padLeft(2, '0')}:' +
                        '${(_timeInSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 260, color: Colors.white),
                  ),
                  if (_showControls) SizedBox(height: 80),
                  if (_showControls)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => _addTime(30),
                          child: Text('30 sec'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => _addTime(5 * 60),
                          child: Text('5 min'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => _addTime(15 * 60),
                          child: Text('15 min'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => _addTime(30 * 60),
                          child: Text('30 min'),
                        ),
                      ],
                    ),
                  if (_showControls) SizedBox(height: 20),
                  if (_showControls)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _startTimer,
                          child: Text('Start'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _stopTimer,
                          child: Text('Stop'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _resetTimer,
                          child: Text('Reset'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.visibility, color: Colors.white),
              onPressed: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}