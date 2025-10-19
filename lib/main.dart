import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:percent_indicator/percent_indicator.dart';

void main() {
  runApp(const TimerApp());
}

class TimerApp extends StatelessWidget {
  const TimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const TimerScreen(),
      theme: ThemeData(
        primaryColor: const Color(0xFF6B4E99),
        scaffoldBackgroundColor: const Color(0xFF4A2B6B), // Darker background
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF9B59B6),
        ),
      ),
    );
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _timeInSeconds = 0;
  int _initialTime = 0;
  bool _isRunning = false;
  Timer? _timer;
  Timer? _blinkTimer;
  bool _isBlinking = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmPlaying = false;

  // Toggles the timer on and off
  void _toggleTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      if (_timeInSeconds > 0) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    // Set the initial time to calculate the circular progress
    if (_initialTime == 0 || !_isRunning) {
      _initialTime = _timeInSeconds;
    }

    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeInSeconds > 0) {
          _timeInSeconds--;
          // Start blinking when 20 seconds are left
          if (_timeInSeconds <= 20) {
            _startBlinking();
          }
        } else {
          _stopTimer();
          _playAlarm();
        }
      });
    });
  }

  void _stopTimer() {
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _timer?.cancel();
      _stopBlinking(); // Stop blinking when timer is paused
      if (_isAlarmPlaying) {
        _stopAlarm();
      }
    });
  }

  void _resetTimer() {
    _stopAlarm();
    if (!mounted) return;
    setState(() {
      _timeInSeconds = 0;
      _initialTime = 0;
      _isRunning = false;
      _timer?.cancel();
      _stopBlinking(); // Stop blinking on reset
    });
  }

  void _addTime(int seconds) {
    if (!_isRunning) {
      if (!mounted) return;
      setState(() {
        _timeInSeconds += seconds;
        _initialTime = _timeInSeconds;
      });
    }
  }

  // --- Blinking Logic ---
  void _startBlinking() {
    if (_blinkTimer?.isActive ?? false) return; // Avoid multiple timers
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      setState(() {
        _isBlinking = !_isBlinking;
      });
    });
  }

  void _stopBlinking() {
    _blinkTimer?.cancel();
    if (!mounted) return;
    if (_isBlinking) { // Check to avoid unnecessary setState calls
      setState(() {
        _isBlinking = false;
      });
    }
  }

  // --- Audio Logic ---
  void _playAlarm() async {
    if (!_isAlarmPlaying) {
      _isAlarmPlaying = true;
      // Make sure you have 'alarm.mp3' in 'assets/sounds/'
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
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
    _timer?.cancel();
    _blinkTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- UI Helper Methods ---
  String _formatTime() {
    final hours = (_timeInSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_timeInSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timeInSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Color _getBackgroundColor() {
    if (_isRunning && _timeInSeconds <= 60) {
      // Blinking red for the last 20 seconds
      if (_timeInSeconds <= 20) {
        return _isBlinking ? Colors.red.shade900 : Colors.red;
      }
      // Solid red when 1 minute is left
      return Colors.red;
    }
    // Default background color
    return Theme.of(context).scaffoldBackgroundColor;
  }

  // Quick-add time button widget
  Widget _timeButton(String text, int seconds) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B4E99),
            foregroundColor: Colors.white,
            shape: const StadiumBorder()),
        onPressed: () => _addTime(seconds),
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate percentage for the circular indicator
    double percent = 1.0;
    if (_initialTime > 0) {
      percent = _timeInSeconds / _initialTime;
    }

    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double deviceWidth = constraints.maxWidth;
            final double deviceHeight = constraints.maxHeight;

            // Determine the main dimension to scale against (the smaller of the two)
            final double smallerDimension = deviceWidth < deviceHeight ? deviceWidth : deviceHeight;

            // Define sizes relative to the screen size
            final double indicatorRadius = smallerDimension / 4.0;
            final double indicatorLineWidth = smallerDimension / 30.0;
            final double centerFontSize = indicatorRadius / 2.5;
            final double controlButtonRadius = smallerDimension / 30.0;
            final double controlIconSize = controlButtonRadius * 1;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // --- Circular Progress Timer ---
                CircularPercentIndicator(
                  radius: indicatorRadius,
                  lineWidth: indicatorLineWidth,
                  percent: percent,
                  center: Text(
                    _formatTime(),
                    style: TextStyle(
                        fontSize: centerFontSize,
                        color: Colors.white,
                        fontWeight: FontWeight.w300),
                  ),
                  progressColor: Colors.blueAccent, // Changed color to blue
                  backgroundColor: const Color(0xFF6B4E99),
                  circularStrokeCap: CircularStrokeCap.round,
                  animateFromLastPercent: true,
                  animation: true,
                ),
                const Spacer(),
                // --- Quick Add Time Buttons ---
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.0, // Horizontal space between buttons
                  runSpacing: 4.0, // Vertical space if they wrap
                  children: [
                    _timeButton('30s', 30),
                    _timeButton('5m', 5 * 60),
                    _timeButton('15m', 15 * 60),
                    _timeButton('1h', 60 * 60), // Added 1 hour button
                  ],
                ),
                SizedBox(height: deviceHeight * 0.02),
                // --- Main Control Buttons ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Play/Pause Button
                    GestureDetector(
                      onTap: _toggleTimer,
                      child: CircleAvatar(
                        radius: controlButtonRadius,
                        backgroundColor: Colors.white,
                        child: Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow,
                          size: controlIconSize,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                    ),
                    SizedBox(width: deviceWidth * 0.05),
                    // Reset Button
                    GestureDetector(
                      onTap: _resetTimer,
                      child: CircleAvatar(
                        radius: controlButtonRadius,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.stop,
                          size: controlIconSize,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: deviceHeight * 0.07), // Bottom padding
              ],
            );
          },
        ),
      ),
    );
  }
}

