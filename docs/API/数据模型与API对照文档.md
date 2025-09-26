# 数据模型与API对照文档
## 拣配流程追溯与验证程序

### 文档概述
本文档提供数据模型与API接口的完整对照关系，确保前端开发、后端开发和数据库设计的一致性。基于 `docs/DataModel.md` 和 `docs/完整数据模型设计.md` 中定义的数据结构。

---

## 1. 生产订单相关API与数据模型对照

### 1.1 获取分配的生产订单任务
**API路径：** `GET /api/production-orders/tasks/assigned`

**数据来源：** `productionOrderTaskTable` + `productionOrderTable`

**响应数据映射：**
```json
{
  // 来自 productionOrderTaskTable
  "taskId": "taskId",
  "taskType": "taskType",
  "status": "status", 
  "assignedTo": "assignedTo",
  "priority": "priority",
  "estimatedTime": "estimatedTime",
  "actualTime": "actualTime",
  "createdAt": "createdAt",
  "assignedAt": "assignedAt", 
  "dueDate": "dueDate",
  
  // 来自 productionOrderTable (通过 orderNumber 关联)
  "orderNumber": "orderNumber",
  "metadata": {
    "productNumber": "productNumber",
    "productDesc": "productDesc",
    "assemblyLine": "assemblyLine",
    "materialsCount": "materialsCount",
    "cuttingCount": "cuttingCount", 
    "centerWHCount": "centerWHCount",
    "autoWHCount": "autoWHCount",
    "batchNumber": "batchNumber",
    "targetQuantity": "targetQuantity"
  }
}
```

---

### 1.2 获取生产订单拣配详情
**API路径：** `GET /api/production-orders/{orderNumber}/picking`

**数据来源：** `productionOrderTable`

**响应数据映射：**
```json
{
  // 直接映射 productionOrderTable 核心字段
  "orderNumber": "orderNumber",
  "productNumber": "productNumber", 
  "productDesc": "productDesc",
  "finalOrdNumber": "finalOrdNumber",
  "finalProduct": "finalProduct",
  "finalPONumber": "finalPONumber",
  "finalProDesc": "finalProDesc", 
  "assemblyLine": "assemblyLine",
  "status": "status",
  "materialsCount": "materialsCount",
  "cuttingCount": "cuttingCount",
  "centerWHCount": "centerWHCount", 
  "autoWHCount": "autoWHCount",
  "labelCount": "labelCount",
  "remark": "remark",
  "priority": "priority",
  
  // 时间戳字段
  "createdAt": "createdAt",
  "updatedAt": "updatedAt",
  "scheduledStartTime": "scheduledStartTime",
  
  // 各阶段时间记录
  "pickingStartedAt": "pickingStartedAt",
  "pickingCompletedAt": "pickingCompletedAt", 
  "verificationStartedAt": "verificationStartedAt",
  "verificationCompletedAt": "verificationCompletedAt",
  "platformReceivingStartedAt": "platformReceivingStartedAt",
  "platformReceivingCompletedAt": "platformReceivingCompletedAt",
  "lineDeliveryStartedAt": "lineDeliveryStartedAt", 
  "lineDeliveryCompletedAt": "lineDeliveryCompletedAt",
  
  // 简化的生产字段
  "batchNumber": "batchNumber",
  "orderQuantity": "orderQuantity",
  
  // 状态标记
  "isPickingVerified": "isPickingVerified",
  "isPlatformReceived": "isPlatformReceived",
  "isLineDelivered": "isLineDelivered"
}
```

---

### 1.3 获取生产订单物料详情
**API路径：** `GET /api/production-orders/{orderNumber}/materials`

**数据来源：** `productionBOMTable`

**响应数据映射：**
```json
{
  "orderNumber": "orderNumber", // 来自查询参数
  "materials": [
    {
      // 直接映射 productionBOMTable 字段
      "id": "id",
      "orderNumber": "orderNumber",
      "code": "rawMaterial",               // 原始字段名映射
      "name": "rawMatDesc",                // 原始字段名映射
      "category": "category", 
      "required_quantity": "quantity",     // 原始字段名映射
      "available_quantity": "pickQty",     // 原始字段名映射
      "status": "pickStatus",              // 原始字段名映射
      "remarks": "remark",                 // 原始字段名映射
      
      // 保留的字段
      "unit": "unit",                      // 计量单位
      "batchNumber": "batchNumber",        // 物料批次号
      "location": "storageLocation",       // 仓储位置
      
      // 验证相关字段
      "isVerified": "isVerified",          
      "verifiedAt": "verifiedAt",         
      "verifiedBy": "verifiedBy",         
      "verificationRemarks": "verificationRemarks",
      
      // 时间戳
      "createdAt": "createdAt",           
      "updatedAt": "updatedAt"            
    }
  ]
}
```

