# API 接口规范文档
## 拣配流程追溯与验证程序

### 文档概述
本文档定义了拣配验证应用程序所需的所有 API 接口规范，包括请求/响应格式、参数说明、错误处理等。本项目专注于**生产订单**的物料拣配流程追溯与验证，通过"合箱校验"、"平台收料"、"产线送料"三个关键节点实现生产物料的数字化管理。

在后端开发完成前，可使用本文档中的测试数据进行前端开发和用户测试。

**基础配置：**
- 基础URL：`https://api.example.com` (待定)
- 认证方式：Bearer Token (JWT)
- 数据格式：JSON
- 字符编码：UTF-8

---

## 1. 认证模块 (Authentication)

### 1.1 用户登录
**接口描述：** 验证用户身份并获取访问令牌

**HTTP 方法：** `POST`  
**接口路径：** `/auth/login`

**请求参数：**
```json
{
  "employee_id": "string",    // 员工ID，必填
  "password": "string"        // 密码，必填
}
```

**成功响应 (200)：**
```json
{
  "success": true,
  "message": "登录成功",
  "user": {
    "id": "user_12345",
    "employee_id": "EMP001",
    "name": "张三",
    "permissions": [
      "picking_verification",
      "platform_receiving",
      "line_delivery"
    ],
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**错误响应：**
- `400` - 请求参数错误
- `401` - 用户名或密码错误
- `403` - 账户已被禁用
- `500` - 服务器内部错误

**测试数据：**
- 管理员账户：`employee_id: "ADMIN001"`, `password: "admin123"`
- 操作员账户：`employee_id: "OPR001"`, `password: "operator123"`

---

### 1.2 用户登出
**接口描述：** 清除服务端会话状态

**HTTP 方法：** `POST`  
**接口路径：** `/auth/logout`  
**认证要求：** Bearer Token

**请求参数：** 无

**成功响应 (200)：**
```json
{
  "success": true,
  "message": "登出成功"
}
```

---

### 1.3 刷新Token
**接口描述：** 使用 refresh token 获取新的 access token

**HTTP 方法：** `POST`  
**接口路径：** `/auth/refresh`

**请求参数：**
```json
{
  "refresh_token": "string"
}
```

**成功响应 (200)：**
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": 3600
}
```

---

## 2. 生产订单任务模块 (Production Order Tasks)

### 2.1 获取分配的生产订单任务
**接口描述：** 获取当前用户分配的生产订单任务列表

**HTTP 方法：** `GET`  
**接口路径：** `/api/production-orders/tasks/assigned`  
**认证要求：** Bearer Token

**查询参数：**
- `stage`: string (可选) - 任务阶段筛选，可选值：`picking_verification`, `platform_receiving`, `line_delivery`
- `status`: string (可选) - 任务状态筛选，可选值：`pending`, `assigned`, `in_progress`, `completed`
- `priority`: int (可选) - 优先级筛选，1-高优先级，2-中优先级，3-低优先级
- `limit`: int (可选) - 返回数量限制，默认 50
- `offset`: int (可选) - 分页偏移量，默认 0

**成功响应 (200)：**
```json
{
  "tasks": [
    {
      "taskId": "po_task_001",
      "orderNumber": "PO-20240101-001",
      "taskType": "picking_verification",
      "status": "pending",
      "assignedTo": "EMP001",
      "priority": 1,
      "estimatedTime": 30,
      "actualTime": null,
      "createdAt": "2024-01-01T08:00:00Z",
      "assignedAt": "2024-01-01T08:00:00Z",
      "dueDate": "2024-01-01T10:00:00Z",
      "metadata": {
        "productNumber": "PCB_MODULE_V1.2",
        "assemblyLine": "LINE_A",
        "materialsCount": 15,
        "cuttingCount": 5,
        "centerWHCount": 8,
        "autoWHCount": 2,
        "batchNumber": "BATCH_2024001"
      }
    }
  ],
  "total": 25,
  "has_more": true,
  "next_page_token": "eyJvZmZzZXQiOjUwfQ=="
```

