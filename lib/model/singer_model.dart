class SingerModel {
  SingerModel(this.singerId, this.name);

  factory SingerModel.fromMap(map) {
    return SingerModel(
      map['id'] as int,
      map['name'] as String,
    );
  }

  final int singerId;
  final String name;

  Map<String, dynamic> toMap() {
    return {
      'id': singerId,
      'name': name,
    };
  }
}
