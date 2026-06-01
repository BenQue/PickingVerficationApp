# WMPDA — 仓储 PDA 重构设计 (Warehouse Management PDA)

> 状态: **已批准设计 (Approved Design)** · 日期: 2026-06-01 · 作者: Ben Que + Claude
> 上游: `PickingVerficationApp`(Flutter) 简化页面方案 + `QuickFill`(Kotlin) 架构参考
> 下游: 由本 spec 转 `writing-plans` 拆分实现计划

---

## 1. 目标与背景

### 1.1 一句话

把现有 Flutter 版 `PickingVerficationApp` **砍到只剩简化页面方案**（合箱校验 + 断线线边管理），**新增中央立库入库/退货**，并以**原生 Kotlin** 全新代码库 **WMPDA** 重写——架构参考 `QuickFill`（但不复用其代码），网络模型为**在线即时请求**。

### 1.2 为什么重写而非改造 Flutter

- 与 `QuickFill` 技术栈统一：同团队、同 Cruise2 设备、同架构心智，长期只维护一套 Kotlin 栈。
- 扫码是原生强项：Cruise2 出厂扫码走 Android 系统广播，Kotlin `BroadcastReceiver` 直接接，无需 Flutter platform channel。
- 砍功能后重写表面积小：仅 合箱校验 + 线边管理 + 立库建任务，原生重写成本可控。
- 取舍依据：因「作业现场基本全程有网」，**不引入 `QuickFill` 的离线同步内核**（YAGNI）。

### 1.3 范围 (In Scope)

WMPDA 包含且仅包含四个功能模块 + 登录 + 工作台：

1. **登录** (Auth)
2. **工作台** (Workbench) — 功能入口卡片
3. **合箱校验** (Picking) — 工单物料拣配合箱校验
4. **断线线边管理** (LineStock) — 库存查询 / 电缆上架 / 电缆下架 / 电缆入库(收货) / 电缆退库
5. **中央立库入库** (Warehouse PUTAWAY) — 扫物料标签建上架任务
6. **中央立库退货** (Warehouse RETRIEVAL) — 扫物料标签建下架任务

### 1.4 不做 (Out of Scope)

- 现 Flutter 版的：完整版 picking_verification（带登录态校验流程的旧版）、order_verification、platform_receiving、line_delivery、task_board、app_update、home，以及工作台上的灰色占位（订单查询/平台收料/产线配送）。
- 离线优先 / 本地落库 / 后台同步 / WorkManager。
- iOS / 跨平台 / 暗色模式 / Material You 动态取色。
- 中央立库的**真实物理出入库操作**——由中央立库自有管理系统的 PDA 程序完成；WMPDA 只负责扫码建任务。

---

## 2. 架构决策

### 2.1 技术栈

| 项 | 选型 |
|---|---|
| 语言 / UI | Kotlin + Jetpack Compose (Material 3) |
| 依赖装配 | 手写 `AppContainer` 顶层单例，**禁止 Hilt/Koin** (YAGNI，沿用 QuickFill 纪律) |
| 网络 | Retrofit + OkHttp(JavaNetCookieJar + 按 baseUrl 缓存的 Retrofit 实例) |
| 网络模型 | **在线即时请求** |
| 持久化 | DataStore / EncryptedSharedPreferences（仅会话与配置，**无 Room**） |
| 扫码 | `ScannerReceiver` (BroadcastReceiver) → 进程级 `SharedFlow<String>` |
| 响应解析 | `ResponseInterpreter`（统一吃 `{isSuccess, message, data}`） |
| JSON | Gson + `GsonConverterFactory`（与 QuickFill `NetworkClient` 一致，schema-tolerant 解析需要宽松映射） |

### 2.2 从 QuickFill **保留** 的架构组件（重写，不复制代码）

