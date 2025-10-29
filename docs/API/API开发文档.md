# BizLink.MES.WebAPI 开发文档

版本：1.0  
基于：OpenAPI 3.0.1

---

## 目录

- [接口概览](#接口概览)
- [认证接口](#认证接口)
- [电缆裁切参数](#电缆裁切参数)
- [线边库存管理](#线边库存管理)
- [工单管理](#工单管理)
- [工单拣货验证](#工单拣货验证)
- [工单视图查询](#工单视图查询)
- [数据模型](#数据模型)

---

## 接口概览

**基础 URL**: `http://svcn5mesp01:8001`

### API 分类

| 分类              | 说明             |
| ----------------- | ---------------- |
| Auth              | 用户认证         |
| CableCutParam     | 电缆裁切参数管理 |
| LineStock         | 线边库存管理     |
| WorkOrder         | 工单报工         |
| WorkOrderPickVerf | 工单拣货验证     |
| WorkOrderView     | 工单视图查询     |

---

## 认证接口

### 用户登录

**接口地址**: `/api/Auth/Login`  
**请求方法**: `POST`  
**接口说明**: 用户身份验证接口

#### 请求参数

**Content-Type**: `application/json`

**请求体** (LoginDto):

```json
{
  "userName": "string",
  "password": "string"
}
```

| 参数     | 类型   | 必填 | 说明   |
| -------- | ------ | ---- | ------ |
| userName | string | 是   | 用户名 |
| password | string | 是   | 密码   |

#### 响应示例

**成功响应** (200 OK):

```json
{
  "isSuccess": true,
  "message": "string",
  "data": {
    "id": 0,
    "employeeId": "string",
    "domainAccount": "string",
    "userName": "string",
    "factoryName": "string",
    "isActive": true,
    "isDelete": false,
    "createdAt": "2025-10-27T00:00:00Z"
  }
}
```

---

## 电缆裁切参数

### 根据物料编码批量查询裁切参数

**接口地址**: `/api/CableCutParam/byMaterialCodes`  
**请求方法**: `POST`  
**接口说明**: 根据半成品物料编码批量获取电缆裁切参数

#### 请求参数

**Content-Type**: `application/json`

**请求体** (CableCutParamRequest):

```json
{
  "semiMaterialCode": ["string"]
}
```

| 参数             | 类型          | 必填 | 说明               |
| ---------------- | ------------- | ---- | ------------------ |
| semiMaterialCode | array[string] | 是   | 半成品物料编码列表 |

#### 响应示例

**成功响应** (200 OK):

```json
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
      "bomLength": 0.0,
      "upTol": 0.0,
      "downTol": 0.0,
      "alphaFactor": 0.0,
      "betaFactor": 0.0,
      "cuttingLength": 0.0,
      "cuttingTime": 0.0,
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
```

---

## 线边库存管理

### 1. 根据条码查询库存

**接口地址**: `/api/LineStock/byBarcode`  
**请求方法**: `GET`  
**接口说明**: 通过条码和工厂 ID 查询线边库存信息

#### 请求参数

**Query 参数**:

| 参数      | 类型    | 必填 | 说明    |
| --------- | ------- | ---- | ------- |
| factoryid | integer | 是   | 工厂 ID |
| barcode   | string  | 是   | 条码    |

#### 响应示例

**成功响应** (200 OK):

```json
{
  "isSuccess": true,
  "message": "string",
  "data": {}
}
```

---

### 2. 库存转移

**接口地址**: `/api/LineStock/transfer`  
**请求方法**: `POST`  
**接口说明**: 线边库存位置转移

#### 请求参数

**Content-Type**: `application/json`

**请求体** (TransferStockRequest):

```json
{
  "locationCode": "string",
  "barCodes": ["string"]
}
```

| 参数         | 类型          | 必填 | 说明         |
| ------------ | ------------- | ---- | ------------ |
| locationCode | string        | 是   | 目标库位编码 |
| barCodes     | array[string] | 是   | 条码列表     |

#### 响应示例

**成功响应** (200 OK):

```json
{
  "isSuccess": true,
  "message": "string",
  "data": true
}
```

---

### 3. 转移至 SAP

**接口地址**: `/api/LineStock/transferToSAP`  
**请求方法**: `POST`  
**接口说明**: 将库存信息转移至 SAP 系统

#### 请求参数

**Content-Type**: `application/json`

**请求体** (TransferSapRequest):

```json
{
  "factoryCode": "string",
  "employeeId": "string",
  "stockId": 0,
  "materialCode": "string",
  "quantity": 0.0,
  "baseUnit": "string",
  "batchCode": "string",
  "fromLocation": "string",
  "toLocation": "string"
}
```

| 参数         | 类型    | 必填 | 说明     |
| ------------ | ------- | ---- | -------- |
| factoryCode  | string  | 否   | 工厂编码 |
| employeeId   | string  | 否   | 员工 ID  |
| stockId      | integer | 否   | 库存 ID  |
| materialCode | string  | 否   | 物料编码 |
| quantity     | number  | 是   | 数量     |
| baseUnit     | string  | 否   | 基本单位 |
| batchCode    | string  | 否   | 批次号   |
| fromLocation | string  | 否   | 源库位   |
| toLocation   | string  | 否   | 目标库位 |

#### 响应示例

**成功响应** (200 OK):

```json
{
  "isSuccess": true,
  "message": "string",
  "data": true
}
```

---

### 4. 退回 WMS

**接口地址**: `/api/LineStock/returnToWMS`  
**请求方法**: `POST`  
**接口说明**: 将库存退回至仓储管理系统(WMS)

#### 响应示例

**成功响应** (200 OK):

```json
{
  "isSuccess": true,
  "message": "string",
  "data": true
}
```

---

## 工单管理

### 工单报工至 SAP

**接口地址**: `/api/WorkOrder/ReportToSAP`  
**请求方法**: `POST`  
**接口说明**: 将工单生产数据报工至 SAP 系统

#### 请求参数

**Content-Type**: `application/json`

**请求体** (WorkOrderReportRequest):

```json
{
  "factoryCode": "string",
  "processId": 0,
  "employeeId": "string",
  "confirmId": 0
}
```

| 参数        | 类型    | 必填 | 说明     |
| ----------- | ------- | ---- | -------- |
| factoryCode | string  | 否   | 工厂编码 |
| processId   | integer | 是   | 工序 ID  |
| employeeId  | string  | 否   | 员工 ID  |
| confirmId   | integer | 否   | 确认 ID  |

#### 响应示例

**成功响应** (200 OK):

```json
{
  "isSuccess": true,
  "message": "string",
  "data": "string"
}
```

---

## 工单拣货验证

### 1. 查询工单拣货信息

**接口地址**: `/api/WorkOrderPickVerf`  
**请求方法**: `GET`  
**接口说明**: 根据工单号查询拣货验证信息

#### 请求参数

**Query 参数**:

| 参数    | 类型   | 必填 | 说明   |
| ------- | ------ | ---- | ------ |
| orderno | string | 否   | 工单号 |

#### 响应示例

**成功响应** (200 OK):

```json
{
  "isSuccess": true,
  "message": "string",
  "data": {}
}
```

---

### 2. 更新工单工序信息

**接口地址**: `/api/WorkOrderPickVerf`  
**请求方法**: `PUT`  
**接口说明**: 更新工单工序状态和时间信息

#### 请求参数

**Query 参数**:

| 参数         | 类型   | 必填 | 说明     |
| ------------ | ------ | ---- | -------- |
| LocationCode | string | 否   | 库位编码 |

**Content-Type**: `application/json`

**请求体** (WorkOrderProcessUpdateDto):

```json
{
  "id": 0,
  "workOrderId": 0,
  "workOrderNo": "string",
  "operation": "string",
  "status": "string",
  "actStartTime": "2025-10-27T00:00:00Z",
  "actEndTime": "2025-10-27T00:00:00Z",
  "workCenter": "string",
  "processCardPrintCount": 0,
  "updateOn": "2025-10-27T00:00:00Z",
  "updateBy": "string"
}
```

| 参数                  | 类型     | 必填 | 说明           |
| --------------------- | -------- | ---- | -------------- |
| id                    | integer  | 是   | 记录 ID        |
| workOrderId           | integer  | 否   | 工单 ID        |
| workOrderNo           | string   | 否   | 工单号         |
| operation             | string   | 否   | 工序           |
| status                | string   | 否   | 状态           |
| actStartTime          | datetime | 否   | 实际开始时间   |
| actEndTime            | datetime | 否   | 实际结束时间   |
| workCenter            | string   | 否   | 工作中心       |
| processCardPrintCount | integer  | 否   | 工序卡打印次数 |
| updateOn              | datetime | 否   | 更新时间       |
| updateBy              | string   | 否   | 更新人         |

#### 响应示例

**成功响应** (200 OK):

```json
{
  "isSuccess": true,
  "message": "string",
  "data": true
}
```

---

## 工单视图查询

### 1. 按派工日期查询工单

**接口地址**: `/api/WorkOrderView/byDispatchDate`  
**请求方法**: `GET`  
**接口说明**: 根据工厂编码和派工日期查询工单信息

#### 请求参数

**Query 参数**:

| 参数         | 类型   | 必填 | 说明     |
| ------------ | ------ | ---- | -------- |
| factoryCode  | string | 否   | 工厂编码 |
| dispatchDate | string | 否   | 派工日期 |

#### 响应示例

**成功响应** (200 OK):

```json
{
  "isSuccess": true,
  "message": "string",
  "data": {
    "sapOrderOperations": [],
    "sapOrderBoms": []
  }
}
```

---

### 2. 按工单号批量查询

**接口地址**: `/api/WorkOrderView/byOrderNos`  
**请求方法**: `POST`  
**接口说明**: 根据工单号列表批量查询工单详细信息

#### 请求参数

**Content-Type**: `application/json`

**请求体** (SapOrderRequest):

```json
{
  "factoryCode": "string",
  "dispatchDate": "2025-10-27T00:00:00Z",
  "orderNos": ["string"]
}
```

| 参数         | 类型          | 必填 | 说明       |
| ------------ | ------------- | ---- | ---------- |
| factoryCode  | string        | 否   | 工厂编码   |
| dispatchDate | datetime      | 否   | 派工日期   |
| orderNos     | array[string] | 否   | 工单号列表 |

#### 响应示例

**成功响应** (200 OK):

```json
{
  "isSuccess": true,
  "message": "string",
  "data": {
    "sapOrderOperations": [
      {
        "id": 0,
        "orderNo": "string",
        "counter": 0,
        "plantCode": "string",
        "dispatchDate": "string",
        "workCenter": "string",
        "operationNo": "string",
        "materialCode": "string",
        "targetQuantity": 0.0,
        "productFinish": "string",
        "productStart": "string",
        "finishDate": "string",
        "startDate": "string",
        "plannerRemark": "string",
        "orderStatus": "string",
        "operationStatus": "string",
        "mesStatus": "string"
      }
    ],
    "sapOrderBoms": [
      {
        "id": 0,
        "orderNo": "string",
        "reservationNo": 0,
        "reservationItem": 0,
        "materialCode": "string",
        "materialDesc": "string",
        "requireQuantity": 0.0,
        "baseUnit": "string",
        "requireDate": "string",
        "withdrawnQuantity": 0.0,
        "bomItem": "string",
        "operation": "string"
      }
    ]
  }
}
```

---

## 数据模型

### 通用响应模型

所有 API 响应均遵循统一的响应结构：

```json
{
  "isSuccess": boolean,
  "message": "string",
  "data": {}
}
```

| 字段      | 类型    | 说明         |
| --------- | ------- | ------------ |
| isSuccess | boolean | 请求是否成功 |
| message   | string  | 响应消息     |
| data      | object  | 响应数据     |

---

### UserDto - 用户信息

```json
{
  "id": 0,
  "employeeId": "string",
  "domainAccount": "string",
  "userName": "string",
  "factoryName": "string",
  "isActive": true,
  "isDelete": false,
  "createdAt": "2025-10-27T00:00:00Z"
}
```

| 字段          | 类型     | 说明     |
| ------------- | -------- | -------- |
| id            | integer  | 用户 ID  |
| employeeId    | string   | 员工编号 |
| domainAccount | string   | 域账号   |
| userName      | string   | 用户名   |
| factoryName   | string   | 工厂名称 |
| isActive      | boolean  | 是否激活 |
| isDelete      | boolean  | 是否删除 |
| createdAt     | datetime | 创建时间 |

---

### CableCutParamCreateDto - 电缆裁切参数

| 字段              | 类型    | 说明           |
| ----------------- | ------- | -------------- |
| cuttoLeranceId    | integer | 裁切公差 ID    |
| semiMaterialCode  | string  | 半成品物料编码 |
| cableMaterialCode | string  | 电缆物料编码   |
| cableType         | string  | 电缆类型       |
| drawingCode       | string  | 图纸编码       |
| positionItem      | string  | 位置项目       |
| cablePcs          | integer | 电缆数量       |
| postionNo         | string  | 位置编号       |
| bomLength         | number  | BOM 长度       |
| upTol             | number  | 上公差         |
| downTol           | number  | 下公差         |
| alphaFactor       | number  | Alpha 因子     |
| betaFactor        | number  | Beta 因子      |
| cuttingLength     | number  | 裁切长度       |
| cuttingTime       | number  | 裁切时间       |
| reelCode          | string  | 料盘编码       |
| remark            | string  | 备注           |
| status            | string  | 状态           |
| createDate        | string  | 创建日期       |
| createTime        | string  | 创建时间       |
| createBy          | string  | 创建人         |
| updateDate        | string  | 更新日期       |
| updateTime        | string  | 更新时间       |
| updateBy          | string  | 更新人         |

---

### SapOrderOperation - SAP 工单工序

| 字段            | 类型    | 说明         |
| --------------- | ------- | ------------ |
| id              | integer | 记录 ID      |
| orderNo         | string  | 工单号       |
| counter         | integer | 计数器       |
| plantCode       | string  | 工厂编码     |
| dispatchDate    | string  | 派工日期     |
| workCenter      | string  | 工作中心     |
| operationNo     | string  | 工序号       |
| materialCode    | string  | 物料编码     |
| targetQuantity  | number  | 目标数量     |
| productFinish   | string  | 生产完成     |
| productStart    | string  | 生产开始     |
| finishDate      | string  | 完成日期     |
| startDate       | string  | 开始日期     |
| plannerRemark   | string  | 计划员备注   |
| collectiveOrder | string  | 集合订单     |
| superiorOrder   | string  | 上级订单     |
| leadingOrder    | string  | 主导订单     |
| confirmNo       | integer | 确认号       |
| reservationNo   | integer | 预留号       |
| orderStatus     | string  | 订单状态     |
| operationStatus | string  | 工序状态     |
| mesStatus       | string  | MES 状态     |
| transferStatus  | string  | 转移状态     |
| dispatchStatus  | string  | 派工状态     |
| controlKey      | string  | 控制码       |
| storageLocation | string  | 存储位置     |
| salesOrderNo    | string  | 销售订单号   |
| salesOrderItem  | integer | 销售订单项次 |
| stockType       | string  | 库存类型     |
| setupTime1      | number  | 准备时间 1   |
| setupTime2      | number  | 准备时间 2   |
| machineTime1    | number  | 机器时间 1   |
| machineTime2    | number  | 机器时间 2   |
| profitCenter    | string  | 利润中心     |
| labelCount      | integer | 标签数量     |

---

### SapOrderBom - SAP 工单 BOM

| 字段              | 类型    | 说明         |
| ----------------- | ------- | ------------ |
| id                | integer | 记录 ID      |
| orderNo           | string  | 工单号       |
| reservationNo     | integer | 预留号       |
| reservationItem   | integer | 预留项次     |
| reservationType   | string  | 预留类型     |
| materialCode      | string  | 物料编码     |
| materialDesc      | string  | 物料描述     |
| requireQuantity   | number  | 需求数量     |
| baseUnit          | string  | 基本单位     |
| requireDate       | string  | 需求日期     |
| withdrawnQuantity | number  | 已领数量     |
| fixIndicator      | string  | 固定标识     |
| componentScrap    | number  | 组件报废     |
| bomItem           | string  | BOM 项次     |
| operation         | string  | 工序         |
| factoryCode       | string  | 工厂编码     |
| transferStatus    | string  | 转移状态     |
| comletionStatus   | string  | 完成状态     |
| allowedMovement   | string  | 允许移动     |
| salesOrderNo      | string  | 销售订单号   |
| salesOrderItem    | integer | 销售订单项次 |
| superMaterialCode | string  | 上级物料编码 |
| consumeType       | integer | 消耗类型     |

---

## 错误码说明

| HTTP 状态码 | 说明           |
| ----------- | -------------- |
| 200         | 请求成功       |
| 400         | 请求参数错误   |
| 401         | 未授权         |
| 403         | 禁止访问       |
| 404         | 资源不存在     |
| 500         | 服务器内部错误 |

---

## 注意事项

1. **时间格式**: 所有时间字段采用 ISO 8601 格式：`YYYY-MM-DDTHH:mm:ssZ`
2. **编码**: 所有请求和响应均使用 UTF-8 编码
3. **Content-Type**: 请求头需设置为 `application/json`
4. **响应处理**: 请根据响应中的 `isSuccess` 字段判断请求是否成功，`message` 字段包含详细的错误或成功信息
5. **数值精度**: 数量、长度等数值字段使用 `double` 类型，注意精度处理

---

## 联系方式

如有问题，请联系技术支持团队。

**文档生成时间**: 2025-10-27  
**API 基础地址**: http://svcn5mesp01:8001
