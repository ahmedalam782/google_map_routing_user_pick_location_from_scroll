class RegionModel {
  final String id;
  final String name;
  final String polygonId;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Geometry geometry;

  const RegionModel({
    required this.id,
    required this.name,
    required this.polygonId,
    required this.deleted,
    required this.createdAt,
    required this.updatedAt,
    required this.geometry,
  });

  factory RegionModel.fromJson(Map<String, dynamic> json) {
    return RegionModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      polygonId: json['polygonId'] as String,
      deleted: json['deleted'] as bool,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      geometry: Geometry.fromJson(json['geometry']),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'polygonId': polygonId,
        'deleted': deleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'geometry': geometry.toJson(),
      };
}

class Geometry {
  final String type;
  final List<List<List<double>>> coordinates;

  const Geometry({
    required this.type,
    required this.coordinates,
  });

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      type: json['type'] as String,
      coordinates: (json['coordinates'] as List)
          .map((outer) => (outer as List)
              .map((inner) => (inner as List)
                  .map((coord) => (coord as num).toDouble())
                  .toList())
              .toList())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'coordinates': coordinates,
      };
}
