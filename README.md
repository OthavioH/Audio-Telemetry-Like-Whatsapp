# Audio Telemetry Like WhatsApp

This Flutter App is a demo test to make an audio telemetry like WhatsApp.

![image](https://github.com/user-attachments/assets/9df28320-e52c-449b-af1a-4d4561bbd1e2)

## Dependencies

The main package for this demo is the [Record](https://pub.dev/packages/record) package, which is used to record the audio and get the Amplitude data.

The app gets the amplitude data in dBFS and normalize it to get a value between 0 and 200, save it in a List of length 10 and build it on the screen using a Container.

### Other Dependencies
- path_provider
- flutter_riverpod
- universal_html
- permission_handler