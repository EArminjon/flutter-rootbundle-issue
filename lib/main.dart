import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:path_provider/path_provider.dart';

Future<void> isolateRunner(SendPort port) async {
  final Stopwatch clock = Stopwatch()..start();
  debugPrint("Isolate start");
  final ByteData data = await rootBundle.load("assets/400mb.bin");
  debugPrint("Isolate load success. Elapsed time: ${clock.elapsedMilliseconds}...");

  final Directory directory = await getApplicationDocumentsDirectory();
  final String dbPath = '${directory.path}/movie.bin';
  final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

  await File(dbPath).writeAsBytes(bytes);

  debugPrint("Isolate write success. Elapsed time: ${clock.elapsedMilliseconds}...");
  port.send(true);
}

Future<void> initIsolateHeavyWork() async {
  final ReceivePort port = ReceivePort();
  late FlutterIsolate isolate;
  port.listen((dynamic message) {
    debugPrint("Isolate message: $message");
    port.close();
    // Else isolate is still alive, memory leak
    isolate.kill();
  });
  isolate = await FlutterIsolate.spawn(isolateRunner, port.sendPort);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: Home());
}

class Home extends StatelessWidget {
  const Home({super.key});

  // Used to see freeze easier
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  initIsolateHeavyWork();
                },
                child: const Text("heavy task"),
              ),
              const SizedBox(height: 16),
              const Text("Loader bellow is displayed to show when app freeze"),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
}
