# WMPDA Plan 4 — 中央立库 入库/退货 (Central Warehouse Task Creation) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

---

## ⚠️ BACKEND DEPENDENCY — READ BEFORE STARTING

**This entire module is BACKEND-BLOCKED.** The grounding analysis (`result.api.gapsForCentralWarehouse`) **confirms** that **no central-warehouse task-creation endpoint exists** in the real WMS contract today:

> "CONFIRMED GAP: No central-warehouse (中央仓) putaway (上架) or retrieval/picking (下架/拣货/出库) task-CREATION endpoint exists in the real WMS contract. … none CREATES a warehouse task/order. … any feature requiring the app to ISSUE a central-warehouse putaway or retrieval task needs NEW backend work — the contract must be extended (e.g. a POST /api/{warehouse}/task endpoint) before the client can call it."

Consequently:

1. **The DTOs and Retrofit signatures in this plan are written against the PLACEHOLDER contract** from spec §5.5 (`POST api/CentralWarehouse/CreateTask`, `POST api/CentralWarehouse/CancelTask`). They are marked **🔧 TBD/backend-blocked** throughout. They exist so the module **compiles, unit-tests, and is ready to wire the instant the backend delivers the endpoint** — only the exact path/field names may need a one-line adjustment then.
2. **Every build-verify step in this plan compiles the module** (`./gradlew :app:assembleDebug`) and runs the **pure-logic unit tests** (`MaterialLabelValidator`, `WarehouseTaskFactory`). These pass with no backend.
3. **Live integration is DEFERRED.** Task 8 is a clearly-marked **manual integration checklist** that an engineer runs **only after the backend endpoint is live** — it is NOT a blocker for completing/merging this plan. The screen is fully interactive against the placeholder; against an unreachable/unbuilt endpoint it surfaces the network/business error path (which is itself a useful demo of the error overlay).
4. **Do NOT invent fields the backend hasn't confirmed.** When backend delivers, re-check the response shape against `WmsEnvelope<CreateTaskData>` (Task 2) and adjust `CreateTaskData` field names only.

---

**Goal:** Add a `feature/warehouse/` module to WMPDA implementing the **scan-to-create-task** flow for 中央立库入库 (PUTAWAY) and 中央立库退货 (RETRIEVAL) — one shared repository + one shared screen/ViewModel parameterized by `taskType`, wired to the two existing routes, with a this-session created-task list, green success flash, error overlay on business rejection, and a delete-wrong-scan (删错扫) cancel action — all against a placeholder backend contract.

**Architecture:** ONE `WarehouseTaskRepository.createTask(materialLabelId, taskType)` + `cancelTask(taskId)` calling the placeholder `WmsApi` endpoints, interpreting command results via the Plan-1 `ResponseInterpreter` and reading `data.taskId` via `WmsEnvelope<CreateTaskData>`. ONE `WarehouseViewModel(taskType)` exposing one immutable `WarehouseUiState` via `StateFlow`, collecting `AppContainer.scanFlow` in `init`; on scan it validates the label, POSTs immediately, and on success appends a session row + triggers FlashOverlay + SUCCESS feedback. ONE `WarehouseScreen(taskType, ...)` rendered for both routes. Identity (`employeeId`/`factoryId`) comes **only** from `SessionManager`. Pure logic (label validation, task-row construction, result mapping) is extracted to testable functions with JUnit tests.

**Tech Stack:** Kotlin 2.0.21 · Jetpack Compose (Material 3) · Retrofit 2.11 + OkHttp + Gson · Coroutines/StateFlow · JUnit4. Reuses every Plan-1 (Foundation) contract — see below.

**Spec:** `docs/superpowers/specs/2026-06-01-wmpda-warehouse-pda-rewrite-design.md` §5.5 (flow + placeholder contract), §8 (endpoint table), §9 items 1–2 (backend dependency + 删错扫 semantics).

**Grounding:** `result.api.gapsForCentralWarehouse` (CONFIRMED gap, quoted above).

---

## Plan-1 contracts reused (reference only — DO NOT redefine)

These already exist from Foundation (`docs/superpowers/plans/2026-06-01-wmpda-foundation.md`). This plan only **uses** them:

- **DI:** `com.bizlink.wmpda.AppContainer` (object). Add `warehouseTaskRepository` as a `by lazy` property (Task 4). ViewModels reach deps via `AppContainer.<x>` (service locator) with the default `viewModel()` factory.
- **Network:** `AppContainer.networkClient.api()` → `WmsApi`. ADD the two warehouse endpoints to `core/network/WmsApi.kt` (additive — Task 3). Command/write → `Response<okhttp3.ResponseBody>` interpreted by `ResponseInterpreter`; typed read of `taskId` → `WmsEnvelope<CreateTaskData>` (Gson + TypeToken).
- **Envelope:** `com.bizlink.wmpda.core.network.WmsEnvelope<T>(isSuccess, message, data)`.
- **Command interpreter:** `com.bizlink.wmpda.core.network.ResponseInterpreter.interpret(httpCode: Int, body: String?): WmsResult`.
- **Result:** `com.bizlink.wmpda.core.network.WmsResult` sealed — `Success` / `IdempotentSuccess` / `AuthFailure` / `BusinessFailure(code, msg)` / `RetryableFailure(cause)`.
- **Session:** `AppContainer.sessionManager.current()` (suspend) → `Session(loggedIn, employeeId, userName, factoryName, factoryId: Int, workCenter, apiBaseUrl)`. NEVER hardcode `employeeId` / `factoryId`.
- **Scanner:** `AppContainer.scanFlow: SharedFlow<String>` — collect in ViewModel `init`.
- **Components:** `com.bizlink.wmpda.core.components` — `ScanCard(stepLabel, valueLabel, placeholder, active)`, `ErrorOverlay(title, detail, severity, onDismiss)` with `OverlaySeverity { NORMAL, OFF_PLAN }` (OFF_PLAN = business-rejected), `FlashOverlay(visible, onConsumed)`, `StatusPill(text, tone)` with `PillTone`, `QFCard(modifier, onClick, content)`, `FeedbackPlayer.play(context, Kind.SUCCESS|ERROR)`.
- **Theme:** tokens in `com.bizlink.wmpda.core.theme` (`Primary`, `OnSurface`, `OnSurfaceDim`, `OnSurfaceMuted`, `OutlineSoft`, `StatusError`, `StatusOnline`, …). NEVER raw hex outside `Color.kt`.
- **Nav:** `com.bizlink.wmpda.core.nav.Routes.WAREHOUSE_INBOUND = "warehouse/inbound"` and `Routes.WAREHOUSE_RETURN = "warehouse/return"` already declared. `core/nav/NavGraph.kt` currently routes BOTH to a shared `"待实现"` placeholder block — Task 7 REPLACES them with the real shared screen.