**物料状态说明：**
- `pending`: 待处理
- `in_progress`: 处理中
- `completed`: 已完成
- `error`: 异常
- `missing`: 缺失

**物料类别说明：**
- `line_break`: 断线物料
- `central_warehouse`: 中央仓物料
- `automated`: 自动化库物料

---

### 3.3 激活拣配验证模式
**接口描述：** 激活指定生产订单的拣配验证流程

**HTTP 方法：** `POST`  
**接口路径：** `/api/production-orders/{orderNumber}/picking/activate`  
**认证要求：** Bearer Token

**请求参数：** 无

**成功响应 (200)：**
```json
{
  "success": true,
  "message": "拣配验证模式已激活",
  "orderId": "po_001",
  "activatedAt": "2024-01-01T10:00:00Z"
}
```

---

### 3.4 验证拣配项目
**接口描述：** 更新指定物料项的验证状态

**HTTP 方法：** `PUT`  
**接口路径：** `/api/production-orders/{orderId}/items/{itemId}/verify`  
**认证要求：** Bearer Token

**请求参数：**
```json
{
  "isVerified": true,        // 验证状态
  "remarks": "string"        // 备注（可选）
}
```

**成功响应 (200)：**
```json
{
  "success": true,
  "message": "物料验证状态已更新",
  "itemId": "item_001",
  "isVerified": true,
  "updatedAt": "2024-01-01T10:30:00Z"
}
```

---

### 3.5 提交验证结果
**接口描述：** 提交完整的验证结果，支持重试机制

**HTTP 方法：** `POST`  
**接口路径：** `/api/production-orders/{orderId}/verification/submit`  
**认证要求：** Bearer Token

**请求头：**
```
Content-Type: application/json
X-Submission-ID: {唯一提交ID}
X-Request-Attempt: {重试次数}
X-Operator-ID: {操作员ID}
```

**请求参数：**
```json
{
  "submissionId": "sub_20240101_001",
  "orderId": "po_001",
  "operatorId": "EMP001",
  "verificationItems": [
    {
      "itemId": "item_001",
      "isVerified": true,
      "verifiedAt": "2024-01-01T10:30:00Z",
      "remarks": null
    }
  ],
  "allItemsVerified": true,
  "submittedAt": "2024-01-01T11:00:00Z",
  "notes": "所有物料验证完成"
}
```

**成功响应 (200/201)：**
```json
{
  "success": true,
  "message": "验证结果提交成功",
  "submissionId": "sub_20240101_001",
  "orderId": "po_001",
  "processedAt": "2024-01-01T11:00:00Z",
  "orderStatus": "verification_completed",
  "data": {
    "nextStage": "platform_receiving",
    "estimatedCompletionTime": "2024-01-01T12:00:00Z"
  }
}
```

**错误响应：**
- `400` - 请求参数错误
- `409` - 生产订单状态冲突
- `422` - 数据验证失败
- `429` - 请求过于频繁

---

### 3.6 完成订单验证
**接口描述：** 标记整个生产订单的验证流程完成

**HTTP 方法：** `POST`  
**接口路径：** `/api/production-orders/{orderId}/picking/complete`  
**认证要求：** Bearer Token

**成功响应 (200)：**
```json
{
  "success": true,
  "message": "生产订单验证完成",
  "orderId": "po_001",
  "completedAt": "2024-01-01T11:00:00Z",
  "nextStage": "platform_receiving"
}
```

---

## 4. 生产订单验证模块 (Production Order Verification)

### 4.1 验证生产订单（扫码验证）
**接口描述：** 验证扫描的生产订单号与任务是否匹配

**HTTP 方法：** `POST`  
**接口路径：** `/api/production-orders/verify`  
**认证要求：** Bearer Token

**请求参数：**
```json
{
  "scannedOrderId": "PO-20240101-001",
  "expectedOrderId": "PO-20240101-001",
  "taskId": "po_task_001"
}
```

