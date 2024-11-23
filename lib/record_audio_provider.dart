import 'dart:developer';

import 'package:audio_like_whatsapp/html.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recordAudioProvider = ChangeNotifierProvider<RecordAudioNotifier>((ref) {
  return RecordAudioNotifier();
});

class RecordAudioNotifier extends ChangeNotifier {
  bool isRecording = false;

  final List<double> _intensityRecords = [];
  final List<InputDevice> inputDevices = [];
  InputDevice? choosenDevice;

  StreamSubscription? onStateChangedSubscription;
  StreamSubscription? onAmplitudeChangedSubscription;

  RecordAudioNotifier() {
    getDevices();
  }

  final record = AudioRecorder();

  List<double> get intensityRecords => List.unmodifiable(_intensityRecords);

  void getDevices() async {
    if (await record.hasPermission()) {
      inputDevices.clear();
      var devices = await record.listInputDevices();
      inputDevices.addAll(devices.where((device) => device.id.isNotEmpty && device.label.isNotEmpty));
      choosenDevice = inputDevices.first;
      notifyListeners();
    }
  }

  void changeDevice(InputDevice device) {
    choosenDevice = device;
    notifyListeners();
  }

  Future<void> startRecording() async {
    var path = 'recording.wav';
    if (!kIsWeb) {
      final directory = await getApplicationDocumentsDirectory();
      path = '${directory.path}/recording.wav';
    }
    var hasPermission = await record.hasPermission();

    if (hasPermission) {
      await record.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          device: choosenDevice,
        ),
        path: path,
      );

      isRecording = true;
      notifyListeners();

      onStateChangedSubscription = record.onStateChanged().listen((event) {
        if (event == RecordState.record) {
          onAmplitudeChangedSubscription = record.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amplitude) {
            double dbLevel = amplitude.current; // Use the amplitude value directly

            // Debug logging
            log('Raw amplitude (dBFS): $dbLevel');

            // Normalize dBFS to a range between 0 and 1
            double normalizedValue = (dbLevel + 100) / 100; // Assuming -100 dBFS is the minimum

            // Scale normalized value to desired height range (e.g., 0 to 200)
            double scaledHeight = normalizedValue * 200;

            log('Scaled height: $scaledHeight');

            if (scaledHeight < 0 || dbLevel.isNaN) {
              _intensityRecords.clear();
              _intensityRecords.addAll(List.filled(28, 5));
            } else {
              addIntensityRecord(scaledHeight);
            }
            notifyListeners();
          });
        }
      });
    } else {
      log('Permission denied');
    }
  }

  void addIntensityRecord(double intensity) {
    if (_intensityRecords.length > 28) {
      _intensityRecords.removeAt(0);
    }
    _intensityRecords.add(intensity);
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (isRecording) {
      await record.stop();
      onStateChangedSubscription?.cancel();
      onAmplitudeChangedSubscription?.cancel();
      onStateChangedSubscription = null;
      onAmplitudeChangedSubscription = null;
      isRecording = false;
      notifyListeners();
    }
  }

  Future<void> deleteRecording() async {
    if (isRecording) {
      await record.cancel();
      onStateChangedSubscription?.cancel();
      onAmplitudeChangedSubscription?.cancel();
      onStateChangedSubscription = null;
      onAmplitudeChangedSubscription = null;
      isRecording = false;
      notifyListeners();
    }
  }

  Future<void> sendRecording() async {
    if (isRecording) {
      await stopRecording();
    }

    // The recording is saved at the specified path
    if (!kIsWeb) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/recording.wav';
      log('Recording saved at $path');
    } else {
      download();
    }
  }

  @override
  void dispose() {
    onStateChangedSubscription?.cancel();
    onAmplitudeChangedSubscription?.cancel();
    record.dispose();
    super.dispose();
  }
}