---

## Bug lessons re-encoded (from spec §7 + grounding — do not re-step)

These production incidents from the Flutter app are baked into this plan as explicit code + notes:

- **§7.4 — line-side shared-state union fragility:** each flow gets its OWN ViewModel + UiState. Here, 入库 and 退货 are the SAME flow differing only by a `taskType` constructor arg, so they share ONE `WarehouseViewModel` **class** — but `viewModel()` produces a **separate instance per route** (distinct `NavBackStackEntry` scope). Errors are surfaced as a transient overlay; **the session list is NEVER cleared on error** (Task 5, `showError` does not touch `tasks`).
- **§7.6 — scan input must be explicitly cleared by the outer layer:** the ViewModel owns scan state; after each scan (success OR error) it leaves no half-entered value (there is no persisted scan field — each scan is a discrete event). It also **trims + lowercases-safely** the incoming code and ignores blank/duplicate-within-100ms scans (Task 5, `onScan` guard).
- **§7.7 — pass server Chinese `message` through verbatim; no `print`/`debugPrint`:** `BusinessFailure.msg` is shown unchanged in `ErrorOverlay`; logging uses `android.util.Log` only.
- **§7.8 — HTTP 200 ≠ success:** task creation goes through `ResponseInterpreter` (not the HTTP code alone), then reads `taskId` from the typed envelope. A `200` body with `isSuccess:false` / business message → `BusinessFailure` → OFF_PLAN overlay (Task 4 + Task 5).
- **Grounding — confirmed endpoint gap:** see the BACKEND DEPENDENCY banner. The repository is fully wired but the endpoint is placeholder; integration is deferred (Task 8).

---

## File Structure

All paths under `/Users/benque/Projects/WMPDA/app/src/main/java/com/bizlink/wmpda/`.

```
feature/warehouse/
├── data/
│   ├── WarehouseDtos.kt            # 🔧 placeholder DTOs: CreateTaskRequest, CancelTaskRequest, CreateTaskData
│   ├── WarehouseTaskType.kt        # enum PUTAWAY / RETRIEVAL (+ wire value + Chinese label)
│   ├── MaterialLabelValidator.kt   # PURE — label format guard (TDD)
│   ├── WarehouseTaskFactory.kt     # PURE — builds SessionTask rows + maps create result (TDD)
│   └── WarehouseTaskRepository.kt  # createTask / cancelTask → WmsApi → ResponseInterpreter + WmsEnvelope
└── ui/
    ├── WarehouseViewModel.kt       # taskType-parameterized; one StateFlow<WarehouseUiState>
    └── WarehouseScreen.kt          # shared screen for both routes

core/network/WmsApi.kt              # MODIFY (additive): + createWarehouseTask, + cancelWarehouseTask
AppContainer.kt                     # MODIFY (additive): + warehouseTaskRepository by lazy
core/nav/NavGraph.kt                # MODIFY: remove the two warehouse routes from the placeholder list,
                                    #         add real composable(WAREHOUSE_INBOUND/RETURN){ WarehouseScreen(...) }

app/src/test/java/com/bizlink/wmpda/feature/warehouse/data/
├── MaterialLabelValidatorTest.kt
└── WarehouseTaskFactoryTest.kt
```

**Responsibility boundaries:**
- `WarehouseDtos.kt` + `WarehouseTaskType.kt` — the placeholder wire contract (the ONLY place to touch when backend delivers).
- `MaterialLabelValidator` / `WarehouseTaskFactory` — pure, unit-tested business logic (no Android, no network).
- `WarehouseTaskRepository` — the only place network shape is interpreted for this feature.
- `WarehouseViewModel` — orchestration + UiState; `WarehouseScreen` — pure rendering.

---

## Task 1: Task type enum + pure label validator (TDD)

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/warehouse/data/WarehouseTaskType.kt`
- Create: `app/src/main/java/com/bizlink/wmpda/feature/warehouse/data/MaterialLabelValidator.kt`
- Test: `app/src/test/java/com/bizlink/wmpda/feature/warehouse/data/MaterialLabelValidatorTest.kt`

- [ ] **Step 1: Write `WarehouseTaskType.kt`** (single source of the two modes; `wire` is the placeholder enum string the backend expects, `label` is the Chinese UI title)

```kotlin
package com.bizlink.wmpda.feature.warehouse.data

/**
 * 中央立库任务类型。入库与退货同流程,差此枚举。
 * 🔧 backend-blocked: `wire` 值取自 spec §5.5 占位契约 ("PUTAWAY"|"RETRIEVAL");
 * 后端接口就绪后若枚举字符串不同,只改此处。
 */
