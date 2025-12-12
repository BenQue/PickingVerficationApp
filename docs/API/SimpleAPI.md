/api/WorkOrderPickVerf

GET Method:
Parameters
orderno = "string"

Request URL
http://10.163.130.173:8001/api/WorkOrderPickVerf?orderno=123456789

成功响应 (200 OK):
{
"isSuccess": true,
"message": "操作成功",
"data": {
"orderId": 1,
"orderNo": "123456789",
"operationNo": "0001",
"operationStatus": "1",
"cableItemCount": 2,
"rawItemCount": 10,
"rawMtrBatchCount": 12,
"labelCount": 5,
"cableItems": [
{
"itemNo": "001",
"materialCode": "C001",
"materialDesc": "Cable 1",
"quantity": 5,
"completedQuantity": 3
},
{
"itemNo": "002",
"materialCode": "C002",
"materialDesc": "Cable 2",
"quantity": 3,
"completedQuantity": 3
}
],
"centerStockItems": [
{
"itemNo": "003",
"materialCode": "C003",
"materialDesc": "Cable 3",
"quantity": 5,
"completedQuantity": 3
},
{
"itemNo": "004",
"materialCode": "C004",
"materialDesc": "Cable 4",
"quantity": 3,
"completedQuantity": 3
}
],
"autoStockItems": [
{
"itemNo": "005",
"materialCode": "C005",
"materialDesc": "Cable 5",
"quantity": 5,
"completedQuantity": 3
},
{
"itemNo": "006",
"materialCode": "C006",
"materialDesc": "Cable 6",
"quantity": 3,
"completedQuantity": 3
}
]
}
}

错误响应 (400 Bad Request):
{
"isSuccess": false,
"message": "扫码出错：未查询到订单信息",
"data": null
}

说明:

- 当订单号不存在或查询失败时,返回 400 状态码
- message 字段包含具体的错误信息,将在客户端直接展示给用户
- 客户端会在界面上显示该错误消息并允许用户重试或返回

PUT Method

Return Code 200 OK
{
"isSuccess": true,
"message": "操作成功",
"data": true
}

Retrun Code 400 Error: Bad Request
{
"isSuccess": false,
"message": "扫码出错：未查询到订单信息",
"data": null
}

PUT Method

Request body
{
"workOrderId": 1,
"operation": "0001",
"status": "verfSuccess",
"workCenter": "WC001",
"updateOn": "2025-09-14T12:48:25.879Z",
"updateBy": "operator"
}

说明:

- workOrderId: 工单 ID (从 GET 响应的 orderId 获取)
- operation: 工序号 (从 GET 响应的 operationNo 获取)
- status: 状态码 (校验成功传 "verfSuccess")
- workCenter: 工作中心
- updateOn: 更新时间 (ISO8601 格式)
- updateBy: 更新人

Return Code 200 OK
{
"isSuccess": true,
"message": "操作成功",
"data": true
}

电缆收货：

## 库存查询 API

### 1. 按物料号查询 (返回多批次)

用于查询某物料号下所有批次的库存信息，返回列表。

Get Method
Request URL:
http://SVCN5MESP01:8001/api/LineStock/byMaterialCode
Parameter:
factoryid = 2
materialcode = "string"

Response body
{
"isSuccess": true,
"message": "string",
"data": [
{
"id": 0,
"factoryId": 0,
"materialId": 0,
"materialCode": "string",
"materialDesc": "string",
"baseUnit": "string",
"batchCode": "string",
"barCode": "string",
"quantity": 0,
"lastQuantity": 0,
"status": "string",
"sapStatus": "string",
"locationId": 0,
"locationCode": "string",
"locationDesc": "string",
"createdAt": "2025-12-12T06:16:44.016Z",
"createdBy": "string",
"updatedAt": "2025-12-12T06:16:44.016Z",
"updateBy": "string"
}
]
}

### 2. 按条码查询 (返回单条)

用于查询特定电缆条码的库存信息，返回单个对象。

Request URL:
http://SVCN5MESP01:8001/api/LineStock/ByBarcode?factoryid=2&barcode=0010985231001

Parameters:
factoryid=2
barcode= "string"

Response
{
"isSuccess": true,
"message": "操作成功",
"data": {
"id": 8274,
"factoryId": 2,
"materialId": 571441,
"materialCode": "806823",
"materialDesc": "CABLE L-YY 3X1X1.5 OIL RESIST UL2464",
"baseUnit": "M",
"batchCode": "0010985231",
"barCode": "0010985231001",
"quantity": 200.000,
"lastQuantity": 176.050,
"status": "1",
"sapStatus": "1",
"locationId": 4,
"locationCode": "2200-100",
"locationDesc": "断线线边库",
"createdAt": "2025-11-29T21:20:00.4",
"createdBy": "JYDB",
"updatedAt": null,
"updateBy": null
}
}

Post Method:

Request URL:
http://SVCN5MESP01:8001/api/LineStock/HandoverConfirm

Request body

{
"barCodes": [
"0010985231001"
]
}

返回消息：

Response
{
"isSuccess": true,
"message": "标签收货确认完成！",
"data": true
}

Request URL:
http://SVCN5MESP01:8001/api/CableCutParam/byMaterialCodes

Request Body:
{
"semiMaterialCode": [
"string"
]
}

返回消息&Response body：

{
"isSuccess": true,
"message": "string",
"data": [
{
"cuttoLeranceId": 0,
"semiMaterialCode": "string",
"cableMaterialCode": "string",
"cableType": "string",
"drawingCode": "string",
"positionItem": "string",
"cablePcs": 0,
"postionNo": "string",
"bomLength": 0,
"upTol": 0,
"downTol": 0,
"alphaFactor": 0,
"betaFactor": 0,
"cuttingLength": 0,
"cuttingTime": 0,
"reelCode": "string",
"remark": "string",
"status": "string",
"createDate": "string",
"createTime": "string",
"createBy": "string",
"updateDate": "string",
"updateTime": "string",
"updateBy": "string"
}
]
}
