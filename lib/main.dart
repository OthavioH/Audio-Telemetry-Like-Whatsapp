import 'package:audio_like_whatsapp/record_audio_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Telemetry Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Audio Telemetry'),
      ),
      body: Builder(builder: (context) {
        var isRecording = ref.watch(recordAudioProvider).isRecording;
        var listOfIntensities = ref.watch(recordAudioProvider).intensityRecords;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<InputDevice>(
                value: ref.watch(recordAudioProvider).choosenDevice,
                isExpanded: true,
                items: ref
                    .watch(recordAudioProvider)
                    .inputDevices
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                selectedItemBuilder: (context) {
                  return ref
                      .watch(recordAudioProvider)
                      .inputDevices
                      .map((e) => Text(
                            e.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ))
                      .toList();
                },
                onChanged: (value) {
                  if (value != null) {
                    ref.read(recordAudioProvider).changeDevice(value);
                  }
                },
              ),
              const SizedBox(
                height: 20,
              ),
              isRecording
                  ? SizedBox(
                      height: 210,
                      child: ListView.builder(
                        itemCount: listOfIntensities.length,
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                width: 10,
                                height: listOfIntensities[index],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : const SizedBox(),
              const SizedBox(
                height: 20,
              ),
              SendMessageWidget(
                isRecording: ref.watch(recordAudioProvider).isRecording,
                onDeleteRecording: ref.read(recordAudioProvider).deleteRecording,
                onSendRecording: ref.read(recordAudioProvider).sendRecording,
                onStartRecording: ref.read(recordAudioProvider).startRecording,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class SendMessageWidget extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onSendRecording;
  final VoidCallback onDeleteRecording;
  const SendMessageWidget({
    required this.isRecording,
    required this.onStartRecording,
    required this.onSendRecording,
    required this.onDeleteRecording,
    super.key,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 60,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Visibility(
              visible: isRecording,
              child: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: () {
                  onDeleteRecording();
                },
              ),
            ),
            Visibility(
              visible: isRecording,
              child: IconButton(
                icon: const Icon(
                  Icons.send,
                  color: Colors.green,
                ),
                onPressed: () {
                  onSendRecording();
                },
              ),
            ),
            Visibility(
              visible: !isRecording,
              child: InkWell(
                onTap: () {
                  onStartRecording();
                },
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.mic),
                ),
              ),
            ),
          ],
        ),
      );
}
