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

  // Change this if you want to display more telemetry lines
  int maxTelemetryLines = 15;

  RecordAudioNotifier() {
    getDevices();
  }

  final record = AudioRecorder();

  List<double> get intensityRecords => List.unmodifiable(_intensityRecords);

  /// Retrieves the list of available input audio devices and updates the
  /// `inputDevices` list with devices that have non-empty IDs and labels.
  ///
  /// If the user has granted permission to access audio recording, this method
  /// clears the current list of input devices, fetches the available devices,
  /// filters out those with empty IDs or labels, and adds the remaining devices
  /// to the `inputDevices` list. The first device in the updated list is set as
  /// the `choosenDevice`. Finally, it notifies listeners about the changes.
  ///
  /// This method is asynchronous and should be called with `await`.
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

  /// Starts recording audio and updates the recording state.
  ///
  /// This method checks for recording permissions and starts recording audio
  /// if permissions are granted. It saves the recording to a file named
  /// 'recording.wav' in the application's documents directory (or the current
  /// directory if running on the web). The recording state is updated and
  /// listeners are notified.
  ///
  /// While recording, it listens to amplitude changes and logs the raw
  /// amplitude in dBFS. The amplitude is normalized to a range between 0 and 1,
  /// then scaled to a desired height range (e.g., 0 to 200). The scaled height
  /// is used to update intensity records, which are cleared and reset if the
  /// scaled height is less than 0 or if the dB level is NaN.
  ///
  /// If recording permissions are denied, a log message is generated.
  ///
  /// Throws:
  /// - `Exception` if an error occurs while starting the recording.
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
              _intensityRecords.addAll(List.filled(10, 5));
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
    if (_intensityRecords.length > 10) {
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

  /// Sends the recording by stopping the recording if it is in progress,
  /// and then saving the recording to a specified path or downloading it.
  ///
  /// If the platform is not web, the recording is saved in the application's
  /// documents directory with the filename 'recording.wav'. The path to the
  /// saved recording is logged.
  ///
  /// If the platform is web, the recording is downloaded.
  ///
  /// This method is asynchronous and returns a [Future] that completes when
  /// the recording has been sent.
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
      downloadFileOnBrowser();
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
