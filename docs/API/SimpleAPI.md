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
