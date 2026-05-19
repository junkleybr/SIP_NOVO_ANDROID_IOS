import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/call_log.dart';
import 'storage_service.dart';

/// Mantém o histórico em memória + persistido.
class CallLogService extends ChangeNotifier {
  CallLogService(this._storage);

  final StorageService _storage;
  final _uuid = const Uuid();
  List<CallLogEntry> _entries = <CallLogEntry>[];

  List<CallLogEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    _entries = await _storage.loadCallLog();
    _entries.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    notifyListeners();
  }

  Future<void> add({
    required String number,
    String? name,
    required Duration duration,
    required CallDirection direction,
    DateTime? startedAt,
  }) async {
    final e = CallLogEntry(
      id: _uuid.v4(),
      number: number,
      name: name,
      duration: duration,
      direction: direction,
      startedAt: startedAt ?? DateTime.now(),
    );
    _entries = [e, ..._entries];
    if (_entries.length > 200) _entries = _entries.sublist(0, 200);
    await _storage.saveCallLog(_entries);
    notifyListeners();
  }

  Future<void> clear() async {
    _entries = [];
    await _storage.saveCallLog(_entries);
    notifyListeners();
  }
}