| 组件 | 在 WMPDA 的形态 |
|---|---|
| `WmpdaApp : Application` | `onCreate { AppContainer.init(this) }` 一行 |
| `AppContainer` (object) | 持 `appContext` + `applicationScope(SupervisorJob+Dispatchers.Default)`；`by lazy` 装配 network/session/scanner + 各 feature repo；`init()` = {设 context、预热会话、注册 scanner}。用**闭包注入**(`baseUrlProvider:()->String`、`tokenProvider:()->String?`)破 Config/Auth 环依赖 |
| `NetworkClient` | OkHttp(cookie jar ACCEPT_ALL + AuthInterceptor + 日志拦截器仅 DEBUG)；`api()` 按 baseUrl 缓存 Retrofit；base URL 变更才重建 |
| `WmsApi` (Retrofit interface) | `suspend fun ... : Response<T>`；不稳定/启发式响应用 `Response<ResponseBody>`，稳定读用 `Response<TypedDto>` |
| `AuthInterceptor` | 非阻塞 `tokenProvider` 闭包；有 token 才加 `Authorization: Bearer`（真 WMS 无 token 时为空操作） |
| `ResponseInterpreter`（重命名 `WmsResult`） | 纯函数 `(httpCode, body) -> WmsResult` sealed；解析 `{isSuccess/state/success, message/msg, data}`；**保留 `authFailureHints`**（200+失败+"未登录" → 触发重登）；`idempotentHints` 降级为可选兜底 |
| `AuthRepository` | Mutex 串行化 login/ensureLoggedIn/forceRelogin；`@Volatile` 缓存；401 → forceRelogin。会话持久化用 **DataStore**（非 Room） |
| `SessionManager`(≈ ConfigRepository) | DataStore 持 `employeeId / factoryId / workCenter / factoryName / apiBaseUrl`；暴露 reactive flow |
| `ScannerReceiver` | 注册 `com.android.server.scannerservice.broadcast`，读 `scannerdata` extra，`tryEmit` 进 `MutableSharedFlow<String>(replay=0, buffer=1, DROP_OLDEST)` |
| Nav 模式 | 单 `NavHost` + `Routes` 字符串常量 + lambda 回调导航（屏幕不持 NavController） |
| ViewModel 模式 | 单一不可变 `UiState` data class 经 `StateFlow` 暴露；屏幕 `collectAsState()`；一次性副作用用 `LaunchedEffect`；`init` 收集 `AppContainer.scanFlow` 驱动扫码状态机；ViewModel 经 `AppContainer` service-locator 取依赖（`viewModel()` 默认工厂） |

### 2.3 从 QuickFill **丢弃** 的组件（离线机器）

`SyncScheduler` · `SyncWorker` · `NetworkObserver` · WorkManager 依赖 · `AppDatabase` + 4 DAO/Entity(Room) · `BindingRepository` 离线状态机(PENDING/SYNCING/SYNCED) · `TaskRepository` 本地缓存合并(TaskMerger/applyMergePlan) · OFF-PLAN 的**同步分类**语义（overlay 机制保留，语义改为「业务被拒」）。

> 结论：在线场景 Repository 塌缩为 `suspend fun 调网络 → ResponseInterpreter → 返回 sealed 结果` 的薄包装。无队列、无 PENDING、无后台 worker、无 Room。

---

## 3. 工程结构

包名 `com.bizlink.wmpda`，位置 `/Users/benque/Projects/WMPDA`。Feature-first + core 共享：

```
com.bizlink.wmpda/
├── WmpdaApp.kt
├── AppContainer.kt
├── core/
│   ├── network/   NetworkClient · WmsApi · AuthInterceptor · ResponseInterpreter(WmsResult) · envelope DTO · TokenExtractor(休眠兜底)
│   ├── session/   SessionManager (DataStore: employeeId/factoryId/workCenter/factoryName/apiBaseUrl)
│   ├── scanner/   ScannerReceiver → SharedFlow
│   ├── scan/      通用 Compose 扫码输入组件(焦点保持/软键盘抑制/扫后清空/去重/弹窗后重夺焦点)
│   ├── nav/       Routes · NavGraph
│   └── theme/     Color.kt · Type.kt · Shape.kt · Theme.kt (复用 QuickFill)
└── feature/
    ├── auth/        ui/(LoginScreen, LoginViewModel) · data/(AuthApi, AuthRepository)
    ├── picking/     ui/ · data/
    ├── linestock/   ui/(5 屏 + 各自 ViewModel) · data/
    └── warehouse/   ui/(入库屏, 退货屏 + ViewModel) · data/(WarehouseTaskRepository)
```

每 feature：`ui/`(Screen + ViewModel) · `data/`(API DTO + Repository)。每个独立流程一个 ViewModel + UiState（**不共享状态联合体**）。

---

## 4. 网络与 WMS 契约

### 4.1 Base URL

- **生产真实地址**: `http://svcn5mesp01:8001`（= `http://10.163.130.173:8001`），所有接口在 `/api/...`。
- 做成 DataStore **可配置**（运维改地址不重打包）。
- ⚠️ **不要**接 `app_config.dart` 里过期的 `http://192.168.1.100:8080/api`。

### 4.2 响应壳

