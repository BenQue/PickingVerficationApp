/// Request model for handover confirmation API
///
/// Used for POST /api/LineStock/HandoverConfirm endpoint
class HandoverConfirmRequest {
  final List<String> barCodes;

  const HandoverConfirmRequest({
    required this.barCodes,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'barCodes': barCodes,
    };
  }
}
