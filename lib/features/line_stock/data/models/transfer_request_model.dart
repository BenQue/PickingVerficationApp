/// Transfer Request Model
/// Request body for stock transfer API
class TransferRequestModel {
  final String locationCode;
  final List<String> barCodes;

  const TransferRequestModel({
    required this.locationCode,
    required this.barCodes,
  });

  Map<String, dynamic> toJson() {
    return {
      'locationCode': locationCode,
      'barCodes': barCodes,
    };
  }

  factory TransferRequestModel.fromJson(Map<String, dynamic> json) {
    return TransferRequestModel(
      locationCode: json['locationCode'] as String,
      barCodes: List<String>.from(json['barCodes'] as List),
    );
  }
}
