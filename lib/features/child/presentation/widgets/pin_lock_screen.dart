import 'package:flutter/material.dart';
import 'dart:async';

class PinLockScreen extends StatefulWidget {
  final Function(String) onPinVerified;
  final String requiredPin;

  const PinLockScreen({Key? key, required this.onPinVerified, this.requiredPin = '1234'}) : super(key: key);

  @override
  _PinLockScreenState createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  int _attempts = 0;
  DateTime? _lockoutUntil;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  bool get _isLockedOut {
    if (_lockoutUntil == null) return false;
    return DateTime.now().isBefore(_lockoutUntil!);
  }

  String get _lockoutTimeRemaining {
    if (_lockoutUntil == null) return "0";
    final diff = _lockoutUntil!.difference(DateTime.now());
    return "${diff.inSeconds}";
  }

  void _onNumberPressed(String number) {
    if (_isLockedOut) return;

    setState(() {
      if (_pin.length < 4) {
        _pin += number;
        if (_pin.length == 4) {
          if (_pin == widget.requiredPin) {
            _attempts = 0;
            widget.onPinVerified(_pin);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => _pin = '');
            });
          } else {
            _attempts++;
            if (_attempts >= 3) {
              _lockoutUntil = DateTime.now().add(const Duration(seconds: 60));
              _startCooldownTimer();
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_attempts >= 3 
                  ? 'Too many attempts. Locked for 60s.' 
                  : 'Incorrect PIN. Attempt $_attempts of 3.'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.redAccent,
              ),
            );
            
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => _pin = '');
            });
          }
        }
      }
    });
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (!_isLockedOut) {
          timer.cancel();
          _attempts = 0;
        }
      });
    });
  }

  void _onDeletePressed() {
    if (_isLockedOut) return;
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Parent PIN'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLockedOut 
              ? Column(
                  children: [
                    const Icon(Icons.timer_off_outlined, color: Colors.red, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      'Locked out for security\nTry again in ${_lockoutTimeRemaining}s',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              : const Text('Parent permission required', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length ? Colors.blue : Colors.grey[300],
                  ),
                );
              }),
            ),
            const SizedBox(height: 50),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.5),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) return const SizedBox.shrink(); // Empty space
                  if (index == 11) {
                    return TextButton(
                      onPressed: _onDeletePressed,
                      child: const Icon(Icons.backspace_outlined, size: 30),
                    );
                  }
                  final number = (index == 10) ? '0' : (index + 1).toString();
                  return TextButton(
                    onPressed: () => _onNumberPressed(number),
                    child: Text(number, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
