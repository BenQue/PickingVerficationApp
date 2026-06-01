# WMPDA Plan 2 — 合箱校验 (Picking Verification) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `feature/picking/` module of WMPDA — scan/type a work order number, fetch its picking-verification detail from WMS (three material buckets: 断线物料 / 中央仓库 / 自动化库), display them read-only across three tabs with color-coded completion status, and submit a `verfSuccess` confirmation when every material is complete — faithfully porting the Flutter `simple_picking_*` flow while re-encoding every v1.8.0 cache-pollution lesson.

**Architecture:** Online-only. A single `PickingRepository` (suspend functions) calls `WmsApi.getWorkOrderPickVerf` (typed `WmsEnvelope<WorkOrderDataDto>` read) and `WmsApi.submitWorkOrderPickVerf` (raw `ResponseBody`, interpreted by `ResponseInterpreter`). One `PickingViewModel` exposes a single immutable `PickingUiState` via `StateFlow`. **No caching anywhere** — every Load fetches fresh; a network failure NEVER falls back to stale data, it emits `Error`. The pure completion/anomaly logic lives in testable top-level functions (`PickingLogic`) with full JUnit coverage. `updateBy`/`workCenter` come from `SessionManager`, never hardcoded.

**Tech Stack:** Kotlin 2.0.21 · Jetpack Compose (Material 3) · Retrofit 2.11 + Gson · Coroutines/StateFlow · JUnit4. Reuses Plan 1 contracts: `AppContainer`, `NetworkClient.api()`, `WmsEnvelope<T>`, `ResponseInterpreter`/`WmsResult`, `SessionManager`, `AppContainer.scanFlow`, theme tokens, shared components (`QFCard`, `StatusPill`, `ErrorOverlay`, `FeedbackPlayer`), `Routes.PICKING`, `NavGraph`.

**Spec:** `docs/superpowers/specs/2026-06-01-wmpda-warehouse-pda-rewrite-design.md` §5.3.
**Grounding:** `result.picking` (flowSteps, wmsEndpoints, businessRules, bugLessons, uiScreens, portingNotes).
**Flutter source ported:** `lib/features/picking_verification/` (`simple_api_models.dart`, `simple_picking_entities.dart`, `simple_picking_datasource.dart`, `simple_picking_repository_impl.dart`, `simple_picking_bloc.dart`, `simple_picking_screen.dart`, `simple_material_item_widget.dart`).

**Depends on:** Plan 1 (Foundation) complete and green (`./gradlew :app:assembleDebug` succeeds, 28 unit tests pass). All paths below are under `/Users/benque/Projects/WMPDA/`.

---

## File Structure

```
app/src/main/java/com/bizlink/wmpda/
├── core/network/WmsApi.kt                    # MODIFY: add getWorkOrderPickVerf + submitWorkOrderPickVerf
├── core/nav/NavGraph.kt                      # MODIFY: replace Routes.PICKING placeholder with PickingScreen
└── feature/picking/
    ├── data/
    │   ├── PickingDtos.kt                     # CREATE: WorkOrderDataDto, MaterialItemDto, SubmitVerfRequest
    │   └── PickingRepository.kt              # CREATE: two suspend calls, no cache, sealed results
    ├── domain/
    │   └── PickingModels.kt                   # CREATE: MaterialCategory enum, Material, WorkOrder + PickingLogic (pure, tested)
    └── ui/
        ├── PickingViewModel.kt               # CREATE: PickingUiState (sealed-ish via status enum) + StateFlow
        ├── PickingScreen.kt                  # CREATE: top-level screen dispatching on status
        └── MaterialItemRow.kt                # CREATE: read-only material card (red/green/orange)

app/src/test/java/com/bizlink/wmpda/feature/picking/
├── PickingLogicTest.kt                       # CREATE: isCompleted / hasDataAnomaly / isAllCompleted / progress / remaining
└── data/PickingMappingTest.kt               # CREATE: DTO→domain mapping keeps buckets isolated; parse envelope
```

**Responsibility boundaries:**
- `domain/PickingModels.kt` — the ONLY place business rules live. Pure functions in `object PickingLogic` so they are unit-testable without Android. The `Material`/`WorkOrder` data classes expose computed properties that delegate to `PickingLogic`.
- `data/PickingDtos.kt` — Gson DTOs matching the WMS JSON exactly. Defaults: numbers→0, lists→empty (mirrors the Dart `?? 0` / `?? []`).
- `data/PickingRepository.kt` — thin: call `WmsApi` → interpret → map to domain. **No `Map<String, WorkOrder>` cache.**
- `ui/` — one ViewModel (StateFlow), one screen that renders per-status, one read-only row composable.

---

## Pre-flight notes (read once)

