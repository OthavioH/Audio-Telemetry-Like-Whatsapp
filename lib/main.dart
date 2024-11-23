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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

// Column is also a layout widget. It takes a list of children and
// arranges them vertically. By default, it sizes itself to fit its
// children horizontally, and tries to be as tall as its parent.
//
// Column has various properties to control how it sizes itself and
// how it positions its children. Here we use mainAxisAlignment to
// center the children vertically; the main axis here is the vertical
// axis because Columns are vertical (the cross axis would be
// horizontal).
//
// TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
// action in the IDE, or press "p" in the console), to see the
// wireframe for each widget.

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
        title: const Text('Flutter Demo Home Page'),
      ),
      body: Center(
        child: Builder(builder: (context) {
          var isRecording = ref.watch(recordAudioProvider).isRecording;
          var listOfIntensities = ref.watch(recordAudioProvider).intensityRecords;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<InputDevice>(
                value: ref.watch(recordAudioProvider).choosenDevice,
                items: ref
                    .watch(recordAudioProvider)
                    .inputDevices
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.label),
                        ))
                    .toList(),
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
                  ? Flexible(
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
          );
        }),
      ),
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
          children: [
            Expanded(
              child: Container(
                color: Colors.grey,
              ),
            ),
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
              child: IconButton(
                icon: const Icon(Icons.mic),
                onPressed: () {
                  onStartRecording();
                },
              ),
            ),
          ],
        ),
      );
}
