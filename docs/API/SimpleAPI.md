/api/WorkOrderPickVerf

GET Method:
Parameters
orderno = "string"

Request URL
http://10.163.130.173:8001/api/WorkOrderPickVerf?orderno=123456789

Responses body:
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
"labelCount": 5,
"cabelItems": [
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

PUT Method

Request body
{
"workOrderId": 0,
"operation": "string",
"status": "string",
"workCenter": "string",
"updateOn": "2025-09-14T12:48:25.879Z",
"updateBy": "string"
}

Retrun Code 200 OK
{
"isSuccess": true,
"message": "string",
"data": true
}