**成功响应 (200)：**
```json
{
  "orderId": "PO-20240101-001",
  "isValid": true,
  "errorMessage": null,
  "verifiedAt": "2024-01-01T10:00:00Z",
  "orderDetails": {
    "productModel": "PCB_MODULE_V1.2",
    "materialsCount": 12,
    "status": "ready_for_verification",
    "productionLine": "LINE_A",
    "batchNumber": "BATCH_2024001"
  }
}
```

**验证失败响应：**
```json
{
  "orderId": "PO-20240101-002",
  "isValid": false,
  "errorMessage": "生产订单号不匹配，请重新扫描",
  "verifiedAt": "2024-01-01T10:00:00Z"
}
```

---

## 5. 平台收料模块 (Platform Receiving)

### 5.1 验证收料前置条件
**接口描述：** 验证生产订单是否已完成合箱校验，可进入平台收料流程

**HTTP 方法：** `GET`  
**接口路径：** `/api/production-orders/{orderNumber}/platform-receiving/check`  
**认证要求：** Bearer Token

**成功响应 (200)：**
```json
{
  "orderId": "po_001",
  "orderNumber": "PO-20240101-001",
  "canReceive": true,
  "pickingVerificationCompleted": true,
  "pickingCompletedAt": "2024-01-01T11:00:00Z",
  "readyForReceiving": true
}
```

**前置条件不满足响应：**
```json
{
  "orderId": "po_001",
  "orderNumber": "PO-20240101-001",
  "canReceive": false,
  "pickingVerificationCompleted": false,
  "errorMessage": "生产订单尚未完成合箱校验",
  "requiredSteps": ["complete_picking_verification"]
}
```

---

### 5.2 提交收料确认
**接口描述：** 提交平台收料确认，更新生产订单位置状态

**HTTP 方法：** `POST`  
**接口路径：** `/api/production-orders/{orderNumber}/platform-receiving/confirm`  
**认证要求：** Bearer Token

**请求参数：**
```json
{
  "receiverId": "EMP001",
  "receivedAt": "2024-01-01T12:00:00Z",
  "platformLocation": "PLATFORM_A",
  "notes": "物料已收到，状态良好"
}
```

**成功响应 (200)：**
```json
{
  "success": true,
  "message": "平台收料确认成功",
  "orderId": "po_001",
  "status": "received_at_platform",
  "receivedAt": "2024-01-01T12:00:00Z",
  "platformLocation": "PLATFORM_A",
  "nextStage": "line_delivery"
}
```

---

## 6. 产线送料模块 (Line Delivery)

### 6.1 验证产线位置
**接口描述：** 验证扫描的生产线位置二维码

**HTTP 方法：** `POST`  
**接口路径：** `/api/production-lines/verify`  
**认证要求：** Bearer Token

**请求参数：**
```json
{
  "scannedLocationCode": "LINE_A_001",
  "orderId": "po_001"
}
```

**成功响应 (200)：**
```json
{
  "locationCode": "LINE_A_001",
  "isValid": true,
  "locationName": "生产线A工位1",
  "isOperational": true,
  "canReceiveOrders": true
}
```

---

### 6.2 提交送料确认
**接口描述：** 提交产线送料确认，完成整个流程闭环

**HTTP 方法：** `POST`  
**接口路径：** `/api/production-orders/{orderNumber}/line-delivery/confirm`  
**认证要求：** Bearer Token

**请求参数：**
```json
{
  "deliveryPersonId": "EMP001",
  "productionLineCode": "LINE_A_001",
  "deliveredAt": "2024-01-01T13:00:00Z",
  "receivedByLineOperator": "LINE_OPR_A01",
  "notes": "物料已送达生产线，交接完成"
}
```

**成功响应 (200)：**
```json
{
  "success": true,
  "message": "产线送料确认成功",
  "orderId": "po_001",
  "status": "delivered_to_line",
  "deliveredAt": "2024-01-01T13:00:00Z",
  "productionLineCode": "LINE_A_001",
  "workflowCompleted": true
}
```

---

## 7. 错误处理