```jsonc
{ "isSuccess": boolean, "message": "string", "data": object|array|bool|string|null }
```
- 分支判 `isSuccess`（也兼容 `state/success` 键，schema-tolerant）；HTTP 400 也可能携带 `{isSuccess:false, message}` 业务失败体，需从 errorBody 解析。
- **`message` 为给作业员的中文，必须原样透传**，不得吞为通用「请求失败」。
- 命令类接口 `data:true` 表示成功；`isSuccess:true` 但 `data:false` 视为业务失败。

### 4.3 鉴权模型（重要）

- `POST /api/Auth/Login {userName, password}` → `{isSuccess, message, data: UserDto}`，UserDto 含 `id/employeeId/domainAccount/userName/factoryName/isActive/...`。**真实响应不含 token**。
- 会话靠 **ASP.NET cookie**（OkHttp cookie jar 自动携带）+ **身份字段随请求带**（`updateBy=employeeId`、`factoryid`、`workCenter`）。
- `TokenExtractor` + Bearer 头作为**休眠兜底**保留，默认不依赖。
- `AuthRepository`：Mutex 串行化、401/「未登录」→ 静默重登。`SessionManager` 在登录后从 UserDto 填充 `employeeId/factoryId/workCenter`，全局统一来源（**根除现版 `factoryId` 硬编码=2 的散落 TODO**）。

---

## 5. 模块设计

### 5.1 登录 (feature/auth)

- 账号 + 密码 → `POST /api/Auth/Login` → 存 UserDto 到 `SessionManager`。
- 失败透传 `message`。成功后导航至工作台。
- 状态: `sealed LoginUiState { Idle, Submitting, Success, Error(message) }`。

### 5.2 工作台 (feature/workbench，可并入 auth 或独立)

- 复刻现简化版 `WorkbenchHomeScreen` 的卡片分组布局，用 Compose + 新设计系统重画。
- 分组与入口：
  - **物料拣配合箱**: 合箱校验
  - **线边 / 立库**: 库存查询 · 电缆上架 · 电缆下架 · 电缆入库(收货) · 电缆退库 · 中央立库入库 · 中央立库退货
- 顶部: 操作员名（来自 SessionManager）+ 版本号（点击查看应用信息）。

### 5.3 合箱校验 (feature/picking)

**流程**: 扫/输工单号 → 加载 → 三页签只读物料 → 全部完成才可提交 → 确认弹窗 → 提交 → 成功页「继续下一个工单」。

**接口**:
| 方法 | 路径 | 用途 |
|---|---|---|
| GET | `/api/WorkOrderPickVerf?orderno={no}` | 取工单校验详情 |
| PUT | `/api/WorkOrderPickVerf` | 提交校验结果 |

- GET 响应 `data`: `{orderId, orderNo, operationNo, operationStatus, cableItemCount, rawItemCount, rawMtrBatchCount, labelCount, cableItems[], centerStockItems[], autoStockItems[]}`；每 item `{itemNo, materialCode, materialDesc, quantity, completedQuantity}`。
- PUT body: `{workOrderId(=orderId), operation(=operationNo), status:'verfSuccess', workCenter, updateOn(ISO-8601), updateBy}`。`workCenter/updateBy` 来自 `SessionManager`。

**业务规则（必须照搬）**:
1. 物料三桶严格隔离: `cableItems`=断线物料 / `centerStockItems`=中央仓库 / `autoStockItems`=自动化库 → 对应三页签，**永不串桶**。
2. `isCompleted = quantity > 0 && completedQuantity >= quantity`（**0 需求量算数据异常，不算完成**）。
3. `hasDataAnomaly = quantity <= 0 || materialCode.isBlank() || materialDesc.isBlank()`，红色，优先级高于完成/未完成。
4. `isAllCompleted = 全部桶物料完成`；但**空工单(0 物料)走专门「无需校验」分支**禁用提交（否则 0==0 误判全完成）。
5. 完成度服务端驱动，物料行只读。
6. 进度 clamp 0..1，剩余量 clamp 0..quantity。

**状态机**: `sealed PickingUiState { Initial, Loading, Loaded(workOrder), Submitting, Submitted(message), Error(message, lastOrderNo) }`，单一 StateFlow。

### 5.4 断线线边管理 (feature/linestock)

五条子流程，**每条独立 ViewModel + UiState**：

| 子流程 | 路由 | WMS 调用 |
|---|---|---|
| 库存查询 | `/linestock` | GET `byBarcode` / GET `byMaterialCode` |
| 电缆上架 | `/linestock/shelving` | POST `transfer {locationCode(扫得), barCodes[]}` |
| 电缆下架 | `/linestock/removal` | POST `transfer {locationCode='2200-100'(锁定,线边库), barCodes[]}` |
| 电缆入库/收货 | `/linestock/receiving` | GET `GetHandoverListByBarcode` → POST `HandoverConfirm {barCodes[]}` |
| 电缆退库 | `/linestock/return` | POST `transfer {locationCode='RETURN'(魔法串), barCodes[]}` |