enum class WarehouseTaskType(val wire: String, val label: String, val actionVerb: String) {
    PUTAWAY(wire = "PUTAWAY", label = "中央立库入库", actionVerb = "上架"),
    RETRIEVAL(wire = "RETRIEVAL", label = "中央立库退货", actionVerb = "下架"),
}
```

- [ ] **Step 2: Write the failing test `MaterialLabelValidatorTest.kt`**

```kotlin
package com.bizlink.wmpda.feature.warehouse.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MaterialLabelValidatorTest {

    @Test fun `blank is invalid`() {
        assertFalse(MaterialLabelValidator.isValid(""))
        assertFalse(MaterialLabelValidator.isValid("   "))
    }

    @Test fun `too short is invalid`() {
        // MIN_LENGTH 位以下视为无效
        assertFalse(MaterialLabelValidator.isValid("123"))
    }

    @Test fun `valid label of min length accepted`() {
        val label = "1".repeat(MaterialLabelValidator.MIN_LENGTH)
        assertTrue(MaterialLabelValidator.isValid(label))
    }

    @Test fun `valid long alphanumeric label accepted`() {
        assertTrue(MaterialLabelValidator.isValid("MAT-20260601-000123"))
    }

    @Test fun `normalize trims surrounding whitespace`() {
        assertEquals("ABC123XYZ", MaterialLabelValidator.normalize("  ABC123XYZ \n"))
    }

    @Test fun `normalize leaves inner characters untouched`() {
        assertEquals("A B-C", MaterialLabelValidator.normalize(" A B-C "))
    }
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.feature.warehouse.data.MaterialLabelValidatorTest"`
Expected: FAIL — `MaterialLabelValidator` unresolved reference.

- [ ] **Step 4: Write `MaterialLabelValidator.kt`**

```kotlin
package com.bizlink.wmpda.feature.warehouse.data

/**
 * 物料标签 ID 格式守卫(纯函数,无网络/Android 依赖)。
 * 中央立库只做轻量本地校验:非空 + 去空白后长度 >= MIN_LENGTH。
 * 真正的"是否在计划内/标签有效"由后端 CreateTask 判定并以业务 message 返回。
 */
object MaterialLabelValidator {
    const val MIN_LENGTH = 6

    /** 去掉首尾空白(含换行);保留内部字符原样(条码可能含 - / 等)。 */
    fun normalize(raw: String): String = raw.trim()

    fun isValid(raw: String): Boolean = normalize(raw).length >= MIN_LENGTH
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.feature.warehouse.data.MaterialLabelValidatorTest"`
Expected: PASS (6 tests).

- [ ] **Step 6: Commit**

```bash
cd /Users/benque/Projects/WMPDA
git add -A && git commit -m "feat(warehouse): add WarehouseTaskType + MaterialLabelValidator (TDD)"
```

---

## Task 2: Placeholder DTOs (🔧 backend-blocked)

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/warehouse/data/WarehouseDtos.kt`

> No test here — these are pure data carriers parsed by Gson; their behavior is exercised through `WarehouseTaskFactory` (Task 3) and `WarehouseTaskRepository` (Task 4). DTO shape matches spec §5.5 placeholder; **adjust field names only when backend delivers.**

- [ ] **Step 1: Write `WarehouseDtos.kt`**

```kotlin
package com.bizlink.wmpda.feature.warehouse.data

/**
 * 🔧 TBD / BACKEND-BLOCKED — 占位契约,取自 spec §5.5。
 *
 * 后端尚未提供中央立库建任务接口(见 grounding: gapsForCentralWarehouse「CONFIRMED GAP」)。
 * 以下 DTO 仅为让模块可编译/可联调就绪;后端就绪后核对字段名后再启用。
 *
 *   POST api/CentralWarehouse/CreateTask
 *     body: { materialLabelId, taskType:"PUTAWAY"|"RETRIEVAL", employeeId, factoryId }
 *     resp: { isSuccess, message, data:{ taskId } }
 *
 *   POST api/CentralWarehouse/CancelTask   (可选 —「删错扫」撤销)
 *     body: { taskId, employeeId }
 *     resp: { isSuccess, message, data }
 */

data class CreateTaskRequest(
    val materialLabelId: String,
    val taskType: String,   // WarehouseTaskType.wire — "PUTAWAY" | "RETRIEVAL"
    val employeeId: String,  // from SessionManager — 禁止硬编码
    val factoryId: Int,      // from SessionManager — 禁止硬编码
)

data class CancelTaskRequest(
    val taskId: String,
    val employeeId: String,
)

/** `data` 负载;建任务成功后返回的任务号。 */
data class CreateTaskData(
    val taskId: String? = null,
)
```

- [ ] **Step 2: Build to verify the DTOs compile**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 3: Commit**

```bash
cd /Users/benque/Projects/WMPDA
git add -A && git commit -m "feat(warehouse): add placeholder CreateTask/CancelTask DTOs (backend-blocked)"
```

---

## Task 3: WmsApi endpoints (additive) + pure result factory (TDD)

**Files:**
- Modify: `app/src/main/java/com/bizlink/wmpda/core/network/WmsApi.kt`
- Create: `app/src/main/java/com/bizlink/wmpda/feature/warehouse/data/WarehouseTaskFactory.kt`
- Test: `app/src/test/java/com/bizlink/wmpda/feature/warehouse/data/WarehouseTaskFactoryTest.kt`

The factory is the pure, testable seam that maps `(WmsResult, parsed taskId, scanned label, taskType, timestamp)` → a domain outcome (a created `SessionTask` or a failure). This keeps the repository thin and lets us TDD the mapping without a network.

- [ ] **Step 1: Open `WmsApi.kt` and read the current contents** (Plan 1 left only `login`)

The file currently is:

```kotlin
package com.bizlink.wmpda.core.network

import com.bizlink.wmpda.core.network.dto.LoginRequest
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST

interface WmsApi {
    // Untyped body: parsed by ResponseInterpreter (success/failure) + Gson (UserDto) + TokenExtractor (optional token).
    @POST("api/Auth/Login")
    suspend fun login(@Body body: LoginRequest): Response<ResponseBody>
}
```

- [ ] **Step 2: Add the two warehouse endpoints (ADDITIVE — do NOT rewrite the file)**

> ⚠️ This is Plan 4 (runs LAST). By now `WmsApi.kt` already holds `login` (Plan 1) **plus** the picking endpoints (Plan 2) **and** the linestock endpoints (Plan 3). Do NOT replace the file — only ADD the imports and the two methods below, preserving everything already there.

Add these imports (alongside whatever imports already exist):

```kotlin
import com.bizlink.wmpda.feature.warehouse.data.CancelTaskRequest
import com.bizlink.wmpda.feature.warehouse.data.CreateTaskRequest
```

Add these two functions inside the `interface WmsApi { … }` body, after the existing methods:

```kotlin
    // 🔧 TBD / BACKEND-BLOCKED — 中央立库建任务/撤销任务。占位契约见 spec §5.5。
    // 后端尚未提供该接口(grounding: gapsForCentralWarehouse「CONFIRMED GAP」)。
    // 命令类:body 原文经 ResponseInterpreter 判成败;成功后再用 WmsEnvelope<CreateTaskData> 取 taskId。
    @POST("api/CentralWarehouse/CreateTask")
    suspend fun createWarehouseTask(@Body body: CreateTaskRequest): Response<ResponseBody>

    @POST("api/CentralWarehouse/CancelTask")
    suspend fun cancelWarehouseTask(@Body body: CancelTaskRequest): Response<ResponseBody>
```

- [ ] **Step 3: Build to verify the API compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Write the failing test `WarehouseTaskFactoryTest.kt`**

```kotlin
package com.bizlink.wmpda.feature.warehouse.data

import com.bizlink.wmpda.core.network.WmsResult
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WarehouseTaskFactoryTest {

    @Test fun `success with taskId produces a session task`() {
        val r = WarehouseTaskFactory.fromCreateResult(
            result = WmsResult.Success,
            taskId = "T-1001",
            label = "MAT-001",
            taskType = WarehouseTaskType.PUTAWAY,
            timestampMs = 1_700_000_000_000L,
        )
        assertTrue(r is WarehouseTaskFactory.Outcome.Created)
        val task = (r as WarehouseTaskFactory.Outcome.Created).task
        assertEquals("T-1001", task.taskId)
        assertEquals("MAT-001", task.materialLabelId)
        assertEquals(WarehouseTaskType.PUTAWAY, task.taskType)
        assertEquals(1_700_000_000_000L, task.createdAtMs)
    }

    @Test fun `idempotent success also produces a task using fallback id when taskId missing`() {
        val r = WarehouseTaskFactory.fromCreateResult(
            result = WmsResult.IdempotentSuccess,
            taskId = null,
            label = "MAT-002",
            taskType = WarehouseTaskType.RETRIEVAL,
            timestampMs = 42L,
        )
        assertTrue(r is WarehouseTaskFactory.Outcome.Created)
        // taskId 缺失时用占位串,避免列表行不可撤销时崩溃
        assertEquals("(已存在)", (r as WarehouseTaskFactory.Outcome.Created).task.taskId)
    }

    @Test fun `business failure passes server message through verbatim as OFF_PLAN`() {
        val r = WarehouseTaskFactory.fromCreateResult(
            result = WmsResult.BusinessFailure("99", "该物料不在入库计划中"),
            taskId = null,
            label = "MAT-003",
            taskType = WarehouseTaskType.PUTAWAY,
            timestampMs = 0L,
        )
        assertTrue(r is WarehouseTaskFactory.Outcome.Rejected)
        val rej = r as WarehouseTaskFactory.Outcome.Rejected
        assertEquals("该物料不在入库计划中", rej.message)
        assertTrue(rej.offPlan)
    }

    @Test fun `auth failure is a non-offplan rejection`() {
        val r = WarehouseTaskFactory.fromCreateResult(
            result = WmsResult.AuthFailure,
            taskId = null,
            label = "MAT-004",
            taskType = WarehouseTaskType.PUTAWAY,
            timestampMs = 0L,
        )
        assertTrue(r is WarehouseTaskFactory.Outcome.Rejected)
        assertEquals(false, (r as WarehouseTaskFactory.Outcome.Rejected).offPlan)
    }

    @Test fun `retryable failure surfaces cause as non-offplan rejection`() {
        val r = WarehouseTaskFactory.fromCreateResult(
            result = WmsResult.RetryableFailure("HTTP 500"),
            taskId = null,
            label = "MAT-005",
            taskType = WarehouseTaskType.RETRIEVAL,
            timestampMs = 0L,
        )
        assertTrue(r is WarehouseTaskFactory.Outcome.Rejected)
        val rej = r as WarehouseTaskFactory.Outcome.Rejected
        assertEquals(false, rej.offPlan)
        assertTrue(rej.message.contains("HTTP 500"))
    }
}
```

- [ ] **Step 5: Run the test to verify it fails**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.feature.warehouse.data.WarehouseTaskFactoryTest"`
Expected: FAIL — `WarehouseTaskFactory` unresolved reference.

- [ ] **Step 6: Write `WarehouseTaskFactory.kt`** (pure mapping; defines `SessionTask` domain row + `Outcome` sealed result)

```kotlin
package com.bizlink.wmpda.feature.warehouse.data

import com.bizlink.wmpda.core.network.WmsResult

/**
 * 一次建任务的成功记录,展示于「本场次列表」。
 * timestamp 由调用方(Repository/ViewModel)用 System.currentTimeMillis() 注入。
 */
data class SessionTask(
    val taskId: String,
    val materialLabelId: String,
    val taskType: WarehouseTaskType,
    val createdAtMs: Long,
)

/**
 * 纯函数:把网络命令结果映射为领域结果。无 Android/网络依赖,可单测。
 * - Success / IdempotentSuccess → Created(列表新增一行)
 * - BusinessFailure → Rejected(offPlan=true,服务端中文 message 原样透传 → OFF_PLAN 覆盖)
 * - AuthFailure / RetryableFailure → Rejected(offPlan=false,普通 ERROR 覆盖)
 */
object WarehouseTaskFactory {

    sealed class Outcome {
        data class Created(val task: SessionTask) : Outcome()
        data class Rejected(val message: String, val offPlan: Boolean) : Outcome()
    }

    fun fromCreateResult(
        result: WmsResult,
        taskId: String?,
        label: String,
        taskType: WarehouseTaskType,
        timestampMs: Long,
    ): Outcome = when (result) {
        WmsResult.Success, WmsResult.IdempotentSuccess -> Outcome.Created(
            SessionTask(
                taskId = taskId?.takeIf { it.isNotBlank() } ?: "(已存在)",
                materialLabelId = label,
                taskType = taskType,
                createdAtMs = timestampMs,
            ),
        )
        is WmsResult.BusinessFailure -> Outcome.Rejected(
            message = result.msg,   // §7.7 服务端中文 message 原样透传
            offPlan = true,
        )
        WmsResult.AuthFailure -> Outcome.Rejected(
            message = "身份验证失败,请重新登录",
            offPlan = false,
        )
        is WmsResult.RetryableFailure -> Outcome.Rejected(
            message = "服务器繁忙,请重试 (${result.cause})",
            offPlan = false,
        )
    }
}
```

- [ ] **Step 7: Run the test to verify it passes**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.feature.warehouse.data.WarehouseTaskFactoryTest"`
Expected: PASS (5 tests).

- [ ] **Step 8: Commit**

```bash
cd /Users/benque/Projects/WMPDA
git add -A && git commit -m "feat(warehouse): add WmsApi create/cancel endpoints + WarehouseTaskFactory (TDD)"
```

---

## Task 4: WarehouseTaskRepository + AppContainer wiring

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/warehouse/data/WarehouseTaskRepository.kt`
- Modify: `app/src/main/java/com/bizlink/wmpda/AppContainer.kt`

- [ ] **Step 1: Write `WarehouseTaskRepository.kt`** (ONE repository for both task types; calls placeholder API, interprets via Plan-1 `ResponseInterpreter` + `WmsEnvelope`, delegates mapping to `WarehouseTaskFactory`; reads identity from `SessionManager`)

```kotlin
package com.bizlink.wmpda.feature.warehouse.data

import android.util.Log
import com.bizlink.wmpda.core.network.NetworkClient
import com.bizlink.wmpda.core.network.ResponseInterpreter
import com.bizlink.wmpda.core.network.WmsEnvelope
import com.bizlink.wmpda.core.network.WmsResult
import com.bizlink.wmpda.core.session.SessionManager
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

/**
 * 中央立库建任务 / 撤销任务仓库。入库(PUTAWAY)与退货(RETRIEVAL)共用本仓库,仅 taskType 不同。
 *
 * 🔧 BACKEND-BLOCKED:调用 spec §5.5 占位接口;后端尚未实现(grounding: gapsForCentralWarehouse)。
 * 编译/联调就绪;真机联调待后端交付(见 Plan 4 Task 8 手动清单)。
 *
 * §7.8 HTTP 200 ≠ 成功:命令结果一律经 ResponseInterpreter,成功后再用 WmsEnvelope 取 taskId。
 * employeeId/factoryId 一律取自 SessionManager(§ 禁止硬编码 2 / 工号)。
 */
class WarehouseTaskRepository(
    private val network: NetworkClient,
    private val session: SessionManager,
) {
    private val gson = Gson()

    suspend fun createTask(
        materialLabelId: String,
        taskType: WarehouseTaskType,
    ): WarehouseTaskFactory.Outcome {
        val label = MaterialLabelValidator.normalize(materialLabelId)
        val s = session.current()
        return runCatching {
            val response = network.api().createWarehouseTask(
                CreateTaskRequest(
                    materialLabelId = label,
                    taskType = taskType.wire,
                    employeeId = s.employeeId,
                    factoryId = s.factoryId,
                ),
            )
            val body = response.body()?.string() ?: response.errorBody()?.string()
            Log.i("WMPDA", "CreateTask(${taskType.wire}) resp[${response.code()}]: $body")

            val result = ResponseInterpreter.interpret(response.code(), body)
            val taskId = if (result is WmsResult.Success || result is WmsResult.IdempotentSuccess) {
                parseTaskId(body)
            } else null

            WarehouseTaskFactory.fromCreateResult(
                result = result,
                taskId = taskId,
                label = label,
                taskType = taskType,
                timestampMs = System.currentTimeMillis(),
            )
        }.getOrElse { e ->
            Log.w("WMPDA", "CreateTask error", e)
            WarehouseTaskFactory.Outcome.Rejected(
                message = "网络异常:${e.message ?: "无法连接服务器"}",
                offPlan = false,
            )
        }
    }

    /**
     * 「删错扫」撤销已建任务(§9 item 2 默认 (b))。
     * @return Pair(ok, message):ok=true 撤销成功;message 用于失败时给用户提示。
     */
    suspend fun cancelTask(taskId: String): Pair<Boolean, String> {
        val s = session.current()
        return runCatching {
            val response = network.api().cancelWarehouseTask(
                CancelTaskRequest(taskId = taskId, employeeId = s.employeeId),
            )
            val body = response.body()?.string() ?: response.errorBody()?.string()
            Log.i("WMPDA", "CancelTask($taskId) resp[${response.code()}]: $body")
            when (val r = ResponseInterpreter.interpret(response.code(), body)) {
                WmsResult.Success, WmsResult.IdempotentSuccess -> true to "已撤销任务 $taskId"
                is WmsResult.BusinessFailure -> false to r.msg
                WmsResult.AuthFailure -> false to "身份验证失败,请重新登录"
                is WmsResult.RetryableFailure -> false to "服务器繁忙,请重试 (${r.cause})"
            }
        }.getOrElse { e ->
            Log.w("WMPDA", "CancelTask error", e)
            false to "网络异常:${e.message ?: "无法连接服务器"}"
        }
    }

    private fun parseTaskId(body: String?): String? {
        if (body.isNullOrBlank()) return null
        return runCatching {
            val type = object : TypeToken<WmsEnvelope<CreateTaskData>>() {}.type
            gson.fromJson<WmsEnvelope<CreateTaskData>>(body, type).data?.taskId
        }.getOrNull()
    }
}
```

- [ ] **Step 2: Open `AppContainer.kt` and read the current contents** (Plan 1 left `sessionManager`, `networkClient`, `authRepository`, `scanFlow`)

The relevant region to add to is the `by lazy` block (after `authRepository`).

- [ ] **Step 3: Edit `AppContainer.kt` — add the import and the `warehouseTaskRepository` lazy property**

Add this import near the other feature imports:

```kotlin
import com.bizlink.wmpda.feature.warehouse.data.WarehouseTaskRepository
```

And add this property right after the existing `authRepository` lazy block:

```kotlin
    val warehouseTaskRepository: WarehouseTaskRepository by lazy {
        WarehouseTaskRepository(network = networkClient, session = sessionManager)
    }
```

- [ ] **Step 4: Build to verify the repository + wiring compile**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 5: Commit**

```bash
cd /Users/benque/Projects/WMPDA
git add -A && git commit -m "feat(warehouse): add WarehouseTaskRepository + AppContainer wiring"
```

---

## Task 5: WarehouseViewModel (taskType-parameterized)

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/warehouse/ui/WarehouseViewModel.kt`

This is the one ViewModel class shared by both routes; each route's `viewModel()` produces a distinct instance scoped to its `NavBackStackEntry`, so 入库 and 退货 keep separate session lists (§7.4). It collects `AppContainer.scanFlow` in `init`, debounces duplicate scans within 100ms (§7.6), validates the label, POSTs immediately, and on success prepends a `SessionTask` row + raises `flashSuccess`. Errors NEVER clear `tasks` (§7.4).

- [ ] **Step 1: Write `WarehouseViewModel.kt`**

```kotlin
package com.bizlink.wmpda.feature.warehouse.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bizlink.wmpda.AppContainer
import com.bizlink.wmpda.core.components.OverlaySeverity
import com.bizlink.wmpda.feature.warehouse.data.MaterialLabelValidator
import com.bizlink.wmpda.feature.warehouse.data.SessionTask
import com.bizlink.wmpda.feature.warehouse.data.WarehouseTaskFactory
import com.bizlink.wmpda.feature.warehouse.data.WarehouseTaskType
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class WarehouseError(
    val title: String,
    val detail: String,
    val severity: OverlaySeverity = OverlaySeverity.NORMAL,
)

data class WarehouseUiState(
    val taskType: WarehouseTaskType,
    val submitting: Boolean = false,
    val lastScan: String? = null,
    val tasks: List<SessionTask> = emptyList(),
    val error: WarehouseError? = null,
    val flashSuccess: Boolean = false,
)

/**
 * 入库/退货共用 ViewModel,差 taskType。每条路由由 viewModel() 各建一份实例
 * (NavBackStackEntry 作用域隔离),故两屏的本场次列表互不干扰(§7.4)。
 */
class WarehouseViewModel(
    private val taskType: WarehouseTaskType,
) : ViewModel() {

    private val _state = MutableStateFlow(WarehouseUiState(taskType = taskType))
    val state: StateFlow<WarehouseUiState> = _state.asStateFlow()

    // §7.6 ~100ms 去重:同一条码在窗口内重复广播只处理一次。
    private var lastHandledCode: String? = null
    private var lastHandledAtMs: Long = 0L

    init {
        viewModelScope.launch {
            AppContainer.scanFlow.collect { code -> onScan(code) }
        }
    }

    private fun onScan(raw: String) {
        if (_state.value.submitting) return  // 提交中忽略,避免重复建任务
        val code = MaterialLabelValidator.normalize(raw)
        val now = System.currentTimeMillis()
        if (code == lastHandledCode && now - lastHandledAtMs < 100) return
        lastHandledCode = code
        lastHandledAtMs = now

        if (!MaterialLabelValidator.isValid(code)) {
            showError(
                "物料标签格式不符",
                "扫码内容:${code.ifBlank { "(空)" }}(需 ≥${MaterialLabelValidator.MIN_LENGTH} 位)",
                OverlaySeverity.NORMAL,
            )
            return
        }
        createTask(code)
    }

    private fun createTask(label: String) {
        _state.value = _state.value.copy(submitting = true, lastScan = label, error = null)
        viewModelScope.launch {
            when (val outcome = AppContainer.warehouseTaskRepository.createTask(label, taskType)) {
                is WarehouseTaskFactory.Outcome.Created ->
                    _state.value = _state.value.copy(
                        submitting = false,
                        // 新建任务置顶,本场次列表(§5.5)
                        tasks = listOf(outcome.task) + _state.value.tasks,
                        flashSuccess = true,
                        error = null,
                    )
                is WarehouseTaskFactory.Outcome.Rejected ->
                    showError(
                        title = if (outcome.offPlan) "建任务被拒" else "建任务失败",
                        detail = outcome.message,  // §7.7 服务端中文 message 原样透传
                        severity = if (outcome.offPlan) OverlaySeverity.OFF_PLAN else OverlaySeverity.NORMAL,
                    )
            }
        }
    }

    /** 「删错扫」:撤销已建任务,成功后从本场次列表移除该行(§9 item 2 默认 (b))。 */
    fun deleteWrongScan(task: SessionTask) {
        if (_state.value.submitting) return
        _state.value = _state.value.copy(submitting = true, error = null)
        viewModelScope.launch {
            val (ok, message) = AppContainer.warehouseTaskRepository.cancelTask(task.taskId)
            if (ok) {
                _state.value = _state.value.copy(
                    submitting = false,
                    tasks = _state.value.tasks.filterNot { it === task },
                    flashSuccess = true,
                    error = null,
                )
            } else {
                // §7.4 撤销失败不清空列表,只弹一次性错误。
                _state.value = _state.value.copy(submitting = false)
                showError("撤销失败", message, OverlaySeverity.NORMAL)
            }
        }
    }

    fun dismissError() {
        _state.value = _state.value.copy(error = null)
    }

    fun consumeSuccessFlash() {
        _state.value = _state.value.copy(flashSuccess = false)
    }

    private fun showError(title: String, detail: String, severity: OverlaySeverity) {
        // §7.4 错误不清空 tasks;只覆盖 error + 退出 submitting。
        _state.value = _state.value.copy(
            submitting = false,
            error = WarehouseError(title, detail, severity),
        )
    }
}
```

- [ ] **Step 2: Build to verify the ViewModel compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 3: Commit**

```bash
cd /Users/benque/Projects/WMPDA
git add -A && git commit -m "feat(warehouse): add taskType-parameterized WarehouseViewModel"
```

---

## Task 6: WarehouseScreen (shared for both routes)

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/warehouse/ui/WarehouseScreen.kt`

The screen takes `taskType` + `onBack` and creates its ViewModel with the `viewModel()` factory passing a `ViewModelProvider.Factory` that supplies the `taskType` constructor arg (the Plan-1 default factory cannot build a ViewModel with a constructor parameter, so this is the one place a tiny inline factory is needed). It shows: a `ScanCard` prompt, a "本场次已建任务" list of `QFCard` rows (taskId + label + HH:mm:ss timestamp + a 删错扫 button), a `FlashOverlay` on success, and an `ErrorOverlay` on rejection with `FeedbackPlayer` SUCCESS/ERROR effects.

- [ ] **Step 1: Write `WarehouseScreen.kt`**

```kotlin
package com.bizlink.wmpda.feature.warehouse.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.DeleteOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import com.bizlink.wmpda.core.components.ErrorOverlay
import com.bizlink.wmpda.core.components.FeedbackPlayer
import com.bizlink.wmpda.core.components.FlashOverlay
import com.bizlink.wmpda.core.components.PillTone
import com.bizlink.wmpda.core.components.QFCard
import com.bizlink.wmpda.core.components.ScanCard
import com.bizlink.wmpda.core.components.StatusPill
import com.bizlink.wmpda.core.theme.OnSurfaceDim
import com.bizlink.wmpda.core.theme.OnSurfaceMuted
import com.bizlink.wmpda.core.theme.Primary
import com.bizlink.wmpda.core.theme.StatusError
import com.bizlink.wmpda.feature.warehouse.data.SessionTask
import com.bizlink.wmpda.feature.warehouse.data.WarehouseTaskType
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// taskType 需作为构造参数注入,默认 viewModel() 工厂无法直接构造带参 VM,故用此小工厂。
private class WarehouseVmFactory(
    private val taskType: WarehouseTaskType,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T =
        WarehouseViewModel(taskType) as T
}

@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
fun WarehouseScreen(
    taskType: WarehouseTaskType,
    onBack: () -> Unit,
    viewModel: WarehouseViewModel = viewModel(factory = WarehouseVmFactory(taskType)),
) {
    val state by viewModel.state.collectAsState()
    val context = LocalContext.current

    LaunchedEffect(state.error) {
        if (state.error != null) FeedbackPlayer.play(context, FeedbackPlayer.Kind.ERROR)
    }
    LaunchedEffect(state.flashSuccess) {
        if (state.flashSuccess) FeedbackPlayer.play(context, FeedbackPlayer.Kind.SUCCESS)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(taskType.label, style = MaterialTheme.typography.titleLarge) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                ),
            )
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            Column(Modifier.fillMaxSize().padding(16.dp)) {
                ScanCard(
                    stepLabel = "扫描物料标签 → 即时建${taskType.actionVerb}任务",
                    valueLabel = state.lastScan,
                    placeholder = "等待扫码…",
                    active = !state.submitting,
                )
                Spacer(Modifier.height(16.dp))
                Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                    Text(
                        "本场次已建任务",
                        style = MaterialTheme.typography.titleMedium,
                        color = Primary,
                        modifier = Modifier.weight(1f),
                    )
                    StatusPill(text = "${state.tasks.size} 条", tone = PillTone.SYNCED)
                }
                Spacer(Modifier.height(8.dp))
                if (state.tasks.isEmpty()) {
                    Box(Modifier.fillMaxWidth().padding(top = 48.dp), contentAlignment = Alignment.Center) {
                        Text("尚无记录,扫描物料标签开始", style = MaterialTheme.typography.bodyMedium, color = OnSurfaceMuted)
                    }
                } else {
                    LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        items(state.tasks, key = { it.taskId + "@" + it.createdAtMs }) { task ->
                            TaskRow(
                                task = task,
                                onDelete = { viewModel.deleteWrongScan(task) },
                                deleteEnabled = !state.submitting,
                            )
                        }
                    }
                }
            }

            FlashOverlay(visible = state.flashSuccess, onConsumed = viewModel::consumeSuccessFlash)

            state.error?.let { err ->
                ErrorOverlay(
                    title = err.title,
                    detail = err.detail,
                    severity = err.severity,
                    onDismiss = viewModel::dismissError,
                )
            }
        }
    }
}