- **Base URL:** Do NOT hardcode `http://10.163.130.173:8001` at the call site (that was the Flutter datasource's mistake of bypassing the configured base URL). Retrofit's base URL comes from `NetworkClient` (Plan 1), which reads `SessionManager.apiBaseUrl` (defaults to `http://svcn5mesp01:8001`). Use **relative** paths `api/WorkOrderPickVerf`.
- **Identity:** `updateBy` = `session.employeeId`, `workCenter` = `session.workCenter` — both from `AppContainer.sessionManager.current()`. NEVER `"operator"` / `"WC001"` literals at the call site (these are placeholders that cause HTTP 400 if wrong; Plan 1's `SessionManager` already supplies defaults).
- **GET response** envelope: `{isSuccess, message, data: WorkOrderDataDto}`. Read typed via `WmsEnvelope<WorkOrderDataDto>`. If `isSuccess == false`, surface `message` as an Error (treat like an HTTP error per portingNotes).
- **PUT response** envelope: `{isSuccess, message, data: Boolean}`. Interpret with `ResponseInterpreter` on the raw body; surface server Chinese `message` verbatim on failure. HTTP 400 almost always = bad `updateBy`/`workCenter`/disallowed status transition.
- **Three buckets stay isolated** — never merge/cross-assign cable/center/auto. The domain tags each `Material` with a `MaterialCategory` and the UI filters by it.
- **No camera fallback in v1:** The Flutter app had a `mobile_scanner` modal. WMPDA uses the hardware scan head via `AppContainer.scanFlow` plus a manual-entry `TextField`. A camera fallback is explicitly out of scope (spec §5.6 scanner is hardware-broadcast based).
- **Commit cadence:** one commit per task (final step).

---

## Task 1: Domain models + pure logic (TDD)

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/picking/domain/PickingModels.kt`
- Test: `app/src/test/java/com/bizlink/wmpda/feature/picking/PickingLogicTest.kt`

This is the heart of the port — every bugLesson about completion/anomaly/empty-order is encoded here and locked by tests first.

- [ ] **Step 1: Write the failing test `PickingLogicTest.kt`**

```kotlin
package com.bizlink.wmpda.feature.picking

import com.bizlink.wmpda.feature.picking.domain.Material
import com.bizlink.wmpda.feature.picking.domain.MaterialCategory
import com.bizlink.wmpda.feature.picking.domain.WorkOrder
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PickingLogicTest {

    private fun mat(
        code: String = "M001",
        desc: String = "电缆物料",
        qty: Int = 10,
        done: Int = 10,
        cat: MaterialCategory = MaterialCategory.CABLE,
        itemNo: String = "1",
    ) = Material(itemNo = itemNo, materialCode = code, materialDesc = desc,
        quantity = qty, completedQuantity = done, category = cat)

    private fun order(vararg materials: Material) = WorkOrder(
        orderId = 7, orderNo = "WO123", operationNo = "OP10", operationStatus = "open",
        cableItemCount = 0, rawItemCount = 0, rawMtrBatchCount = 0, labelCount = 0,
        materials = materials.toList(),
    )

    // --- isCompleted: quantity > 0 guard is mandatory ---
    @Test fun `completed when done greater equal demand and demand positive`() {
        assertTrue(mat(qty = 10, done = 10).isCompleted)
        assertTrue(mat(qty = 10, done = 12).isCompleted)
    }

    @Test fun `not completed when done below demand`() {
        assertFalse(mat(qty = 10, done = 9).isCompleted)
    }

    @Test fun `zero demand is NOT completed even though done greater equal demand`() {
        // 0 >= 0 would be true without the guard — this is the v1.8.0-adjacent zero-demand bug.
        assertFalse(mat(qty = 0, done = 0).isCompleted)
        assertFalse(mat(qty = 0, done = 5).isCompleted)
    }

    // --- hasDataAnomaly: precedence over complete/incomplete ---
    @Test fun `anomaly when demand non-positive`() {
        assertTrue(mat(qty = 0).hasDataAnomaly)
        assertTrue(mat(qty = -1).hasDataAnomaly)
    }

    @Test fun `anomaly when material code blank`() {
        assertTrue(mat(code = "").hasDataAnomaly)
        assertTrue(mat(code = "   ").hasDataAnomaly)
    }

    @Test fun `anomaly when material desc blank`() {
        assertTrue(mat(desc = "").hasDataAnomaly)
    }

    @Test fun `no anomaly for valid row`() {
        assertFalse(mat(qty = 10, done = 3, code = "M1", desc = "x").hasDataAnomaly)
    }

    // --- progress clamp 0..1 ---
    @Test fun `progress clamps to one when overdone`() {
        assertEquals(1.0f, mat(qty = 10, done = 20).progress, 0.0001f)
    }

    @Test fun `progress is zero for zero demand`() {
        assertEquals(0.0f, mat(qty = 0, done = 5).progress, 0.0001f)
    }

    @Test fun `progress fractional`() {
        assertEquals(0.5f, mat(qty = 10, done = 5).progress, 0.0001f)
    }

    // --- remaining clamp 0..quantity ---
    @Test fun `remaining never negative`() {
        assertEquals(0, mat(qty = 10, done = 20).remainingQuantity)
    }

    @Test fun `remaining normal`() {
        assertEquals(4, mat(qty = 10, done = 6).remainingQuantity)
    }

    // --- WorkOrder aggregates ---
    @Test fun `total and completed counts span all buckets`() {
        val wo = order(
            mat(qty = 5, done = 5, cat = MaterialCategory.CABLE, itemNo = "a"),
            mat(qty = 5, done = 2, cat = MaterialCategory.CENTER, itemNo = "b"),
            mat(qty = 5, done = 5, cat = MaterialCategory.AUTO, itemNo = "c"),
        )
        assertEquals(3, wo.totalMaterialCount)
        assertEquals(2, wo.completedMaterialCount)
    }

    @Test fun `isAllCompleted true only when every bucket material complete`() {
        val incomplete = order(
            mat(qty = 5, done = 5, itemNo = "a"),
            mat(qty = 5, done = 1, cat = MaterialCategory.CENTER, itemNo = "b"),
        )
        assertFalse(incomplete.isAllCompleted)

        val complete = order(
            mat(qty = 5, done = 5, itemNo = "a"),
            mat(qty = 5, done = 7, cat = MaterialCategory.CENTER, itemNo = "b"),
        )
        assertTrue(complete.isAllCompleted)
    }

    @Test fun `anomaly row keeps isAllCompleted false`() {
        val wo = order(
            mat(qty = 5, done = 5, itemNo = "a"),
            mat(qty = 0, done = 0, cat = MaterialCategory.AUTO, itemNo = "b"), // anomaly, not complete
        )
        assertFalse(wo.isAllCompleted)
    }

    // --- empty order: the dedicated branch flag, NOT isAllCompleted, gates submit ---
    @Test fun `empty order reports isAllCompleted true but isEmpty true`() {
        val wo = order()
        assertTrue(wo.materials.isEmpty())
        // 0 == 0 makes isAllCompleted true; the UI must branch on isEmpty FIRST.
        assertTrue(wo.isAllCompleted)
    }

    @Test fun `category filter returns only that bucket`() {
        val wo = order(
            mat(cat = MaterialCategory.CABLE, itemNo = "a"),
            mat(cat = MaterialCategory.CENTER, itemNo = "b"),
            mat(cat = MaterialCategory.CENTER, itemNo = "c"),
            mat(cat = MaterialCategory.AUTO, itemNo = "d"),
        )
        assertEquals(1, wo.materialsIn(MaterialCategory.CABLE).size)
        assertEquals(2, wo.materialsIn(MaterialCategory.CENTER).size)
        assertEquals(1, wo.materialsIn(MaterialCategory.AUTO).size)
    }

    @Test fun `category completed count for badge`() {
        val wo = order(
            mat(qty = 5, done = 5, cat = MaterialCategory.CENTER, itemNo = "a"),
            mat(qty = 5, done = 1, cat = MaterialCategory.CENTER, itemNo = "b"),
        )
        assertEquals(2, wo.materialsIn(MaterialCategory.CENTER).size)
        assertEquals(1, wo.completedCountIn(MaterialCategory.CENTER))
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.feature.picking.PickingLogicTest"`
Expected: FAIL — `Material` / `MaterialCategory` / `WorkOrder` unresolved reference.

- [ ] **Step 3: Write `PickingModels.kt`**

```kotlin
package com.bizlink.wmpda.feature.picking.domain

// 物料三桶,严格隔离,绝不串桶。映射到 UI 三页签。
enum class MaterialCategory(val displayName: String) {
    CABLE("断线物料"),
    CENTER("中央仓库"),
    AUTO("自动化库"),
}

/**
 * 单个物料(只读)。完成度服务端驱动(completedQuantity vs quantity)。
 * 业务规则全部下沉到这里的计算属性,由 PickingLogic 实现,便于纯单元测试。
 */
data class Material(
    val itemNo: String,
    val materialCode: String,
    val materialDesc: String,
    val quantity: Int,
    val completedQuantity: Int,
    val category: MaterialCategory,
) {
    val isCompleted: Boolean get() = PickingLogic.isCompleted(quantity, completedQuantity)
    val hasDataAnomaly: Boolean get() = PickingLogic.hasDataAnomaly(quantity, materialCode, materialDesc)
    val progress: Float get() = PickingLogic.progress(quantity, completedQuantity)
    val remainingQuantity: Int get() = PickingLogic.remaining(quantity, completedQuantity)
}

data class WorkOrder(
    val orderId: Int,
    val orderNo: String,
    val operationNo: String,
    val operationStatus: String,
    val cableItemCount: Int,
    val rawItemCount: Int,
    val rawMtrBatchCount: Int,
    val labelCount: Int,
    val materials: List<Material>, // 三桶合并,每个 Material 自带 category
) {
    val totalMaterialCount: Int get() = materials.size
    val completedMaterialCount: Int get() = materials.count { it.isCompleted }

    /** 0..1 总体进度。注意空工单返回 0(无意义,UI 走空工单分支)。 */
    val overallProgress: Float
        get() = if (totalMaterialCount == 0) 0f else completedMaterialCount.toFloat() / totalMaterialCount

    /**
     * 全部完成。⚠️ 空工单(0 物料)时 0==0 也为 true,
     * 所以提交按钮必须先判 materials.isEmpty() 走「无需校验」分支,不能只靠此标记。
     */
    val isAllCompleted: Boolean get() = completedMaterialCount == totalMaterialCount

    fun materialsIn(category: MaterialCategory): List<Material> =
        materials.filter { it.category == category }

    fun completedCountIn(category: MaterialCategory): Int =
        materialsIn(category).count { it.isCompleted }
}

/** 纯业务逻辑,无 Android 依赖,单元测试覆盖。照搬 Flutter simple_picking_entities.dart。 */
object PickingLogic {
    /** 需求量必须 > 0(0 需求量算数据异常,绝不算完成)。 */
    fun isCompleted(quantity: Int, completedQuantity: Int): Boolean =
        quantity > 0 && completedQuantity >= quantity

    /** 数据异常:需求量 <= 0,或物料码/描述为空白。视觉上红色,优先级高于完成/未完成。 */
    fun hasDataAnomaly(quantity: Int, materialCode: String, materialDesc: String): Boolean =
        quantity <= 0 || materialCode.isBlank() || materialDesc.isBlank()

    /** 进度 clamp 到 0..1。 */
    fun progress(quantity: Int, completedQuantity: Int): Float {
        if (quantity <= 0) return 0f
        return (completedQuantity.toFloat() / quantity).coerceIn(0f, 1f)
    }

    /** 剩余量 clamp 到 0..quantity(从不为负)。 */
    fun remaining(quantity: Int, completedQuantity: Int): Int =
        (quantity - completedQuantity).coerceIn(0, quantity.coerceAtLeast(0))
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.feature.picking.PickingLogicTest"`
Expected: PASS (19 tests).

- [ ] **Step 5: Commit**

```bash
cd /Users/benque/Projects/WMPDA
git add -A && git commit -m "feat(picking): add domain models + pure PickingLogic with tests"
```

---

## Task 2: DTOs + DTO→domain mapping (TDD)

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/picking/data/PickingDtos.kt`
- Test: `app/src/test/java/com/bizlink/wmpda/feature/picking/data/PickingMappingTest.kt`

- [ ] **Step 1: Write the failing test `PickingMappingTest.kt`** (Gson parses the real envelope; mapping keeps buckets isolated and applies defaults)

```kotlin
package com.bizlink.wmpda.feature.picking.data

import com.bizlink.wmpda.core.network.WmsEnvelope
import com.bizlink.wmpda.feature.picking.domain.MaterialCategory
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PickingMappingTest {

    private val gson = Gson()

    private fun parse(body: String): WmsEnvelope<WorkOrderDataDto> {
        val type = object : TypeToken<WmsEnvelope<WorkOrderDataDto>>() {}.type
        return gson.fromJson(body, type)
    }

    @Test fun `parses full envelope with three buckets`() {
        val body = """
        {"isSuccess":true,"message":"ok","data":{
          "orderId":7,"orderNo":"WO123","operationNo":"OP10","operationStatus":"open",
          "cableItemCount":1,"rawItemCount":2,"rawMtrBatchCount":3,"labelCount":4,
          "cableItems":[{"itemNo":"1","materialCode":"C1","materialDesc":"电缆","quantity":10,"completedQuantity":10}],
          "centerStockItems":[{"itemNo":"2","materialCode":"M2","materialDesc":"中央件","quantity":5,"completedQuantity":2}],
          "autoStockItems":[{"itemNo":"3","materialCode":"A3","materialDesc":"自动件","quantity":3,"completedQuantity":0}]
        }}
        """.trimIndent()
        val env = parse(body)
        assertEquals(true, env.isSuccess)
        val wo = env.data!!.toDomain()
        assertEquals(7, wo.orderId)
        assertEquals("WO123", wo.orderNo)
        assertEquals(3, wo.totalMaterialCount)
        // buckets isolated
        assertEquals(MaterialCategory.CABLE, wo.materialsIn(MaterialCategory.CABLE).single().category)
        assertEquals("C1", wo.materialsIn(MaterialCategory.CABLE).single().materialCode)
        assertEquals(MaterialCategory.CENTER, wo.materialsIn(MaterialCategory.CENTER).single().category)
        assertEquals(MaterialCategory.AUTO, wo.materialsIn(MaterialCategory.AUTO).single().category)
    }

    @Test fun `missing lists default empty and counts default zero`() {
        val body = """
        {"isSuccess":true,"message":"ok","data":{
          "orderId":1,"orderNo":"WO0","operationNo":"OP1","operationStatus":"open"
        }}
        """.trimIndent()
        val wo = parse(body).data!!.toDomain()
        assertEquals(0, wo.totalMaterialCount)
        assertEquals(0, wo.labelCount)
        assertEquals(0, wo.cableItemCount)
    }

    @Test fun `item numeric fields default to zero when absent`() {
        val body = """
        {"isSuccess":true,"message":"ok","data":{
          "orderId":1,"orderNo":"WO0","operationNo":"OP1","operationStatus":"open",
          "cableItems":[{"itemNo":"1","materialCode":"X","materialDesc":"y"}]
        }}
        """.trimIndent()
        val m = parse(body).data!!.toDomain().materialsIn(MaterialCategory.CABLE).single()
        assertEquals(0, m.quantity)
        assertEquals(0, m.completedQuantity)
    }

    @Test fun `failure envelope has null data`() {
        val body = """{"isSuccess":false,"message":"工单不存在","data":null}"""
        val env = parse(body)
        assertEquals(false, env.isSuccess)
        assertEquals("工单不存在", env.message)
        assertTrue(env.data == null)
    }

    @Test fun `submit request serializes expected keys`() {
        val req = SubmitVerfRequest(
            workOrderId = 7, operation = "OP10", status = "verfSuccess",
            workCenter = "WCX", updateOn = "2026-06-01T08:00:00", updateBy = "E001",
        )
        val json = gson.toJson(req)
        assertTrue(json.contains("\"workOrderId\":7"))
        assertTrue(json.contains("\"operation\":\"OP10\""))
        assertTrue(json.contains("\"status\":\"verfSuccess\""))
        assertTrue(json.contains("\"workCenter\":\"WCX\""))
        assertTrue(json.contains("\"updateBy\":\"E001\""))
        assertTrue(json.contains("\"updateOn\":\"2026-06-01T08:00:00\""))
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.feature.picking.data.PickingMappingTest"`
Expected: FAIL — `WorkOrderDataDto` / `SubmitVerfRequest` / `toDomain` unresolved.

- [ ] **Step 3: Write `PickingDtos.kt`**

```kotlin
package com.bizlink.wmpda.feature.picking.data

import com.bizlink.wmpda.feature.picking.domain.Material
import com.bizlink.wmpda.feature.picking.domain.MaterialCategory
import com.bizlink.wmpda.feature.picking.domain.WorkOrder

// GET /api/WorkOrderPickVerf?orderno=<no> 的 data 负载。
// 数值缺省 0,列表缺省空(照搬 Flutter 的 ?? 0 / ?? [])。
// Gson 对缺省字段不会报错;orderId/orderNo/operationNo 由后端保证非空。
data class WorkOrderDataDto(
    val orderId: Int = 0,
    val orderNo: String = "",
    val operationNo: String = "",
    val operationStatus: String = "",
    val cableItemCount: Int = 0,
    val rawItemCount: Int = 0,
    val rawMtrBatchCount: Int = 0,
    val labelCount: Int = 0,
    val cableItems: List<MaterialItemDto>? = null,
    val centerStockItems: List<MaterialItemDto>? = null,
    val autoStockItems: List<MaterialItemDto>? = null,
) {
    fun toDomain(): WorkOrder = WorkOrder(
        orderId = orderId,
        orderNo = orderNo,
        operationNo = operationNo,
        operationStatus = operationStatus,
        cableItemCount = cableItemCount,
        rawItemCount = rawItemCount,
        rawMtrBatchCount = rawMtrBatchCount,
        labelCount = labelCount,
        materials = buildList {
            addAll((cableItems ?: emptyList()).map { it.toDomain(MaterialCategory.CABLE) })
            addAll((centerStockItems ?: emptyList()).map { it.toDomain(MaterialCategory.CENTER) })
            addAll((autoStockItems ?: emptyList()).map { it.toDomain(MaterialCategory.AUTO) })
        },
    )
}

data class MaterialItemDto(
    val itemNo: String = "",
    val materialCode: String = "",
    val materialDesc: String = "",
    val quantity: Int = 0,
    val completedQuantity: Int = 0,
) {
    fun toDomain(category: MaterialCategory): Material = Material(
        itemNo = itemNo,
        materialCode = materialCode,
        materialDesc = materialDesc,
        quantity = quantity,
        completedQuantity = completedQuantity,
        category = category,
    )
}

// PUT /api/WorkOrderPickVerf body。status 永远 'verfSuccess'。
// workCenter/updateBy 来自 SessionManager,不在此硬编码。
data class SubmitVerfRequest(
    val workOrderId: Int,
    val operation: String,
    val status: String,
    val workCenter: String,
    val updateOn: String, // ISO-8601
    val updateBy: String,
)
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.feature.picking.data.PickingMappingTest"`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(picking): add WMS DTOs + DTO→domain mapping with tests"
```

---

## Task 3: Extend WmsApi with the two WorkOrderPickVerf endpoints

**Files:**
- Modify: `app/src/main/java/com/bizlink/wmpda/core/network/WmsApi.kt`

After Plan 1, `WmsApi.kt` contains only `login`. Add the two picking endpoints (additive). The GET uses the typed `WmsEnvelope<WorkOrderDataDto>`; the PUT uses raw `ResponseBody` so `ResponseInterpreter` reads the command outcome and we can surface the server `message`.

- [ ] **Step 1: Read the current `WmsApi.kt` to confirm its exact content**

Run: `cat /Users/benque/Projects/WMPDA/app/src/main/java/com/bizlink/wmpda/core/network/WmsApi.kt`
Expected: shows the interface with the single `login` method and imports for `LoginRequest`, `ResponseBody`, `Response`, `Body`, `POST` (per Plan 1 Task 4 Step 6).

- [ ] **Step 2: Add the two endpoints (ADDITIVE — do NOT rewrite the file)**

> Plans 3 (linestock) and 4 (warehouse) also append to this same `WmsApi.kt`. Always ADD methods/imports; never replace the whole file, so the three plans compose in any execution order.

Add these imports to the top of `WmsApi.kt` (alongside the Plan-1 imports):

```kotlin
import com.bizlink.wmpda.feature.picking.data.SubmitVerfRequest
import com.bizlink.wmpda.feature.picking.data.WorkOrderDataDto
import retrofit2.http.GET
import retrofit2.http.PUT
import retrofit2.http.Query
```

Add these two functions inside the `interface WmsApi { … }` body, immediately after `login`:

```kotlin
    // 合箱校验 — 取工单详情(类型化读)。base URL 来自 NetworkClient/SessionManager,用相对路径。
    @GET("api/WorkOrderPickVerf")
    suspend fun getWorkOrderPickVerf(
        @Query("orderno") orderNo: String,
    ): Response<WmsEnvelope<WorkOrderDataDto>>

    // 合箱校验 — 提交校验结果(命令类,原始 body 交给 ResponseInterpreter)。
    @PUT("api/WorkOrderPickVerf")
    suspend fun submitWorkOrderPickVerf(
        @Body body: SubmitVerfRequest,
    ): Response<ResponseBody>
```

- [ ] **Step 3: Build to verify the API compiles against the DTOs**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL` (picking DTOs from Task 2 resolve).

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(network): add WorkOrderPickVerf GET/PUT to WmsApi"
```

---

## Task 4: PickingRepository (no cache; fetch fresh; surface server message)

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/picking/data/PickingRepository.kt`

This re-encodes the v1.8.0 cache-pollution lessons directly: **no in-memory `Map`**, fetch fresh every call, never return stale data on error. On GET failure it returns `LoadResult.Failed(serverMessage)`; on submit failure it surfaces the interpreted Chinese `message`.

- [ ] **Step 1: Write `PickingRepository.kt`**

```kotlin
package com.bizlink.wmpda.feature.picking.data

import android.util.Log
import com.bizlink.wmpda.core.network.NetworkClient
import com.bizlink.wmpda.core.network.ResponseInterpreter
import com.bizlink.wmpda.core.network.WmsEnvelope
import com.bizlink.wmpda.core.network.WmsResult
import com.bizlink.wmpda.feature.picking.domain.WorkOrder
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

/**
 * 合箱校验仓储。在线模型,**绝不缓存**:
 * - 每次 load 直接打 WMS,失败抛错(返回 Failed),从不回退旧数据(v1.8.0 缓存污染教训)。
 * - 单一实例由 NavGraph 内的同一个 ViewModel 持有,杜绝多入口建多份缓存。
 */
class PickingRepository(
    private val network: NetworkClient,
) {
    private val gson = Gson()

    sealed class LoadResult {
        data class Ok(val workOrder: WorkOrder) : LoadResult()
        data class Failed(val message: String) : LoadResult()
    }

    sealed class SubmitResult {
        data class Ok(val message: String) : SubmitResult()
        data class Failed(val message: String) : SubmitResult()
        object AuthExpired : SubmitResult()
    }

    /** GET /api/WorkOrderPickVerf?orderno=<no> — 每次拉新。 */
    suspend fun loadWorkOrder(orderNo: String): LoadResult {
        return runCatching {
            val response = network.api().getWorkOrderPickVerf(orderNo.trim())
            val env: WmsEnvelope<WorkOrderDataDto>? = response.body()

            if (!response.isSuccessful) {
                // 尝试从 errorBody 解析服务端中文 message
                val msg = parseErrorMessage(response.errorBody()?.string())
                    ?: "获取工单失败: HTTP ${response.code()}"
                return@runCatching LoadResult.Failed(msg)
            }
            if (env == null) return@runCatching LoadResult.Failed("登录响应解析失败")
            if (env.isSuccess == false) {
                // isSuccess=false 视同错误,透传服务端 message(portingNotes 要求)。
                return@runCatching LoadResult.Failed(env.message ?: "工单加载失败")
            }
            val data = env.data
                ?: return@runCatching LoadResult.Failed(env.message ?: "工单数据为空")
            LoadResult.Ok(data.toDomain())
        }.getOrElse { e ->
            Log.w("WMPDA", "loadWorkOrder error", e)
            LoadResult.Failed("网络异常：${e.message ?: "无法连接服务器"}")
        }
    }

    /** PUT /api/WorkOrderPickVerf — 提交 verfSuccess。 */
    suspend fun submitVerification(req: SubmitVerfRequest): SubmitResult {
        return runCatching {
            val response = network.api().submitWorkOrderPickVerf(req)
            val body = response.body()?.string() ?: response.errorBody()?.string()
            Log.i("WMPDA", "submit verf response[${response.code()}]: $body")

            when (val r = ResponseInterpreter.interpret(response.code(), body)) {
                WmsResult.Success, WmsResult.IdempotentSuccess ->
                    SubmitResult.Ok(parseMessage(body) ?: "验证提交成功！")
                WmsResult.AuthFailure -> SubmitResult.AuthExpired
                is WmsResult.BusinessFailure -> SubmitResult.Failed(r.msg)
                is WmsResult.RetryableFailure -> SubmitResult.Failed("服务器繁忙，请重试 (${r.cause})")
            }
        }.getOrElse { e ->
            Log.w("WMPDA", "submitVerification error", e)
            SubmitResult.Failed("网络异常：${e.message ?: "无法连接服务器"}")
        }
    }

    /** 从 {isSuccess,message,data} 壳里取 message。 */
    private fun parseMessage(body: String?): String? {
        if (body.isNullOrBlank()) return null
        return runCatching {
            val type = object : TypeToken<WmsEnvelope<Any>>() {}.type
            gson.fromJson<WmsEnvelope<Any>>(body, type)?.message
        }.getOrNull()?.takeIf { it.isNotBlank() }
    }

    private fun parseErrorMessage(body: String?): String? = parseMessage(body)
}
```

- [ ] **Step 2: Build to verify the repository compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(picking): add PickingRepository (online, no cache, server message passthrough)"
```

---

## Task 5: Register PickingRepository in AppContainer

**Files:**
- Modify: `app/src/main/java/com/bizlink/wmpda/AppContainer.kt`

Add the repository as a `by lazy` property mirroring `authRepository` (Plan 1 contract: ViewModels reach deps via `AppContainer.<x>`). A single `AppContainer` instance ⇒ a single repository ⇒ the single-instance invariant from bugLessons is satisfied for free.

- [ ] **Step 1: Read the current `AppContainer.kt`**

Run: `cat /Users/benque/Projects/WMPDA/app/src/main/java/com/bizlink/wmpda/AppContainer.kt`
Expected: the slim version from Plan 1 Task 6 Step 2 (has `sessionManager`, `networkClient`, `authRepository`, `scanFlow`, `init`, `context`).

- [ ] **Step 2: Add the import**

In `AppContainer.kt`, after the existing import line `import com.bizlink.wmpda.feature.auth.data.AuthRepository`, add:

```kotlin
import com.bizlink.wmpda.feature.picking.data.PickingRepository
```

- [ ] **Step 3: Add the lazy property**

Immediately after the existing `authRepository` block:

```kotlin
    val authRepository: AuthRepository by lazy {
        AuthRepository(network = networkClient, session = sessionManager)
    }
```

insert:

```kotlin
    val pickingRepository: PickingRepository by lazy {
        PickingRepository(network = networkClient)
    }
```

- [ ] **Step 4: Build to verify**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(di): wire PickingRepository into AppContainer"
```

---

## Task 6: PickingViewModel + PickingUiState

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/picking/ui/PickingViewModel.kt`

Mirrors the BLoC state machine (Initial / Loading / Loaded / Submitting / Submitted / Error) as a single immutable `PickingUiState` with a `status` enum. Collects `AppContainer.scanFlow` in `init` to accept hardware scans on the input step. Re-encodes the bugLessons: identity from `SessionManager`, empty-order branch flag, auto-revert-after-2s on submit/validation error, fetch fresh (no cache).

- [ ] **Step 1: Write `PickingViewModel.kt`**

```kotlin
package com.bizlink.wmpda.feature.picking.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bizlink.wmpda.AppContainer
import com.bizlink.wmpda.feature.picking.data.PickingRepository
import com.bizlink.wmpda.feature.picking.data.SubmitVerfRequest
import com.bizlink.wmpda.feature.picking.domain.WorkOrder
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.OffsetDateTime
import java.time.format.DateTimeFormatter

enum class PickingStatus { INPUT, LOADING, LOADED, SUBMITTING, SUBMITTED, ERROR }

data class PickingUiState(
    val status: PickingStatus = PickingStatus.INPUT,
    val orderNoInput: String = "",
    val workOrder: WorkOrder? = null,
    val message: String? = null,         // 成功页/错误页要显示的服务端消息
    val lastOrderNo: String? = null,      // 错误页「重试」用
    val showConfirmDialog: Boolean = false,
) {
    /** 空工单分支:有工单但 0 物料 → 走「无需校验」,提交禁用(不靠 isAllCompleted)。 */
    val isEmptyOrder: Boolean
        get() = workOrder != null && workOrder.materials.isEmpty()

    /** 提交按钮可用:已加载 + 非空工单 + 全部完成。 */
    val canSubmit: Boolean
        get() = status == PickingStatus.LOADED &&
            workOrder != null &&
            !isEmptyOrder &&
            workOrder.isAllCompleted
}

class PickingViewModel : ViewModel() {

    private val repo: PickingRepository = AppContainer.pickingRepository

    private val _state = MutableStateFlow(PickingUiState())
    val state: StateFlow<PickingUiState> = _state.asStateFlow()

    init {
        // 硬件扫码头:仅在输入步接收,扫到即加载。
        viewModelScope.launch {
            AppContainer.scanFlow.collect { code ->
                if (_state.value.status == PickingStatus.INPUT) {
                    onOrderNoChange(code.trim())
                    load()
                }
            }
        }
    }

    fun onOrderNoChange(v: String) {
        _state.value = _state.value.copy(orderNoInput = v)
    }

    /** 加载工单。每次拉新;切工单无需清缓存(因为根本不缓存)。 */
    fun load() {
        val orderNo = _state.value.orderNoInput.trim()
        if (orderNo.isEmpty()) {
            _state.value = _state.value.copy(status = PickingStatus.ERROR, message = "请输入工单号", lastOrderNo = null)
            return
        }
        _state.value = _state.value.copy(status = PickingStatus.LOADING, message = null)
        viewModelScope.launch {
            when (val r = repo.loadWorkOrder(orderNo)) {
                is PickingRepository.LoadResult.Ok ->
                    _state.value = _state.value.copy(
                        status = PickingStatus.LOADED,
                        workOrder = r.workOrder,
                        message = null,
                        lastOrderNo = orderNo,
                    )
                is PickingRepository.LoadResult.Failed ->
                    _state.value = _state.value.copy(
                        status = PickingStatus.ERROR,
                        message = r.message,
                        lastOrderNo = orderNo,
                    )
            }
        }
    }

    fun requestSubmit() {
        if (_state.value.canSubmit) {
            _state.value = _state.value.copy(showConfirmDialog = true)
        }
    }

    fun dismissConfirm() {
        _state.value = _state.value.copy(showConfirmDialog = false)
    }

    /** 确认提交。防御性二次校验 isAllCompleted(照搬 BLoC)。 */
    fun confirmSubmit() {
        val s = _state.value
        val wo = s.workOrder ?: return
        _state.value = s.copy(showConfirmDialog = false)

        if (!wo.isAllCompleted || wo.materials.isEmpty()) {
            // 二次防御:理论上按钮已禁用,这里仍兜底。错误 2s 后自动回退到已加载。
            showTransientError("还有未完成的物料，请完成所有物料后再提交", revertTo = PickingStatus.LOADED)
            return
        }

        _state.value = s.copy(status = PickingStatus.SUBMITTING, message = null)
        viewModelScope.launch {
            val session = AppContainer.sessionManager.current()  // 身份来自 SessionManager,绝不硬编码
            val req = SubmitVerfRequest(
                workOrderId = wo.orderId,
                operation = wo.operationNo,
                status = "verfSuccess",
                workCenter = session.workCenter,
                updateOn = OffsetDateTime.now().format(DateTimeFormatter.ISO_OFFSET_DATE_TIME),
                updateBy = session.employeeId,
            )
            when (val r = repo.submitVerification(req)) {
                is PickingRepository.SubmitResult.Ok ->
                    _state.value = _state.value.copy(status = PickingStatus.SUBMITTED, message = r.message)
                is PickingRepository.SubmitResult.Failed ->
                    showTransientError(r.message, revertTo = PickingStatus.LOADED)
                PickingRepository.SubmitResult.AuthExpired ->
                    showTransientError("登录已过期，请重新登录后再提交", revertTo = PickingStatus.LOADED)
            }
        }
    }

    /** 错误页「重试」:重新加载上一个工单号。 */
    fun retry() {
        val last = _state.value.lastOrderNo ?: return
        _state.value = _state.value.copy(orderNoInput = last)
        load()
    }

    /** 「返回」/「继续下一个工单」:清空一切回到输入步(等价于 ResetPickingState)。 */
    fun reset() {
        _state.value = PickingUiState()
    }

    fun dismissError() {
        // 错误页常驻的清除入口(供 ErrorOverlay 关闭);回到上一个有效状态。
        val s = _state.value
        if (s.workOrder != null) {
            _state.value = s.copy(status = PickingStatus.LOADED, message = null)
        } else {
            reset()
        }
    }

    /** 显示错误,2 秒后若仍处于错误态则回退(照搬 BLoC 的提交/校验错误自动回退)。 */
    private fun showTransientError(msg: String, revertTo: PickingStatus) {
        _state.value = _state.value.copy(status = PickingStatus.ERROR, message = msg)
        viewModelScope.launch {
            delay(2000)
            val s = _state.value
            if (s.status == PickingStatus.ERROR && s.workOrder != null) {
                _state.value = s.copy(status = revertTo, message = null)
            }
        }
    }
}
```

- [ ] **Step 2: Build to verify the ViewModel compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(picking): add PickingViewModel + PickingUiState state machine"
```

---

## Task 7: MaterialItemRow (read-only material card)

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/picking/ui/MaterialItemRow.kt`

Read-only port of `SimpleMaterialItemWidget`: status precedence 数据异常(红) > 已完成(绿) > 未完成(橙); optional red anomaly banner; materialCode bold + desc; circular status icon; three quantity columns 需求/完成/剩余. Uses theme tokens only (no raw hex) — reusing `StatusError`, `StatusOnline`, `StatusWarning` and their `*Container` shades from Plan 1's `Color.kt`.

- [ ] **Step 1: Write `MaterialItemRow.kt`**

```kotlin
package com.bizlink.wmpda.feature.picking.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.WarningAmber
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.bizlink.wmpda.core.theme.OnSurface
import com.bizlink.wmpda.core.theme.OnSurfaceDim
import com.bizlink.wmpda.core.theme.OutlineSoft
import com.bizlink.wmpda.core.theme.Primary
import com.bizlink.wmpda.core.theme.StatusError
import com.bizlink.wmpda.core.theme.StatusErrorContainer
import com.bizlink.wmpda.core.theme.StatusOnline
import com.bizlink.wmpda.core.theme.StatusOnlineContainer
import com.bizlink.wmpda.core.theme.StatusWarning
import com.bizlink.wmpda.core.theme.StatusWarningContainer
import com.bizlink.wmpda.feature.picking.domain.Material

@Composable
fun MaterialItemRow(material: Material, modifier: Modifier = Modifier) {
    val anomaly = material.hasDataAnomaly
    val completed = material.isCompleted

    // 状态优先级:数据异常 > 已完成 > 未完成。
    val container: Color
    val accent: Color
    val icon: ImageVector
    when {
        anomaly -> { container = StatusErrorContainer; accent = StatusError; icon = Icons.Filled.ErrorOutline }
        completed -> { container = StatusOnlineContainer; accent = StatusOnline; icon = Icons.Filled.Check }
        else -> { container = StatusWarningContainer; accent = StatusWarning; icon = Icons.Filled.Close }
    }

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        colors = CardDefaults.cardColors(containerColor = container),
        border = BorderStroke(1.dp, OutlineSoft),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
    ) {
        Column(Modifier.fillMaxWidth().padding(16.dp)) {
            if (anomaly) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Icon(Icons.Filled.WarningAmber, contentDescription = null, tint = StatusError)
                    Text(
                        text = if (material.quantity <= 0) "数据异常：需求数量为 0" else "数据异常：物料信息不完整",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = StatusError,
                    )
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(
                        material.materialCode.ifBlank { "(无物料码)" },
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = OnSurface,
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        material.materialDesc.ifBlank { "(无描述)" },
                        style = MaterialTheme.typography.bodyMedium,
                        color = OnSurfaceDim,
                    )
                }
                Box(
                    Modifier.size(40.dp).clip(CircleShape).background(accent),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(24.dp))
                }
            }
            Spacer(Modifier.height(16.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,
            ) {
                QuantityCell("需求数量", material.quantity.toString(),
                    if (anomaly) StatusError else Primary)
                QuantityCell("完成数量", material.completedQuantity.toString(),
                    if (anomaly) StatusError else if (completed) StatusOnline else StatusWarning)
                QuantityCell("剩余数量", material.remainingQuantity.toString(),
                    if (anomaly) StatusError else if (material.remainingQuantity > 0) StatusError else StatusOnline)
            }
        }
    }
}

@Composable
private fun QuantityCell(label: String, value: String, valueColor: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(label, style = MaterialTheme.typography.bodySmall, color = OnSurfaceDim)
        Spacer(Modifier.height(4.dp))
        Text(value, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, color = valueColor)
    }
}
```

- [ ] **Step 2: Build to verify the row compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(picking): add read-only MaterialItemRow card"
```

---

## Task 8: PickingScreen (per-status UI, tabs, header, submit, dialogs)

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/picking/ui/PickingScreen.kt`

Single top-level screen that dispatches on `state.status`. Renders: Input, Loading, Loaded (header card + 3-tab TabBar with completed/total badges + bottom 返回/提交 bar; empty-order branch), Submitting, Submitted (success + 继续下一个工单), Error (server message + 重试/返回). Confirm dialog before PUT. Plays `FeedbackPlayer.SUCCESS`/`ERROR`.

- [ ] **Step 1: Write `PickingScreen.kt`**

```kotlin
package com.bizlink.wmpda.feature.picking.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.ScrollableTabRow
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.bizlink.wmpda.core.components.FeedbackPlayer
import com.bizlink.wmpda.core.components.QFCard
import com.bizlink.wmpda.core.components.StatusPill
import com.bizlink.wmpda.core.components.PillTone
import com.bizlink.wmpda.core.theme.OnSurfaceDim
import com.bizlink.wmpda.core.theme.OnPrimary
import com.bizlink.wmpda.core.theme.Primary
import com.bizlink.wmpda.core.theme.StatusError
import com.bizlink.wmpda.core.theme.StatusOnline
import com.bizlink.wmpda.feature.picking.domain.MaterialCategory
import com.bizlink.wmpda.feature.picking.domain.WorkOrder

@Composable
fun PickingScreen(
    onBack: () -> Unit,
    viewModel: PickingViewModel = viewModel(),
) {
    val state by viewModel.state.collectAsState()
    val context = LocalContext.current

    // 提交成功/错误反馈音。
    LaunchedEffect(state.status) {
        when (state.status) {
            PickingStatus.SUBMITTED -> FeedbackPlayer.play(context, FeedbackPlayer.Kind.SUCCESS)
            PickingStatus.ERROR -> FeedbackPlayer.play(context, FeedbackPlayer.Kind.ERROR)
            else -> Unit
        }
    }

    Box(Modifier.fillMaxSize()) {
        when (state.status) {
            PickingStatus.INPUT -> InputView(
                value = state.orderNoInput,
                onChange = viewModel::onOrderNoChange,
                onSubmit = viewModel::load,
                onBack = onBack,
            )
            PickingStatus.LOADING -> CenterMessage("正在加载工单信息...", spinner = true)
            PickingStatus.SUBMITTING -> CenterMessage(
                "正在提交验证...\n${state.workOrder?.orderNo ?: ""}", spinner = true,
            )
            PickingStatus.SUBMITTED -> SuccessView(
                orderNo = state.workOrder?.orderNo ?: "",
                message = state.message ?: "验证提交成功！",
                onContinue = viewModel::reset,
            )
            PickingStatus.ERROR -> ErrorView(
                message = state.message ?: "操作失败",
                canRetry = state.lastOrderNo != null,
                onRetry = viewModel::retry,
                onBack = viewModel::reset,
            )
            PickingStatus.LOADED -> {
                val wo = state.workOrder
                if (wo == null) {
                    CenterMessage("工单数据为空", spinner = false)
                } else if (state.isEmptyOrder) {
                    EmptyOrderView(orderNo = wo.orderNo, onBack = viewModel::reset)
                } else {
                    LoadedView(
                        workOrder = wo,
                        canSubmit = state.canSubmit,
                        onSubmit = viewModel::requestSubmit,
                        onBack = viewModel::reset,
                    )
                }
            }
        }
    }

    if (state.showConfirmDialog) {
        AlertDialog(
            onDismissRequest = viewModel::dismissConfirm,
            title = { Text("确认提交") },
            text = { Text("确认所有物料已完成验证并提交？") },
            confirmButton = { TextButton(onClick = viewModel::confirmSubmit) { Text("确认提交") } },
            dismissButton = { TextButton(onClick = viewModel::dismissConfirm) { Text("取消") } },
        )
    }
}

@Composable
private fun InputView(
    value: String,
    onChange: (String) -> Unit,
    onSubmit: () -> Unit,
    onBack: () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxSize().padding(horizontal = 32.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(Icons.Filled.QrCodeScanner, contentDescription = null, tint = Primary, modifier = Modifier.size(64.dp))
        Spacer(Modifier.height(16.dp))
        Text("合箱校验", style = MaterialTheme.typography.headlineMedium)
        Spacer(Modifier.height(8.dp))
        Text("扫码或输入工单号", style = MaterialTheme.typography.bodyMedium, color = OnSurfaceDim)
        Spacer(Modifier.height(32.dp))
        OutlinedTextField(
            value = value,
            onValueChange = onChange,
            label = { Text("工单号") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Go),
            keyboardActions = KeyboardActions(onGo = { onSubmit() }),
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(Modifier.height(24.dp))
        Button(
            onClick = onSubmit,
            modifier = Modifier.fillMaxWidth().height(56.dp),
        ) { Text("开始校验", style = MaterialTheme.typography.labelLarge) }
        Spacer(Modifier.height(12.dp))
        TextButton(onClick = onBack) { Text("返回工作台") }
    }
}

@Composable
private fun CenterMessage(text: String, spinner: Boolean) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        if (spinner) {
            CircularProgressIndicator()
            Spacer(Modifier.height(16.dp))
        }
        Text(text, style = MaterialTheme.typography.titleMedium, color = OnSurfaceDim)
    }
}

@Composable
private fun LoadedView(
    workOrder: WorkOrder,
    canSubmit: Boolean,
    onSubmit: () -> Unit,
    onBack: () -> Unit,
) {
    var tab by remember { mutableIntStateOf(0) }
    val categories = listOf(MaterialCategory.CABLE, MaterialCategory.CENTER, MaterialCategory.AUTO)

    Column(Modifier.fillMaxSize()) {
        HeaderCard(workOrder)
        ScrollableTabRow(selectedTabIndex = tab, edgePadding = 12.dp) {
            categories.forEachIndexed { index, cat ->
                val total = workOrder.materialsIn(cat).size
                val done = workOrder.completedCountIn(cat)
                Tab(
                    selected = tab == index,
                    onClick = { tab = index },
                    text = { Text("${cat.displayName} $done/$total") },
                )
            }
        }
        val current = workOrder.materialsIn(categories[tab])
        LazyColumn(
            modifier = Modifier.weight(1f).fillMaxWidth(),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            if (current.isEmpty()) {
                item { Text("本类别无物料", style = MaterialTheme.typography.bodyMedium, color = OnSurfaceDim) }
            } else {
                items(current, key = { it.itemNo + it.category.name }) { m ->
                    MaterialItemRow(m)
                }
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            OutlinedButton(onClick = onBack, modifier = Modifier.weight(1f).height(56.dp)) {
                Text("返回")
            }
            Button(
                onClick = onSubmit,
                enabled = canSubmit,
                modifier = Modifier.weight(2f).height(56.dp),
            ) {
                if (!canSubmit) {
                    Icon(Icons.Filled.Block, contentDescription = null, modifier = Modifier.size(20.dp))
                    Spacer(Modifier.size(8.dp))
                    Text("任务未完成", style = MaterialTheme.typography.labelLarge)
                } else {
                    Text("提交验证", style = MaterialTheme.typography.labelLarge)
                }
            }
        }
    }
}

@Composable
private fun HeaderCard(wo: WorkOrder) {
    QFCard(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
        Column(Modifier.fillMaxWidth().padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("工单 ${wo.orderNo}", style = MaterialTheme.typography.titleLarge, modifier = Modifier.weight(1f))
                Text("工序 ${wo.operationNo}", style = MaterialTheme.typography.bodyMedium, color = OnSurfaceDim)
            }
            Spacer(Modifier.height(8.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "完成 ${wo.completedMaterialCount}/${wo.totalMaterialCount}",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.weight(1f),
                )
                val pct = (wo.overallProgress * 100).toInt()
                Text("$pct%", style = MaterialTheme.typography.titleMedium, color = Primary)
            }
            Spacer(Modifier.height(6.dp))
            LinearProgressIndicator(
                progress = { wo.overallProgress },
                modifier = Modifier.fillMaxWidth().height(6.dp),
            )
            Spacer(Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("标签数 ${wo.labelCount}", style = MaterialTheme.typography.bodySmall, color = OnSurfaceDim)
                Text("原料批次 ${wo.rawMtrBatchCount}", style = MaterialTheme.typography.bodySmall, color = OnSurfaceDim)
                if (wo.isAllCompleted) {
                    StatusPill(text = "ALL DONE", tone = PillTone.ONLINE)
                }
            }
        }
    }
}

@Composable
private fun EmptyOrderView(orderNo: String, onBack: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(Icons.Filled.Inventory2, contentDescription = null, tint = OnSurfaceDim, modifier = Modifier.size(72.dp))
        Spacer(Modifier.height(16.dp))
        Text("工单 $orderNo", style = MaterialTheme.typography.titleLarge)
        Spacer(Modifier.height(8.dp))
        Text("无需校验", style = MaterialTheme.typography.headlineSmall, color = Primary)
        Spacer(Modifier.height(8.dp))
        Text("该工单没有需要校验的物料", style = MaterialTheme.typography.bodyMedium, color = OnSurfaceDim)
        Spacer(Modifier.height(32.dp))
        Button(onClick = onBack, enabled = false, modifier = Modifier.fillMaxWidth().height(56.dp)) {
            Text("无需提交")
        }
        Spacer(Modifier.height(12.dp))
        OutlinedButton(onClick = onBack, modifier = Modifier.fillMaxWidth().height(56.dp)) {
            Text("返回")
        }
    }
}