**接口契约**:
| 方法 | 路径 | 请求 | 响应 data |
|---|---|---|---|
| GET | `/api/LineStock/byBarcode` | `barcode`,`factoryid` | 单条 LineStock(或 false=未找到) |
| GET | `/api/LineStock/byMaterialCode` | `materialcode`,`factoryid` | `List<LineStock>`(空列表=未找到错误) |
| POST | `/api/LineStock/transfer` | `{locationCode, barCodes[]}` | `bool`(true=成功) |
| GET | `/api/LineStock/GetHandoverListByBarcode` | `barcode`,`factoryid` | 单条 HandoverItem |
| POST | `/api/LineStock/HandoverConfirm` | `{barCodes[]}` | message(如「标签收货确认完成！」) |

LineStock 字段: `id|stockId, materialCode, materialDesc, quantity, lastQuantity(剩余), baseUnit, batchCode, locationCode, locationDesc, barCode`。

**业务规则**:
- `transfer` 成功要 `isSuccess==true && data==true`；`isSuccess:true` 但 `data:false` → 「上架失败」。
- 重复条码拒绝且**不清空列表**；上架时若条码已在目标库位 → 拒绝「已在目标库位」。
- 物料查询空列表 = 「未找到」错误（非空成功）。
- `factoryId` 来自 `SessionManager`（默认 2）。
- ⚠️ 响应字段 `barCode`(大 C)，请求 `barcode/barCodes`；id 可能为 `id` 或 `stockId`；条码 min 9、库位 min 4、物料码 min 1。
- 退库默认沿用魔法串 `'RETURN'` 走 `transfer`（见 §9 待确认：是否改 `returnToWMS`）。

### 5.5 中央立库 入库/退货 (feature/warehouse) — 新增

**流程（扫码即提交 + 本场次列表）**: 扫物料标签 ID → 即时 POST 建任务 → 成功追加到本场次列表 + 绿色 FlashSuccess/提示音 → 等下一扫。入库与退货同流程，差 `taskType`。共用 `WarehouseTaskRepository.createTask(materialLabelId, taskType)`。

**占位契约（🔧 需后端新建，联调前对齐）**:
```
POST /api/CentralWarehouse/CreateTask
  body: { materialLabelId, taskType: "PUTAWAY"|"RETRIEVAL", employeeId, factoryId }
  resp: { isSuccess, message, data: { taskId } }

# 可选 — 支持「删错扫」撤销已建任务 (见 §9 待确认)
POST /api/CentralWarehouse/CancelTask
  body: { taskId, employeeId }
  resp: { isSuccess, message, data }
```
- `taskType=PUTAWAY` = 入库(上架任务)；`taskType=RETRIEVAL` = 退货(下架任务)。
- UI: 本场次列表显示已建任务(taskId + materialCode/desc + 时间)；支持删除（语义见 §9）。
- 失败（标签无效/不在计划）走 `ErrorOverlay`（OFF_PLAN severity 重指为「业务被拒」）。

### 5.6 扫码 (core/scan，跨模块)

通用 Compose 扫码输入组件，必须解决现版踩过的坑:
- 焦点持续保持；抑制软键盘但收硬件扫码；**扫后/出错后由外层显式清空**(不依赖输入框自清)；~100ms 去重；弹窗关闭后重夺焦点。
- 数据源: `AppContainer.scanFlow`（硬件广播）+ 可选相机兜底(CameraX/MLKit，按需)。

---

## 6. 设计系统 — 复用 QuickFill「Industrial Modern Blue v2.1 Variant B」

因 WMPDA 也是 Compose，**直接拷贝** QuickFill 的 `Color.kt`(22 语义 token + 4 容器色) / `Type.kt`(IBM Plex Sans + JetBrains Mono) / `Shape.kt`(4/8/12/16 ladder) / `Theme.kt`，近乎零改动。

**复用组件**: `ScanCard`(4dp 蓝锚条 / Active-Idle 双态) · `ErrorOverlay`(NORMAL/OFF_PLAN 双 severity + displayMedium 倒计时 + 震动+蜂鸣) · `StatusBadge/StatusPill`(LED 1Hz 呼吸) · `FlashSuccess`(扫码成功 200ms 绿闪) · `Card`(12dp 工蜂容器)。