private val timeFmt = SimpleDateFormat("HH:mm:ss", Locale.getDefault())

@Composable
private fun TaskRow(task: SessionTask, onDelete: () -> Unit, deleteEnabled: Boolean) {
    QFCard(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                Text(task.materialLabelId, style = MaterialTheme.typography.titleMedium)
                Spacer(Modifier.height(2.dp))
                Text(
                    "任务号 ${task.taskId} · ${timeFmt.format(Date(task.createdAtMs))}",
                    style = MaterialTheme.typography.bodySmall,
                    color = OnSurfaceDim,
                )
            }
            TextButton(onClick = onDelete, enabled = deleteEnabled) {
                Icon(Icons.Filled.DeleteOutline, contentDescription = null, tint = StatusError)
                Spacer(Modifier.height(0.dp))
                Text("删错扫", color = StatusError, style = MaterialTheme.typography.labelLarge)
            }
        }
    }
}
```

- [ ] **Step 2: Build to verify the screen compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 3: Commit**

```bash
cd /Users/benque/Projects/WMPDA
git add -A && git commit -m "feat(warehouse): add shared WarehouseScreen (session list + delete-wrong-scan)"
```

---

## Task 7: Wire both routes in NavGraph (replace placeholders)

**Files:**
- Modify: `app/src/main/java/com/bizlink/wmpda/core/nav/NavGraph.kt`

Plan 1's `NavGraph.kt` routes `WAREHOUSE_INBOUND` and `WAREHOUSE_RETURN` through a shared placeholder block:

```kotlin
        // Placeholder destinations — replaced by feature plans 2–4.
        listOf(
            Routes.PICKING, Routes.STOCK_QUERY, Routes.SHELVING, Routes.REMOVAL,
            Routes.RECEIVING, Routes.RETURN, Routes.WAREHOUSE_INBOUND, Routes.WAREHOUSE_RETURN,
        ).forEach { route ->
            composable(route) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("「$route」待实现", style = MaterialTheme.typography.headlineSmall)
                }
            }
        }
