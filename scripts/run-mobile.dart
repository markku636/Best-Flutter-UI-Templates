import 'dart:convert';
import 'dart:io';

final appDirectory = Directory.fromUri(
  Platform.script.resolve('../best_flutter_ui_templates/'),
).path;

String join(String parent, String child) =>
    '$parent${Platform.pathSeparator}$child';

String get flutter {
  final root = Platform.environment['FLUTTER_ROOT'];
  return root == null
      ? 'flutter'
      : join(join(root, 'bin'), Platform.isWindows ? 'flutter.bat' : 'flutter');
}

Future<ProcessResult> command(
  String executable,
  List<String> args, {
  Duration? timeout,
}) async {
  final process = await Process.start(
    executable,
    args,
    workingDirectory: appDirectory,
    runInShell: Platform.isWindows,
  );
  final output = process.stdout.transform(utf8.decoder).join();
  final errors = process.stderr.transform(utf8.decoder).join();
  final resultCode = timeout == null
      ? await process.exitCode
      : await process.exitCode.timeout(
          timeout,
          onTimeout: () {
            process.kill();
            throw StateError('$executable ${args.join(' ')} timed out.');
          },
        );
  return ProcessResult(process.pid, resultCode, await output, await errors);
}

Future<String> checked(
  String executable,
  List<String> args, {
  Duration? timeout,
}) async {
  final result = await command(executable, args, timeout: timeout);
  if (result.exitCode != 0) {
    throw StateError(
      '$executable ${args.join(' ')} failed:\n${result.stdout}${result.stderr}',
    );
  }
  return result.stdout.toString().trim();
}