---

## 2. 任务管理相关API与数据模型对照

### 2.1 更新生产订单任务状态
**API路径：** `POST /api/production-orders/tasks/{taskId}/status`

**数据目标：** `productionOrderTaskTable`

**请求数据映射：**
```json
{
  "status": "status",           // 更新 productionOrderTaskTable.status
  "stage": "taskType",          // 验证 productionOrderTaskTable.taskType
  "operator_notes": "operatorNotes" // 更新 productionOrderTaskTable.operatorNotes
}
```

**同时更新字段：**
- `updatedAt`: 当前时间戳
- `startedAt`: 如果状态变为 `in_progress`
- `completedAt`: 如果状态变为 `completed`

---

## 3. 拣配验证相关API与数据模型对照

### 3.1 激活拣配验证模式
**API路径：** `POST /api/production-orders/{orderNumber}/picking/activate`

**数据目标：** `productionOrderTable`

**更新操作：**
- 更新 `status` 为 `verification_in_progress`
- 更新 `updatedAt` 为当前时间戳
- 可选：更新 `actualStartTime` 为当前时间戳

---

### 3.2 验证拣配项目
**API路径：** `PUT /api/production-orders/{orderId}/items/{itemId}/verify`

**数据目标：** `productionBOMTable`

**请求数据映射：**
```json
{
  "isVerified": "isVerified",   // 更新 productionBOMTable.isVerified
  "remarks": "verificationRemarks" // 更新 productionBOMTable.verificationRemarks
}
```

**同时更新字段：**
- `verifiedAt`: 当前时间戳
- `verifiedBy`: 当前操作员ID
- `updatedAt`: 当前时间戳

---

### 3.3 提交验证结果
**API路径：** `POST /api/production-orders/{orderId}/verification/submit`

**数据目标：** `verificationRecordTable` + `productionOrderTable`

**请求数据映射到 verificationRecordTable：**
```json
{
  "recordId": "生成UUID",              // 新记录ID
  "orderNumber": "从URL获取",          // 生产订单号
  "taskId": "从任务上下文获取",         // 关联任务ID
  "verificationType": "picking_verification", // 固定值
  "operatorId": "operatorId",         // 来自请求
  "verificationItems": "verificationItems", // JSON存储
  "allItemsVerified": "allItemsVerified",
  "submissionId": "submissionId",
  "submissionStatus": "success/failed", // 根据处理结果
  "notes": "notes",
  "startedAt": "计算得出",              // 最早验证项时间
  "completedAt": "当前时间戳", 
  "submittedAt": "submittedAt"
}
```

**同时更新 productionOrderTable：**
- `status`: `verification_completed`
- `isPickingVerified`: `true`
- `updatedAt`: 当前时间戳

---

## 4. 平台收料相关API与数据模型对照

### 4.1 验证收料前置条件
**API路径：** `GET /api/production-orders/{orderNumber}/platform-receiving/check`

**数据来源：** `productionOrderTable`

**检查逻辑：**
```sql
SELECT 
  orderNumber,
  status,
  isPickingVerified,
  CASE 
    WHEN isPickingVerified = true AND status = 'verification_completed' 
    THEN true 
    ELSE false 
  END as canReceive
FROM productionOrderTable 
WHERE orderNumber = ?
```

---

### 4.2 提交收料确认
**API路径：** `POST /api/production-orders/{orderNumber}/platform-receiving/confirm`

**数据目标：** `materialMovementTable` + `productionOrderTable`

**创建 materialMovementTable 记录：**
```json
{
  "movementId": "生成UUID",
  "orderNumber": "从URL获取",
  "materialId": "所有物料项",          // 批量创建记录
  "movementType": "verification_to_platform",
  "fromLocation": "verification_area",
  "toLocation": "platformLocation",   // 来自请求
  "currentLocation": "platformLocation",
  "operatorId": "receiverId",         // 来自请求
  "operationTime": "receivedAt",      // 来自请求
  "quantity": "从BOM表获取",
  "status": "completed",
  "notes": "notes",                   // 来自请求
  "createdAt": "当前时间戳",
  "updatedAt": "当前时间戳"
}
```

**更新 productionOrderTable：**
- `status`: `platform_received` 
- `isPlatformReceived`: `true`
- `updatedAt`: 当前时间戳

---

## 5. 产线送料相关API与数据模型对照

### 5.1 验证产线位置
**API路径：** `POST /api/production-lines/verify`

**数据来源：** 系统配置或产线位置表（需补充）