```

We remove the two warehouse routes from that `listOf(...)` and add real `composable` entries that render the shared screen with the correct `taskType`.

- [ ] **Step 1: Edit the placeholder `listOf(...)` to drop the two warehouse routes**

Change the list literal so it no longer contains `Routes.WAREHOUSE_INBOUND` and `Routes.WAREHOUSE_RETURN`:

```kotlin
        // Placeholder destinations — replaced as feature plans land.
        listOf(
            Routes.PICKING, Routes.STOCK_QUERY, Routes.SHELVING, Routes.REMOVAL,
            Routes.RECEIVING, Routes.RETURN,
        ).forEach { route ->
            composable(route) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("「$route」待实现", style = MaterialTheme.typography.headlineSmall)
                }
            }
        }
```

- [ ] **Step 2: Add the two real warehouse `composable` entries**

Immediately after the `composable(Routes.WORKBENCH) { ... }` block (and before the placeholder `listOf`), add:

```kotlin
        composable(Routes.WAREHOUSE_INBOUND) {
            WarehouseScreen(
                taskType = WarehouseTaskType.PUTAWAY,
                onBack = { navController.popBackStack() },
            )
        }
        composable(Routes.WAREHOUSE_RETURN) {
            WarehouseScreen(
                taskType = WarehouseTaskType.RETRIEVAL,
                onBack = { navController.popBackStack() },
            )
        }
