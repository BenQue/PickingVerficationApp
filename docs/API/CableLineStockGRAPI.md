电缆收货：

Get Method

Parameters:
factoryid=2
barcode= "string"
Request URL:
http://SVCN5MESP01:8001/api/LineStock/GetHandoverListByBarcode?factoryid=2&barcode=0010985231001

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