**硬规则（写进 WMPDA 的 CLAUDE.md）**:
- `Color.kt` 外禁止 hex 字面量（CI grep `Color(0x` 兜底）。
- 橙色已退役；洋红 `#B5179E` 仅 OFF-PLAN；无紫色/渐变/emoji。
- 仅浅色（不做暗色，Cruise2 仓库照明）；触控目标/按钮 minHeight 48dp；动效仅功能性。
- 字体打包进 APK（**不走 google_fonts 在线拉取**），CJK 回退系统 Noto Sans CJK（不打包）。
- ⚠️ `Type.kt` 代码值与 DESIGN.md 文字有 3 处不一致（displayMedium 56sp / bodyLarge 22sp / labelMedium 11sp）——**以代码为准**。

---

## 7. Bug 教训清单（重写时不许重新踩的雷）

1. **合箱校验缓存污染 (v1.8.0)**: 禁止「失败回退旧缓存」；切工单 / 重置 / 提交成功都清缓存；**单一 ViewModel/Repository 实例**(现版多入口建多份缓存致物料串桶)。WMPDA 默认**每次 Load 拉新、不缓存**。
2. **0 需求量误判完成**: 保留 `quantity > 0` 守卫并把 0 需求行标红(数据异常)。
3. **空工单误提交**: 必须 `materials.isEmpty()` 分支到「无需校验」，不靠 `isAllCompleted`。
4. **线边管理共享状态联合体脆弱**: 每流程独立 ViewModel；错误用一次性事件(snackbar)、**不清空列表**。
5. **退库初始化死流程**: 退库屏直接进空的 in-progress 态，**不复刻** `Reset→Initial`。
6. **扫码输入清空**: 外层显式清空；处理条码大小写 `barCode`/`barcode`。
7. **透传服务端中文 message**；删光所有 `debugPrint/print`。
8. **HTTP 200 ≠ 成功**: 命令类判 `data==true`；解析 `isSuccess`，非仅 HTTP code。

---

## 8. WMS 接口总表（现有，已验证契约）

| 模块 | 方法 | 路径 |
|---|---|---|
| Auth | POST | `/api/Auth/Login` |
| 合箱校验 | GET / PUT | `/api/WorkOrderPickVerf` |
| 线边-查询(条码) | GET | `/api/LineStock/byBarcode` |
| 线边-查询(物料) | GET | `/api/LineStock/byMaterialCode` |
| 线边-转移/上架/下架/退库 | POST | `/api/LineStock/transfer` |
| 线边-收货查询 | GET | `/api/LineStock/GetHandoverListByBarcode` |
| 线边-收货确认 | POST | `/api/LineStock/HandoverConfirm` |
| 中央立库-建任务 | POST | `/api/CentralWarehouse/CreateTask` 🔧 **待后端新建** |
| 中央立库-撤销任务 | POST | `/api/CentralWarehouse/CancelTask` 🔧 **可选，待确认** |

---

## 9. 待确认 / 依赖 / 假设

| # | 项 | 默认 | 需谁拍板 |
|---|---|---|---|
| 1 | 中央立库 `CreateTask`(+可选 `CancelTask`) 接口 | 占位契约见 §5.5 | **后端新建**(阻塞立库联调) |
| 2 | 「删错扫」语义 | 默认 (b) 调 `CancelTask` 撤销 | 用户 + 后端（若接受仅删本地日志则省一接口） |
| 3 | 生产 base URL | `svcn5mesp01:8001`，可配置 | 用户/运维最终确认 |
| 4 | 目标设备 | 东集 Seuic Cruise2（扫码 action 一致） | 首次真机 logcat 校准 `ScannerReceiver.ACTION` |
| 5 | 退库实现 | 沿用魔法串 `'RETURN'` 走 `transfer` | 是否改 `returnToWMS`(请求体文档缺失)，待定 |
| 6 | 包名 | `com.bizlink.wmpda` | 用户确认 |

---

## 10. 成功标准 (Definition of Done)

- WMPDA 为独立可构建的原生 Android(Kotlin/Compose)工程，运行于 Cruise2，锁竖屏。
- 登录 → 工作台 → 四模块全部走通在线流程，扫码硬件输入可用。
- 合箱校验/线边管理与真实 WMS(`svcn5mesp01:8001`)联调通过，服务端中文 message 正确透传。
- 中央立库入库/退货在后端接口就绪后可建任务，本场次列表正确。
- 设计系统落地：22 token / 字体 / 组件 / 硬规则齐备，CLAUDE.md 含设计与代码硬规则。
- §7 全部 bug 教训在代码中有对应防护。
- 无 Room / WorkManager / 离线同步残留。
