/// Line Stock Management Feature Constants
class LineStockConstants {
  // API Endpoints
  static const String queryApiPath = '/api/LineStock/byBarcode';
  static const String transferApiPath = '/api/LineStock/transfer';

  // Validation
  static const int barcodeMinLength = 1;
  static const int locationCodeMinLength = 1;

  // Timing
  static const Duration scanDebounce = Duration(milliseconds: 100);
  static const Duration errorDisplayDuration = Duration(seconds: 2);

  // Fixed Locations
  static const String lineStockLocation = '2200-100';
  
  // Messages
  static const String querySuccessMessage = '查询成功';
  static const String transferSuccessMessage = '转移成功';
  static const String barcodeEmptyError = '条码不能为空';
  static const String locationEmptyError = '库位不能为空';
  static const String duplicateBarcodeError = '条码已存在';
  static const String networkError = '网络连接失败';
  static const String serverError = '服务器错误';
  static const String unknownError = '未知错误';
}