@Composable
private fun SuccessView(orderNo: String, message: String, onContinue: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(Icons.Filled.CheckCircle, contentDescription = null, tint = StatusOnline, modifier = Modifier.size(88.dp))
        Spacer(Modifier.height(16.dp))
        Text("验证提交成功！", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        Text("工单 $orderNo", style = MaterialTheme.typography.titleMedium, color = OnSurfaceDim)
        Spacer(Modifier.height(8.dp))
        Text(message, style = MaterialTheme.typography.bodyMedium, color = OnSurfaceDim)
        Spacer(Modifier.height(40.dp))
        Button(onClick = onContinue, modifier = Modifier.fillMaxWidth().height(56.dp)) {
            Text("继续下一个工单", style = MaterialTheme.typography.labelLarge)
        }
    }
}

@Composable
private fun ErrorView(
    message: String,
    canRetry: Boolean,
    onRetry: () -> Unit,
    onBack: () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(Icons.Filled.Block, contentDescription = null, tint = StatusError, modifier = Modifier.size(72.dp))
        Spacer(Modifier.height(16.dp))
        Text("操作失败", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        // 服务端中文 message 原样透传。
        Text(message, style = MaterialTheme.typography.bodyMedium, color = OnSurfaceDim)
        Spacer(Modifier.height(32.dp))
        if (canRetry) {
            Button(onClick = onRetry, modifier = Modifier.fillMaxWidth().height(56.dp)) {
                Text("重试", style = MaterialTheme.typography.labelLarge)
            }
            Spacer(Modifier.height(12.dp))
        }
        OutlinedButton(onClick = onBack, modifier = Modifier.fillMaxWidth().height(56.dp)) {
            Text("返回")
        }
    }
}
```

Note: `OnPrimary` is imported for parity with other screens but the success/error buttons use default Material colors; if Android Studio flags `OnPrimary` as unused, remove that single import line — it is not load-bearing.

- [ ] **Step 2: Build to verify the screen compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(picking): add PickingScreen (input/loaded/tabs/empty/success/error + confirm dialog)"
```