Future<int> interactive(String executable, List<String> args) async {
  final process = await Process.start(
    executable,
    args,
    workingDirectory: appDirectory,
    runInShell: Platform.isWindows,
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}

Future<List<Map<String, dynamic>>> devices() async {
  final output = await checked(flutter, ['devices', '--machine']);
  return (jsonDecode(output) as List).cast<Map<String, dynamic>>();
}

T choose<T>(List<T> values, String Function(T) label, String title) {
  if (values.isEmpty) throw StateError('No $title available.');
  if (values.length == 1) return values.single;
  stdout.writeln('Choose $title:');
  for (var i = 0; i < values.length; i++) {
    stdout.writeln('  ${i + 1}. ${label(values[i])}');
  }
  while (true) {
    stdout.write('Number (or q to cancel): ');
    final answer = stdin.readLineSync();
    if (answer == null || answer.trim().toLowerCase() == 'q') {
      throw StateError('Cancelled.');
    }
    final index = int.tryParse(answer.trim());
    if (index != null && index > 0 && index <= values.length) {
      return values[index - 1];
    }
  }
}

String androidSdk() {
  final env = Platform.environment;
  final candidates = [
    if (env['ANDROID_HOME'] != null) env['ANDROID_HOME']!,
    if (env['ANDROID_SDK_ROOT'] != null) env['ANDROID_SDK_ROOT']!,
    if (Platform.isWindows && env['LOCALAPPDATA'] != null)
      join(env['LOCALAPPDATA']!, 'Android${Platform.pathSeparator}Sdk'),
  ];
  for (final candidate in candidates) {
    if (Directory(candidate).existsSync()) return candidate;
  }
  throw StateError(
    'Android SDK was not found. Install Android Studio, then install the SDK, '
    'Command-line Tools, Platform-Tools and Android Emulator in SDK Manager. '
    'For a custom SDK location, set ANDROID_HOME.\n'
    'https://docs.flutter.dev/platform-integration/android/setup',
  );
}

Future<String> androidEmulator(String? requested, int timeoutSeconds) async {
  final sdk = androidSdk();
  final emulator = join(join(sdk, 'emulator'), 'emulator.exe');
  final adb = join(join(sdk, 'platform-tools'), 'adb.exe');
  if (!File(emulator).existsSync() || !File(adb).existsSync()) {
    throw StateError(
      'Install Android Emulator and Android SDK Platform-Tools in SDK Manager.',
    );
  }
  final avds = (await checked(emulator, ['-list-avds']))
      .split(RegExp(r'\r?\n'))
      .where((line) => line.trim().isNotEmpty)
      .map((line) => line.trim())
      .toList();
  if (avds.isEmpty) {
    throw StateError(
      'No Android virtual device exists. In Android Studio, open Device Manager '
      'and create a phone with a system image first.',
    );
  }
  final name =
      requested ?? choose<String>(avds, (name) => name, 'Android emulator');
  if (!avds.contains(name)) {
    throw StateError('Unknown AVD "$name". Available: ${avds.join(', ')}');
  }
  await checked(adb, ['start-server']);
  Future<String?> matchingDevice() async {
    final output = await checked(adb, ['devices']);
    for (final line in output.split('\n')) {
      final match = RegExp(r'^(emulator-\d+)\s+device\s*$').firstMatch(line);
      if (match == null) continue;
      final id = match.group(1)!;
      final response = await command(adb, [
        '-s',
        id,
        'emu',
        'avd',
        'name',
      ], timeout: const Duration(seconds: 10));
      if (response.stdout.toString().split(RegExp(r'\r?\n')).first.trim() ==
          name) {
        return id;
      }
    }
    return null;
  }

  if (await matchingDevice() == null) {
    stdout.writeln('Starting Android emulator: $name');
    // The emulator window is an intended visible output of this launcher.
    await Process.start(emulator, [
      '-avd',
      name,
    ], mode: ProcessStartMode.detached);
  }
  stdout.writeln('Waiting for Android to finish booting...');
  final deadline = DateTime.now().add(Duration(seconds: timeoutSeconds));
  while (DateTime.now().isBefore(deadline)) {
    final id = await matchingDevice();
    if (id != null) {
      final boot = await command(adb, [
        '-s',
        id,
        'shell',
        'getprop',
        'sys.boot_completed',
      ], timeout: const Duration(seconds: 10));
      if (boot.exitCode == 0 && boot.stdout.toString().trim() == '1') {
        return id;
      }
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  throw StateError(
    'Android did not boot within $timeoutSeconds seconds. Check the emulator '
    'window and hardware virtualization, or retry with --timeout 600.',
  );
}

Future<String> iosSimulator(String? requested, int timeoutSeconds) async {
  await checked('xcodebuild', ['-version']);
  final output = await checked('xcrun', [
    'simctl',
    'list',
    'devices',
    'available',
    '--json',
  ]);
  final groups = (jsonDecode(output) as Map<String, dynamic>)['devices'] as Map;
  final sims = <Map<String, dynamic>>[];
  for (final entry in groups.entries) {
    if (!entry.key.toString().contains('.iOS-')) continue;
    for (final value in entry.value as List) {
      final sim = Map<String, dynamic>.from(value as Map);
      if (sim['isAvailable'] == true) {
        sim['runtime'] = entry.key.toString().split('.').last;
        sims.add(sim);
      }
    }
  }
  if (sims.isEmpty) {
    throw StateError(
      'No iOS simulator is installed. Download an iOS runtime in Xcode Settings '
      '> Components, or run xcodebuild -downloadPlatform iOS.',
    );
  }
  final matches = requested == null
      ? sims
      : sims.where((sim) => sim['udid'] == requested).toList();
  if (matches.isEmpty)
    throw StateError('Unknown iOS simulator UDID: $requested');
  final booted = matches.where((sim) => sim['state'] == 'Booted').toList();
  final sim = choose(
    requested == null && booted.isNotEmpty ? booted : matches,
    (sim) => '${sim['name']} (${sim['runtime']}, ${sim['state']})',
    'iOS simulator',
  );
  final id = sim['udid'] as String;
  if (sim['state'] != 'Booted') {
    stdout.writeln('Booting ${sim['name']}...');
    await checked('xcrun', ['simctl', 'boot', id]);
  }
  if ((await command('open', ['-a', 'DeviceHub'])).exitCode != 0) {
    await checked('open', ['-a', 'Simulator']);
  }
  stdout.writeln('Waiting for iOS to finish booting...');
  await checked('xcrun', [
    'simctl',
    'bootstatus',
    id,
    '-b',
  ], timeout: Duration(seconds: timeoutSeconds));
  return id;
}

void usage() {
  stdout.writeln('''
Usage: run-android.cmd [options]  (Windows)
       bash run-ios.command [options]  (macOS)

  --help               Show help
  --check              Run flutter doctor without launching the app
  --list               List connected devices and available emulators
  --device <id>        Run on an already connected phone or simulator
  --emulator <id>      Launch an Android AVD name or an iOS simulator UDID
  --timeout <seconds>  Simulator boot timeout (default: 300)
  -- <arguments>       Pass remaining arguments to flutter run (e.g. --release)

The launcher opens an emulator by default and runs flutter pub get first.
Android SDK licenses must be reviewed with flutter doctor --android-licenses.
iPhone signing must be configured with your Team in Xcode.
''');
}

Future<void> main(List<String> args) async {
  try {
    if (args.isEmpty) throw ArgumentError('Specify android or ios.');
    final platform = args.first;
    if (platform != 'android' && platform != 'ios') {
      throw ArgumentError('Unknown platform: $platform');
    }
    String? deviceId;
    String? emulatorId;
    var timeout = 300;
    var list = false;
    var check = false;
    var help = false;
    final forwarded = <String>[];
    for (var i = 1; i < args.length; i++) {
      final option = args[i];
      if (option == '--') {
        forwarded.addAll(args.skip(i + 1));
        break;
      }
      switch (option) {
        case '--help':
          help = true;
        case '--check':
          check = true;
        case '--list':
          list = true;
        case '--device' || '--emulator' || '--timeout':
          if (++i >= args.length) throw ArgumentError('Missing value: $option');
          if (option == '--device') deviceId = args[i];
          if (option == '--emulator') emulatorId = args[i];
          if (option == '--timeout') {
            timeout = int.tryParse(args[i]) ?? 0;
            if (timeout <= 0) throw ArgumentError('Timeout must be positive.');
          }
        default:
          throw ArgumentError('Unknown option: $option. Use --help.');
      }
    }
    if (help) {
      usage();
      return;
    }
    if (deviceId != null && emulatorId != null) {
      throw ArgumentError('Choose either --device or --emulator.');
    }
    if (platform == 'ios' && !Platform.isMacOS) {
      throw StateError('iOS requires macOS and Xcode.');
    }
    if (platform == 'android' && !Platform.isWindows) {
      throw StateError('This Android launcher is for Windows.');
    }
    if (check) {
      exitCode = await interactive(flutter, ['doctor', '-v']);
      return;
    }
    if (list) {
      stdout.writeln(await checked(flutter, ['devices']));
      final emulators = await command(flutter, ['emulators']);
      stdout.write(emulators.stdout);
      if (emulators.stderr.toString().isNotEmpty) {
        stdout.write(emulators.stderr);
      }
      return;
    }
    if (deviceId != null) {
      final connected = await devices();
      final matches = connected.where(
        (device) =>
            device['id'] == deviceId &&
            (platform == 'ios'
                ? device['targetPlatform'] == 'ios'
                : device['targetPlatform'].toString().startsWith('android')),
      );
      if (matches.isEmpty) {
        throw StateError(
          'Device "$deviceId" is not a connected $platform device. '
          'Use --list to see devices.',
        );
      }
    } else {
      deviceId = platform == 'android'
          ? await androidEmulator(emulatorId, timeout)
          : await iosSimulator(emulatorId, timeout);
    }
    if (await interactive(flutter, ['pub', 'get']) != 0) {
      throw StateError('flutter pub get failed.');
    }
    stdout.writeln('Running the app on $deviceId...');
    exitCode = await interactive(flutter, [
      'run',
      '-d',
      deviceId,
      ...forwarded,
    ]);
  } catch (error) {
    stderr.writeln('\n$error');
    exitCode = 1;
  }
}
