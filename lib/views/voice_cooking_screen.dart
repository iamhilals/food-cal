import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/theme/app_theme.dart';

class VoiceCookingScreen extends StatefulWidget {
  final String recipeName;
  final List<String> steps;

  const VoiceCookingScreen({
    super.key,
    required this.recipeName,
    required this.steps,
  });

  @override
  State<VoiceCookingScreen> createState() => _VoiceCookingScreenState();
}

class _VoiceCookingScreenState extends State<VoiceCookingScreen> {
  late FlutterTts _tts;
  late stt.SpeechToText _speech;
  
  int _currentStepIndex = 0;
  bool _isSpeechInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastRecognizedWords = '';

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
  }

  void _initTts() {
    _tts = FlutterTts();
    _tts.setLanguage('tr-TR');
    _tts.setSpeechRate(0.55);
    _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
      // Stop listening while speaking to avoid feedback loops
      _stopListening();
    });

    _tts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
      // Resume listening once speech finishes
      _startListening();
    });

    _tts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
      debugPrint('TTS Error: $msg');
      _startListening();
    });

    // Start speaking the first step after a short delay to let the screen open
    Future.delayed(const Duration(milliseconds: 600), () {
      _speakCurrentStep();
    });
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (errorNotification) {
          debugPrint('STT Error: $errorNotification');
          setState(() {
            _isListening = false;
          });
        },
      );
      if (mounted) {
        setState(() {
          _isSpeechInitialized = available;
        });
      }
    } catch (e) {
      debugPrint('STT Init Exception: $e');
    }
  }

  Future<void> _speakCurrentStep() async {
    if (_currentStepIndex < 0 || _currentStepIndex >= widget.steps.length) return;
    await _tts.stop();
    final text = widget.steps[_currentStepIndex];
    // Speak step counter and step text
    await _tts.speak('Adım ${Uri.encodeComponent((_currentStepIndex + 1).toString())}. $text');
  }

  Future<void> _startListening() async {
    if (!_isSpeechInitialized || _isSpeaking) return;
    
    setState(() {
      _isListening = true;
      _lastRecognizedWords = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _lastRecognizedWords = result.recognizedWords;
        });
        if (result.finalResult) {
          _processVoiceCommand(result.recognizedWords);
        }
      },
      localeId: 'tr_TR',
      pauseFor: const Duration(seconds: 2),
    );
  }

  Future<void> _stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  void _processVoiceCommand(String rawText) {
    final text = rawText.toLowerCase().trim();
    debugPrint('Voice command received: $text');

    if (text.contains('sonraki') || text.contains('ileri') || text.contains('geç')) {
      _nextStep();
    } else if (text.contains('önceki') || text.contains('geri')) {
      _prevStep();
    } else if (text.contains('tekrar') || text.contains('oku') || text.contains('yeniden')) {
      _speakCurrentStep();
    } else if (text.contains('kapat') || text.contains('çık') || text.contains('bitir')) {
      Navigator.pop(context);
    } else {
      // If command not recognized, restart listening
      _startListening();
    }
  }

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _speakCurrentStep();
    } else {
      _tts.speak('Tarif tamamlandı. Afiyet olsun!');
    }
  }

  void _prevStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      _speakCurrentStep();
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepText = widget.steps[_currentStepIndex];

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.recipeName,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Step Counter
              Text(
                'ADIM ${_currentStepIndex + 1} / ${widget.steps.length}',
                style: const TextStyle(
                  color: AppTheme.primaryTeal,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),

              // Large typography step content card for kitchen readability
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderSlate, width: 1.5),
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Text(
                        stepText,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Voice feedback helper bar
              if (_isListening || _lastRecognizedWords.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mic_rounded, color: AppTheme.primaryTeal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _lastRecognizedWords.isEmpty ? 'Dinleniyor... (ileri, geri, tekrar)' : '"$_lastRecognizedWords"',
                        style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

              // Tappable backup controllers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Back button
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.darkCard,
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 28),
                    onPressed: _currentStepIndex > 0 ? _prevStep : null,
                  ),

                  // Speak / Repeat button
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(24),
                    ),
                    icon: Icon(
                      _isSpeaking ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                      size: 36,
                    ),
                    onPressed: _speakCurrentStep,
                  ),

                  // Forward / Next button
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.darkCard,
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 28),
                    onPressed: _currentStepIndex < widget.steps.length - 1 ? _nextStep : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