```

- [ ] **Step 3: Add the imports** at the top of `NavGraph.kt` (alongside the existing feature-screen imports)

```kotlin
import com.bizlink.wmpda.feature.warehouse.data.WarehouseTaskType
import com.bizlink.wmpda.feature.warehouse.ui.WarehouseScreen
```

- [ ] **Step 4: Build to verify navigation wiring compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 5: Run the full unit-test suite to confirm nothing regressed**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest`
Expected: PASS — all Plan-1 tests (28) PLUS `MaterialLabelValidatorTest` (6) + `WarehouseTaskFactoryTest` (5) = 39 tests green.

- [ ] **Step 6: Commit**

```bash
cd /Users/benque/Projects/WMPDA
git add -A && git commit -m "feat(warehouse): wire WAREHOUSE_INBOUND/RETURN routes to shared screen"
```

---

## Task 8: Manual integration checklist (🔧 DEFERRED — run only after backend delivers the endpoint)

**This task is NOT a blocker for completing/merging Plan 4.** The module compiles, unit-tests pass, and the screen is interactive against the placeholder. The steps below are the live-integration acceptance run, deferred until the backend implements `POST api/CentralWarehouse/CreateTask` (and optionally `CancelTask`) per spec §9 item 1.

- [ ] **Step 1 (deferred): Confirm the backend contract** matches `WarehouseDtos.kt`

