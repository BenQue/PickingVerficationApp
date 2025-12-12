/// Line Stock Management Feature Constants
class LineStockConstants {
  // API Endpoints
  static const String queryApiPath = '/api/LineStock/byBarcode';
  static const String queryByMaterialApiPath = '/api/LineStock/byMaterialCode';
  static const String transferApiPath = '/api/LineStock/transfer';

  // Handover/Receiving API Endpoints
  static const String handoverQueryApiPath = '/api/LineStock/GetHandoverListByBarcode';
  static const String handoverConfirmApiPath = '/api/LineStock/HandoverConfirm';

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

  // Handover/Receiving Messages
  static const String handoverQuerySuccess = '查询成功';
  static const String handoverConfirmSuccess = '标签收货确认完成！';
  static const String handoverDuplicateError = '该条码已在待入库列表中';

  // Material Query Messages
  static const String materialCodeEmptyError = '物料号不能为空';
  static const String materialNotFoundError = '未找到该物料的库存信息';
}
