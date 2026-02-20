import 'package:flutter/material.dart';
import 'package:travid/services/global_ai_service.dart';
import 'package:travid/services/security_service.dart';
// Ensure correct path or use riverpod

class PinScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final bool isSettingPin;

  const PinScreen({
    super.key,
    required this.onAuthenticated,
    this.isSettingPin = false,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final List<String> _enteredPin = [];
  final SecurityService _securityService = SecurityService();
  final GlobalAIService _aiService = GlobalAIService();
  String _message = "Enter 4-digit PIN";
  String _confirmPin = "";
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _securityService.initialize();
    _message = widget.isSettingPin 
        ? "Set a 4-digit PIN" 
        : "Unlock with your PIN";
    setState(() {});
    
    // Announce
    _speak(_message);
    
    // Listen for voice input if needed?
    // For security, listening continuously might be risky if someone else speaks.
    // Better to have explicit "Speak PIN" button or just listen if AI is active.
  }

  Future<void> _speak(String text) async {
    await _aiService.speak(text);
  }

  void _onDigitPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin.add(digit);
      });
      _speak(digit); // Speak the digit for confirmation
      
      if (_enteredPin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
      });
      _speak("Deleted");
    }
  }

  void _handlePinComplete() async {
    final pin = _enteredPin.join();

    if (widget.isSettingPin) {
      if (_isConfirming) {
        if (pin == _confirmPin) {
          await _securityService.setPin(pin);
          _speak("PIN set successfully");
          widget.onAuthenticated();
        } else {
          _speak("PINs do not match. Try again.");
          setState(() {
            _enteredPin.clear();
            _confirmPin = "";
            _isConfirming = false;
            _message = "Set a 4-digit PIN";
          });
        }
      } else {
        _confirmPin = pin;
        _isConfirming = true;
        setState(() {
          _enteredPin.clear();
          _message = "Confirm your PIN";
        });
        _speak("Confirm your PIN");
      }
    } else {
      // Verify
      if (_securityService.verifyPin(pin)) {
        _speak("Unlocked");
        widget.onAuthenticated();
      } else {
        _speak("Incorrect PIN. Try again.");
        setState(() {
          _enteredPin.clear();
        });
        // Shake animation?
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Header / Message
            Text(
              _message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _enteredPin.length 
                        ? Colors.blueAccent 
                        : Colors.grey[700],
                  ),
                );
              }),
            ),
            
            const Spacer(),
            
            // Keypad
            _buildKeypad(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 20),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 20),
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 20),
          _buildKeypadRow(['', '0', 'del']),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) return const SizedBox(width: 80, height: 80);
        return _buildKey(key);
      }).toList(),
    );
  }

  Widget _buildKey(String key) {
    final isDel = key == 'del';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => isDel ? _onDelete() : _onDigitPress(key),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[800],
          ),
          alignment: Alignment.center,
          child: isDel 
              ? const Icon(Icons.backspace, color: Colors.white)
              : Text(
                  key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