When backend delivers, compare the live request/response to the placeholder. Adjust ONLY if different:
- Path: `WmsApi.createWarehouseTask` / `cancelWarehouseTask` `@POST(...)` strings.
- Request fields: `CreateTaskRequest` / `CancelTaskRequest`.
- Response field: `CreateTaskData.taskId` (the key the server uses inside `data`).
- Enum strings: `WarehouseTaskType.wire` (if backend uses values other than `PUTAWAY`/`RETRIEVAL`).
Re-run `./gradlew :app:testDebugUnitTest` after any change.

- [ ] **Step 2 (deferred): Install and smoke-test on a Cruise2 device against the live WMS**

```bash
cd /Users/benque/Projects/WMPDA && ./gradlew :app:installDebug
adb logcat -s WMPDA OkHttp
```
Log in, open 工作台 → 中央立库入库.

- [ ] **Step 3 (deferred): Verify the happy path (PUTAWAY)**

Scan a valid in-plan material label. Expected: green full-screen flash + success beep; a row appears at the TOP of 本场次已建任务 showing `materialLabelId`, `任务号 <taskId>`, and an `HH:mm:ss` timestamp; the pill count increments. `adb logcat` shows `CreateTask(PUTAWAY) resp[200]: {"isSuccess":true,...,"data":{"taskId":"..."}}`.

