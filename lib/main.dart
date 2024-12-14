import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PrefCounter());
}

sealed class Result<T> {
  const Result();
  factory Result.ok(T value) => Ok(value);
  factory Result.error(Exception error) => Error(error);
}

final class Ok<T> extends Result<T> {
  final T value;
  Ok(this.value);
  @override
  String toString() => 'Result<$T>.ok($value)';
}

final class Error<T> extends Result<T> {
  final Exception error;
  Error(this.error);
  @override
  String toString() => 'Error<$T>.error($error)';
}

typedef CommandAction0<T> = Future<Result<T>> Function();

abstract class Command<T> extends ChangeNotifier {
  Command();
  bool _running = false;
  bool get running => _running;

  Result<T>? _result;
  Result? get result => _result;

  bool get error => _result is Error;
  bool get completed => _result! is Ok;

  /*  void clearResult() {
    _result = null;
    notifyListeners();
  } */

  Future<void> _execute(CommandAction0<T> action) async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();
    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

class Command0<T> extends Command<T> {
  Command0(this._action);
  final CommandAction0<T>? _action;
  Future<void> execute() async {
    await _execute(() => _action!());
  }
}

class PrefCounter extends StatefulWidget {
  const PrefCounter({super.key});

  @override
  State<PrefCounter> createState() => _PrefCounterState();
}

class _PrefCounterState extends State<PrefCounter> {
  late Command0 loadComm, incComm;
  int _counter = 0;

  @override
  void initState() {
    loadComm = Command0(_loadCounter)..execute();
    super.initState();
  }

  Future<Result<void>> _loadCounter() async {
    try {
      final pref = await SharedPreferences.getInstance();
      setState(() {
        _counter = pref.getInt('counter') ?? 0;
      });
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<int>> _increment() async {
    try {
      final pref = await SharedPreferences.getInstance();
      setState(() {
        _counter = (pref.getInt('counter') ?? 0) + 1;
        pref.setInt('counter', _counter);
      });

      return Result.ok(_counter);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
            title: const Text(
              'Counter',
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Number of button presses:'),
              Text(
                _counter.toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            incComm = Command0(_increment)..execute();
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
