enum CallDirection { incoming, outgoing, missed }

class CallLogEntry {
  final String id;
  final String number;
  final String? name;
  final DateTime startedAt;
  final Duration duration;
  final CallDirection direction;

  const CallLogEntry({
    required this.id,
    required this.number,
    required this.startedAt,
    required this.duration,
    required this.direction,
    this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'name': name,
        'startedAt': startedAt.toIso8601String(),
        'durationSec': duration.inSeconds,
        'direction': direction.name,
      };

  factory CallLogEntry.fromJson(Map<String, dynamic> j) => CallLogEntry(
        id: j['id'] as String,
        number: j['number'] as String,
        name: j['name'] as String?,
        startedAt: DateTime.parse(j['startedAt'] as String),
        duration: Duration(seconds: j['durationSec'] as int? ?? 0),
        direction: CallDirection.values.firstWhere(
          (d) => d.name == j['direction'],
          orElse: () => CallDirection.outgoing,
        ),
      );
}
