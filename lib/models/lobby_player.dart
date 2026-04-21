class LobbyPlayer {
  const LobbyPlayer({
    required this.id,
    required this.name,
    required this.isHost,
    required this.isConnected,
    this.address,
  });

  final String id;
  final String name;
  final bool isHost;
  final bool isConnected;
  final String? address;

  LobbyPlayer copyWith({
    String? id,
    String? name,
    bool? isHost,
    bool? isConnected,
    String? address,
  }) {
    return LobbyPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isHost: isHost ?? this.isHost,
      isConnected: isConnected ?? this.isConnected,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isHost': isHost,
      'isConnected': isConnected,
      'address': address,
    };
  }

  factory LobbyPlayer.fromJson(Map<String, dynamic> json) {
    return LobbyPlayer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isHost: json['isHost'] as bool? ?? false,
      isConnected: json['isConnected'] as bool? ?? true,
      address: json['address'] as String?,
    );
  }
}