---

## Task 9: Replace the Routes.PICKING placeholder in NavGraph

**Files:**
- Modify: `app/src/main/java/com/bizlink/wmpda/core/nav/NavGraph.kt`

Plan 1's `NavGraph.kt` routes all feature destinations through one placeholder block:
```kotlin
listOf(
    Routes.PICKING, Routes.STOCK_QUERY, Routes.SHELVING, Routes.REMOVAL,
    Routes.RECEIVING, Routes.RETURN, Routes.WAREHOUSE_INBOUND, Routes.WAREHOUSE_RETURN,
).forEach { route -> composable(route) { Box(... Text("「$route」待实现") ) } }
```
Remove `Routes.PICKING` from that list and add a real `composable(Routes.PICKING) { PickingScreen(...) }`.

- [ ] **Step 1: Add the import**

In `NavGraph.kt`, alongside the existing feature imports (after `import com.bizlink.wmpda.feature.workbench.ui.WorkbenchScreen`), add:

```kotlin
import com.bizlink.wmpda.feature.picking.ui.PickingScreen
```

- [ ] **Step 2: Add the real PICKING destination**

Immediately before the placeholder `listOf(...).forEach { route -> ... }` block, add:

```kotlin
        composable(Routes.PICKING) {
            PickingScreen(onBack = { navController.popBackStack() })
        }
```

