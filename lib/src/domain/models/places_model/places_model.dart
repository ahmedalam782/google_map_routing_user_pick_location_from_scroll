import 'prediction.dart';

class PlacesModel {
  List<Prediction>? predictions;
  String? status;

  PlacesModel({this.predictions, this.status});

  factory PlacesModel.fromJson(Map<String, dynamic> json) => PlacesModel(
        predictions: (json['predictions'] as List<dynamic>?)
            ?.map((e) => Prediction.fromJson(e as Map<String, dynamic>))
            .toList(),
        status: json['status'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'predictions': predictions?.map((e) => e.toJson()).toList(),
        'status': status,
      };
}