- [ ] **Step 4 (deferred): Verify business rejection (OFF_PLAN)**

Scan a label the backend rejects (not in plan / invalid). Expected: magenta OFF-PLAN `ErrorOverlay` with the server's Chinese `message` verbatim + error beep + vibrate; the session list is UNCHANGED (not cleared). Tap 关闭 to dismiss.

- [ ] **Step 5 (deferred): Verify delete-wrong-scan (CancelTask)**

On a created row, tap 删错扫. Expected: `CancelTask` POSTs; on success the row is removed and the count decrements (green flash). On backend failure, an error overlay shows the server message and the row REMAINS.

- [ ] **Step 6 (deferred): Verify RETRIEVAL route isolation**

Back out, open 工作台 → 中央立库退货, scan a valid label. Expected: identical flow but `taskType=RETRIEVAL` in the logged request; this screen's session list is INDEPENDENT of the 入库 screen's (separate ViewModel instances per route).

- [ ] **Step 7 (deferred): Confirm no offline residue**

Confirm there is no Room/WorkManager/queue involvement — a failed/slow request surfaces the network-error overlay immediately (online-only model). No commit needed for this verification task; record results in the integration ticket.

---

## Done criteria for Plan 4

- `./gradlew :app:assembleDebug` succeeds; `./gradlew :app:testDebugUnitTest` is green including `MaterialLabelValidatorTest` (6) + `WarehouseTaskFactoryTest` (5).
- `feature/warehouse/` exists with: `WarehouseTaskType`, `MaterialLabelValidator`, `WarehouseDtos` (🔧 placeholder), `WarehouseTaskFactory`, `WarehouseTaskRepository`, `WarehouseViewModel`, `WarehouseScreen`.
- `WmsApi` has `createWarehouseTask` + `cancelWarehouseTask` (additive; `login` untouched). `AppContainer` exposes `warehouseTaskRepository`.
- `Routes.WAREHOUSE_INBOUND` and `Routes.WAREHOUSE_RETURN` no longer hit the `"待实现"` placeholder; both render `WarehouseScreen` with `PUTAWAY` / `RETRIEVAL` respectively (one shared screen + ViewModel).
- Scan → immediate create-task → on success: prepend to 本场次列表 (taskId + label + `HH:mm:ss` timestamp via `System.currentTimeMillis()`) + green `FlashOverlay` + `FeedbackPlayer.SUCCESS`. Business rejection → `ErrorOverlay` OFF_PLAN + `FeedbackPlayer.ERROR`, list NOT cleared. 删错扫 → `cancelTask` then remove the row.
- `employeeId`/`factoryId` read from `SessionManager` only; server Chinese `message` passed through verbatim; HTTP 200 routed through `ResponseInterpreter` (not the code alone). No `print`/`debugPrint`.
- Backend dependency is documented in-code (🔧 markers) and live integration is deferred to Task 8.

## Hand-off / cross-plan notes

- **Other plans:** This plan ADDS two methods to `core/network/WmsApi.kt` (`createWarehouseTask`, `cancelWarehouseTask`). Whoever else edits `WmsApi.kt` must keep these (additive, no conflict expected). It also imports the warehouse request DTOs into `WmsApi.kt`, creating a compile dependency from `core/network` → `feature/warehouse/data` — acceptable for this app, but if a future plan enforces strict layering, move the DTOs to `core/network/dto/`.
- **NavGraph:** This plan removes `WAREHOUSE_INBOUND`/`WAREHOUSE_RETURN` from the shared placeholder `listOf(...)`. Picking (Plan 2) and LineStock (Plan 3) remove THEIR routes from the SAME list — coordinate so the final placeholder list is empty (or delete the block entirely) once all feature plans land.
- **Backend:** Feature is fully wired but `POST api/CentralWarehouse/CreateTask` does NOT exist yet (CONFIRMED gap). Live use is blocked on backend per spec §9 item 1; Task 8 is the deferred acceptance run.
