class ContactEntry {
  final String id;
  final String name;
  final String number;
  final bool favorite;

  const ContactEntry({
    required this.id,
    required this.name,
    required this.number,
    this.favorite = false,
  });

  ContactEntry copyWith({String? name, String? number, bool? favorite}) =>
      ContactEntry(
        id: id,
        name: name ?? this.name,
        number: number ?? this.number,
        favorite: favorite ?? this.favorite,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'number': number,
        'favorite': favorite,
      };

  factory ContactEntry.fromJson(Map<String, dynamic> j) => ContactEntry(
        id: j['id'] as String,
        name: j['name'] as String,
        number: j['number'] as String,
        favorite: j['favorite'] as bool? ?? false,
      );
}