### 7.1 标准错误响应格式
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "人类可读的错误消息",
    "details": {
      "field": "具体字段错误信息"
    }
  },
  "timestamp": "2024-01-01T10:00:00Z",
  "requestId": "req_12345"
}
```

### 7.2 常见错误码
- `AUTH_REQUIRED`: 需要认证
- `AUTH_INVALID`: 认证信息无效
- `PERMISSION_DENIED`: 权限不足
- `RESOURCE_NOT_FOUND`: 资源不存在
- `VALIDATION_ERROR`: 参数验证错误
- `CONFLICT`: 资源状态冲突
- `RATE_LIMIT_EXCEEDED`: 请求过于频繁
- `INTERNAL_ERROR`: 服务器内部错误

### 7.3 HTTP状态码说明
- `200`: 请求成功
- `201`: 资源创建成功
- `400`: 请求参数错误
- `401`: 未认证
- `403`: 权限不足
- `404`: 资源不存在
- `409`: 资源冲突
- `422`: 数据验证失败
- `429`: 请求过于频繁
- `500`: 服务器内部错误
- `502`: 网关错误
- `503`: 服务不可用
- `504`: 网关超时

---

## 8. 测试数据集

### 8.1 测试用户账户
```json
[
  {
    "employee_id": "ADMIN001",
    "password": "admin123",
    "name": "系统管理员",
    "permissions": ["picking_verification", "platform_receiving", "line_delivery", "admin"]
  },
  {
    "employee_id": "OPR001",
    "password": "operator123",
    "name": "操作员张三",
    "permissions": ["picking_verification", "platform_receiving"]
  },
  {
    "employee_id": "OPR002",
    "password": "operator456",
    "name": "操作员李四",
    "permissions": ["picking_verification", "line_delivery"]
  }
]
```

### 8.2 测试生产订单数据
```json
[
  {
    "orderNumber": "PO-20240101-001",
    "productModel": "PCB_MODULE_V1.2",
    "productionLine": "LINE_A",
    "status": "picking_completed",
    "materialsCount": 3,
    "priority": 1,
    "batchNumber": "BATCH_2024001"
  },
  {
    "orderNumber": "PO-20240101-002", 
    "productModel": "SENSOR_MODULE_V2.1",
    "productionLine": "LINE_B",
    "status": "pending",
    "materialsCount": 5,
    "priority": 2,
    "batchNumber": "BATCH_2024002"
  },
  {
    "orderNumber": "PO-20240101-003",
    "productModel": "CONTROLLER_UNIT_V3.0",
    "productionLine": "LINE_C",
    "status": "verification_completed",
    "materialsCount": 8,
    "priority": 1,
    "batchNumber": "BATCH_2024003"
  }
]
```

### 8.3 生产线位置码
- `LINE_A_001`: 生产线A工位1
- `LINE_A_002`: 生产线A工位2  
- `LINE_B_001`: 生产线B工位1
- `LINE_B_002`: 生产线B工位2
- `LINE_C_001`: 生产线C工位1

---

## 9. 开发注意事项

### 9.1 认证Token处理
- Token 有效期为 1 小时
- 需要实现自动刷新机制
- Token 过期时需要重新登录

### 9.2 网络异常处理
- 实现重试机制（最多3次）
- 超时时间：连接超时10秒，接收超时10秒
- 网络不可用时提供离线提示

### 9.3 数据缓存策略
- 任务列表可缓存5分钟
- 生产订单详情可缓存10分钟
- 认证信息安全存储，不允许明文缓存

### 9.4 用户体验优化
- 长时间操作显示加载状态
- 网络请求失败时提供重试选项
- 关键操作需要用户确认

---

## 10. API接口变更记录

| 版本 | 日期 | 变更内容 | 负责人 |
|------|------|----------|--------|
| 1.0 | 2024-01-01 | 初始版本，定义所有核心接口 | API开发团队 |
| 1.1 | 2024-01-01 | 修正为生产订单场景，更新所有接口路径和测试数据 | API开发团队 |

---

**文档维护：** 此文档应与后端API开发同步更新，确保接口规范的一致性。