- [ ] **Step 3: Remove `Routes.PICKING` from the placeholder list**

Change the placeholder list from:

```kotlin
        listOf(
            Routes.PICKING, Routes.STOCK_QUERY, Routes.SHELVING, Routes.REMOVAL,
            Routes.RECEIVING, Routes.RETURN, Routes.WAREHOUSE_INBOUND, Routes.WAREHOUSE_RETURN,
        ).forEach { route ->
```

to (drop `Routes.PICKING`):

```kotlin
        listOf(
            Routes.STOCK_QUERY, Routes.SHELVING, Routes.REMOVAL,
            Routes.RECEIVING, Routes.RETURN, Routes.WAREHOUSE_INBOUND, Routes.WAREHOUSE_RETURN,
        ).forEach { route ->
```

- [ ] **Step 4: Build to verify navigation wiring compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 5: Run the full unit-test suite (regression)**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest`
Expected: PASS — Plan 1's 28 tests + PickingLogicTest (19) + PickingMappingTest (5) = 52 tests green.

- [ ] **Step 6: Manual device verification**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:installDebug` then launch.
Manual (device connected to a reachable WMS): Login → Workbench → tap 合箱校验. Expected:
- Input screen shows; type/scan a real work order number → 开始校验.
- A populated order shows the header card, three tabs with `done/total` badges, read-only material rows colored red(异常)/绿(完成)/橙(未完成). Submit button is disabled ("任务未完成") unless every material is complete.
- An order with 0 materials shows the "无需校验" screen with a disabled "无需提交" button (NOT an error, NOT an accidental submit).
- A nonexistent order surfaces the server's Chinese error message verbatim with 重试/返回.
- When all complete, tapping 提交验证 → confirm dialog → 确认提交 → success screen "验证提交成功！" → 继续下一个工单 returns to a clean input screen.
(Without a reachable WMS, loading shows the network-error message — confirms the error path and that no stale data is shown.)

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat(nav): replace Routes.PICKING placeholder with real PickingScreen"
```

---

## Self-Review (performed during authoring)

- **Spec §5.3 coverage:** GET/PUT endpoints (Task 3); three-bucket isolation via `MaterialCategory` (Tasks 1–2, UI tabs Task 8); `isCompleted` with `quantity>0` guard, `hasDataAnomaly` precedence, `isAllCompleted`, progress/remaining clamps (Task 1, tested); empty-order branch (Tasks 6 `isEmptyOrder`/`canSubmit`, 8 `EmptyOrderView`); read-only rows (Task 7); `workCenter`/`updateBy` from `SessionManager` (Task 6); server message verbatim (Task 4 + Task 8 ErrorView); single StateFlow state machine (Task 6).
- **bugLessons re-encoded:** (1) no cache anywhere + fetch-fresh + never-stale-on-error → Task 4 repo has no `Map`, returns `Failed` on error; single repository instance via `AppContainer` lazy (Task 5) + single `PickingViewModel` per nav destination (Task 6/9). (2) `quantity>0` guard → `PickingLogic.isCompleted` + test `zero demand is NOT completed`. (3) anomaly red precedence → `hasDataAnomaly` + Task 7 `when` order anomaly→completed→incomplete. (4) empty-order dedicated branch not gated on `isAllCompleted` alone → `isEmptyOrder` checked before `canSubmit`; test `empty order reports isAllCompleted true`. (5) configurable identity → `session.workCenter`/`session.employeeId`. (6) server Chinese message verbatim → repo passthrough + ErrorView.
- **Type consistency:** `Material`/`WorkOrder`/`MaterialCategory`/`PickingLogic` (Task 1) used identically by DTO mapping (Task 2), ViewModel (Task 6), and UI (Tasks 7–8). `materialsIn`/`completedCountIn`/`isAllCompleted`/`overallProgress`/`remainingQuantity` names match across tasks. `PickingRepository.LoadResult.{Ok,Failed}` and `SubmitResult.{Ok,Failed,AuthExpired}` referenced consistently in ViewModel.
- **Plan-1 contracts reused, not redefined:** `WmsEnvelope`, `ResponseInterpreter`/`WmsResult`, `NetworkClient.api()`, `AppContainer`, `SessionManager.current()`, `scanFlow`, `QFCard`/`StatusPill`/`PillTone`/`FeedbackPlayer`, theme tokens, `Routes.PICKING`, NavGraph placeholder edit.
- **No placeholders:** every code step contains complete Kotlin; every gradle step states the exact command and expected output.

---

## Done criteria for Plan 2

- `./gradlew :app:assembleDebug` succeeds; `./gradlew :app:testDebugUnitTest` green (52 tests total: Plan 1's 28 + PickingLogicTest 19 + PickingMappingTest 5).
- `WmsApi` has `getWorkOrderPickVerf` (typed `WmsEnvelope<WorkOrderDataDto>`) and `submitWorkOrderPickVerf` (raw `ResponseBody`); both use relative paths against the SessionManager base URL.
- `AppContainer.pickingRepository` is the single repository instance; no in-memory order cache exists anywhere.
- Workbench → 合箱校验 opens the real `PickingScreen` (placeholder removed from NavGraph's list).
- Picking flow works end-to-end against `svcn5mesp01:8001`: scan/type → load fresh → three isolated tabs → read-only color-coded rows → submit gated on full completion (empty order → 无需校验, never auto-submits) → confirm dialog → success → continue; failures surface the server's Chinese message verbatim and never show stale data.
- Identity (`updateBy`/`workCenter`) is read from `SessionManager`; no `"operator"`/`"WC001"` literals at call sites.

## Hand-off note for other plans

- This plan ADDS to `WmsApi.kt` two methods importing `com.bizlink.wmpda.feature.picking.data.{WorkOrderDataDto, SubmitVerfRequest}`. Plans 3 (linestock) and 4 (warehouse) must keep these methods when they further extend `WmsApi` (additive edits only — read the file first, append, do not overwrite the picking methods).
- This plan REMOVES `Routes.PICKING` from the NavGraph placeholder `listOf(...)`. The remaining placeholder list still contains `STOCK_QUERY, SHELVING, REMOVAL, RECEIVING, RETURN, WAREHOUSE_INBOUND, WAREHOUSE_RETURN` for Plans 3–4 to replace the same way.
- Assumption other plans must know: `SubmitVerfRequest.updateOn` uses `OffsetDateTime.now().format(ISO_OFFSET_DATE_TIME)` (offset-aware ISO-8601). If linestock/warehouse writes need a timestamp, follow the same format for server consistency.