**建议补充数据表：**
```sql
CREATE TABLE productionLineLocationTable (
  locationCode string PRIMARY KEY,
  locationName string,
  assemblyLine string,
  isOperational boolean,
  canReceiveOrders boolean,
  createdAt datetime,
  updatedAt datetime
);
```

---

### 5.2 提交送料确认
**API路径：** `POST /api/production-orders/{orderNumber}/line-delivery/confirm`

**数据目标：** `materialMovementTable` + `productionOrderTable`

**创建 materialMovementTable 记录：**
```json
{
  "movementId": "生成UUID",
  "orderNumber": "从URL获取",
  "materialId": "所有物料项",          // 批量创建记录
  "movementType": "platform_to_line",
  "fromLocation": "platform_area",
  "toLocation": "productionLineCode", // 来自请求
  "currentLocation": "productionLineCode",
  "operatorId": "deliveryPersonId",   // 来自请求
  "operationTime": "deliveredAt",     // 来自请求
  "quantity": "从BOM表获取",
  "scanLocation": "productionLineCode",
  "status": "completed",
  "notes": "notes",                   // 来自请求
  "createdAt": "当前时间戳",
  "updatedAt": "当前时间戳"
}
```

**更新 productionOrderTable：**
- `status`: `completed`
- `isLineDelivered`: `true` 
- `updatedAt`: 当前时间戳

---

## 6. 用户认证相关API与数据模型对照

### 6.1 用户登录
**API路径：** `POST /auth/login`

**数据来源：** `userTable`

**验证逻辑：**
```sql
SELECT userId, employeeId, name, permissions, roles, status
FROM userTable 
WHERE employeeId = ? AND status = 'active'
```

**响应数据映射：**
```json
{
  "user": {
    "id": "userId",
    "employee_id": "employeeId", 
    "name": "name",
    "permissions": "permissions", // JSON数组
    "token": "生成JWT Token"
  }
}
```

**同时更新：**
- `lastLoginAt`: 当前时间戳

---

## 7. 系统日志记录

### 7.1 操作日志记录
**触发时机：** 所有API调用

**数据目标：** `operationLogTable`

**记录内容：**
```json
{
  "logId": "生成UUID",
  "userId": "从Token解析",
  "orderNumber": "从请求URL或Body获取", 
  "operation": "API路径",
  "operationDetails": "请求参数JSON",
  "deviceId": "从请求头获取",
  "deviceType": "PDA", 
  "appVersion": "从请求头获取",
  "ipAddress": "客户端IP",
  "requestId": "请求追踪ID",
  "success": "响应状态",
  "errorMessage": "错误信息（如有）",
  "executionTime": "API执行时间", 
  "timestamp": "当前时间戳"
}
```

---

## 8. 数据一致性检查清单

### 8.1 API开发检查清单
- [ ] API响应字段与数据表字段完全对应
- [ ] 枚举值与数据模型定义一致
- [ ] 时间戳字段使用ISO 8601格式
- [ ] 外键关联正确处理
- [ ] 批量操作正确处理事务
- [ ] 状态变更遵循业务流程
- [ ] 操作日志正确记录

### 8.2 前端开发检查清单  
- [ ] 接口请求参数与数据模型匹配
- [ ] 响应数据解析正确
- [ ] 枚举值显示文案正确
- [ ] 时间格式本地化处理
- [ ] 错误处理覆盖所有业务场景
- [ ] 数据验证规则与后端一致

### 8.3 测试数据检查清单
- [ ] 测试数据符合数据模型约束
- [ ] 外键关联数据完整
- [ ] 枚举值在有效范围内
- [ ] 时间戳数据逻辑合理
- [ ] 边界条件数据覆盖完整

---

## 9. 常见问题与解决方案

### 9.1 字段名映射问题
**问题：** 原始数据模型中的字段名与API设计不一致

**解决方案：**
- API层使用标准化命名（如：`rawMaterial` → `materialCode`）
- 数据访问层进行字段名映射
- 文档明确标注映射关系

### 9.2 数据类型转换问题
**问题：** 数据库存储类型与API传输类型不匹配

**解决方案：**
- 明确定义每个字段的数据类型
- API层进行类型转换
- 前端进行数据格式验证

### 9.3 枚举值同步问题
**问题：** 枚举值在不同层次定义不一致

**解决方案：**
- 建立统一的枚举值配置文件
- API文档明确列出所有枚举值
- 前后端使用相同的枚举定义

---

**文档版本：** v1.0  
**更新日期：** 2024-01-01  
**维护说明：** 当数据模型或API接口发生变更时，必须同步更新此对照文档。