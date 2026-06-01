# WMPDA Plan 3 — 断线线边管理 (Line Stock) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the five 断线线边管理 (Line Stock) sub-flows — 库存查询 / 电缆上架 / 电缆下架 / 电缆入库(收货) / 电缆退库 — to WMPDA as a `feature/linestock/` module that calls the real WMS over the Plan-1 network spine, with **one ViewModel + one immutable UiState + one route per flow** (no shared state union), and wires them into `core/nav/NavGraph.kt` by replacing the placeholder destinations for `Routes.STOCK_QUERY`, `Routes.SHELVING`, `Routes.REMOVAL`, `Routes.RECEIVING`, and `Routes.RETURN`.

**Architecture:** Online-only. A single `LineStockRepository` (added as a `by lazy` property on `AppContainer`) wraps the five WMS endpoints: typed reads via `WmsEnvelope<T>` + Gson (byBarcode / byMaterialCode / GetHandoverListByBarcode), and command/writes via `ResponseInterpreter` plus a typed `data==true` check (transfer / HandoverConfirm). Each flow has its own ViewModel exposing an immutable `…UiState` `StateFlow` (the **single source of truth** that holds the in-progress list) and a `SharedFlow<…Event>` for **one-shot** error/success/flash events that NEVER mutate the list. Hardware scans arrive via `AppContainer.scanFlow` collected in each ViewModel's `init`. Pure logic (validators, duplicate/already-at-location guards, material-query summary, response→result mapping) is extracted to plain Kotlin functions with JUnit tests written TDD-first.

**Tech Stack:** Kotlin 2.0.21 · Jetpack Compose (Material 3) · Retrofit 2.11 + OkHttp 4.12 + Gson · Coroutines/StateFlow/SharedFlow · JUnit4 + coroutines-test. Manual DI via `AppContainer`. No Room / WorkManager / offline queue.

**Spec:** `docs/superpowers/specs/2026-06-01-wmpda-warehouse-pda-rewrite-design.md` §5.4 (and §9 待确认 #5: 退库 magic-string `'RETURN'`).

**Depends on:** Plan 1 Foundation (`docs/superpowers/plans/2026-06-01-wmpda-foundation.md`). Reuse its contracts verbatim — do NOT redefine them:
- `com.bizlink.wmpda.AppContainer` (object service locator); add `lineStockRepository` as a `by lazy` property mirroring `authRepository`.
- `AppContainer.networkClient.api()` → `WmsApi` (ADD endpoints additively).
- `WmsEnvelope<T>(isSuccess, message, data)` for typed reads; `ResponseInterpreter.interpret(httpCode, body)` → `WmsResult` for command/writes.
- `AppContainer.sessionManager.current()` → `Session(... factoryId: Int ...)` — read `factoryId` here, NEVER hardcode `2`.
- `AppContainer.scanFlow: SharedFlow<String>` — collect in ViewModel `init`.
- Shared components `com.bizlink.wmpda.core.components`: `ScanCard`, `ErrorOverlay`/`OverlaySeverity`, `FlashOverlay`, `StatusPill`/`PillTone`, `QFCard`, `FeedbackPlayer`.
- Theme tokens `com.bizlink.wmpda.core.theme` (`Primary`, `OnSurfaceDim`, `StatusError`, `OnSurfaceMuted`, `OutlineSoft`, `StatusWarning`, `StatusOnline`, …) — reference tokens, never raw hex outside `Color.kt`.
- Routes already declared in `core/nav/Routes.kt`: `STOCK_QUERY="linestock"`, `SHELVING="linestock/shelving"`, `REMOVAL="linestock/removal"`, `RECEIVING="linestock/receiving"`, `RETURN="linestock/return"`.

**Reference source (read-only, DO NOT copy package names):** Flutter `lib/features/line_stock/` and QuickFill `app/src/main/java/com/quickfill/ui/`.

---

## File Structure

All paths under `/Users/benque/Projects/WMPDA/`. Kotlin sources under `app/src/main/java/com/bizlink/wmpda/`.

```
feature/linestock/
├── data/
│   ├── LineStockDtos.kt          # LineStockDto, HandoverItemDto, TransferRequest, HandoverConfirmRequest, CableItem, summary
│   ├── LineStockMapping.kt       # pure: DTO→domain, transfer-result decode, material summary, duplicate/already-at-loc guards, validators
│   └── LineStockRepository.kt    # 5 suspend fns → sealed results; reads factoryId from SessionManager
└── ui/
    ├── StockQueryViewModel.kt    # StockQueryUiState + StockQueryEvent
    ├── StockQueryScreen.kt       # /linestock landing (byBarcode / byMaterialCode)
    ├── ShelvingViewModel.kt      # ShelvingUiState + ShelvingEvent (scanned target location)
    ├── ShelvingScreen.kt         # /linestock/shelving
    ├── RemovalViewModel.kt       # RemovalUiState (fixed location 2200-100)
    ├── RemovalScreen.kt          # /linestock/removal
    ├── ReceivingViewModel.kt     # ReceivingUiState + ReceivingEvent (handover)
    ├── ReceivingScreen.kt        # /linestock/receiving
    ├── ReturnViewModel.kt        # ReturnUiState (magic string 'RETURN')
    ├── ReturnScreen.kt           # /linestock/return
    └── CableListItem.kt          # shared row composable (cable + handover variants) + StockInfoCard

core/network/WmsApi.kt            # MODIFY: add 5 endpoints (additive)
core/nav/NavGraph.kt              # MODIFY: replace 5 placeholders with real screens
AppContainer.kt                   # MODIFY: add lineStockRepository by lazy

test/java/com/bizlink/wmpda/feature/linestock/
├── LineStockMappingTest.kt       # validators, guards, transfer decode, summary
├── LineStockResponseParseTest.kt # Gson envelope parsing (barCode capital C, id|stockId, data:false)
└── LineStockViewModelTest.kt     # list-retention-on-error, duplicate rejection, already-at-location
```

**Responsibility boundaries:**
- `data/LineStockMapping.kt` — ALL pure decisions (no Android, no Retrofit): unit-tested first.
- `data/LineStockRepository.kt` — thin: call `WmsApi` → interpret → return a sealed result; the ONLY place `factoryId` is read from `SessionManager`.
- `ui/*ViewModel.kt` — one per flow; `StateFlow<UiState>` holds the list (single source of truth); `SharedFlow<Event>` for transient error/success/flash. Collects `AppContainer.scanFlow` in `init`.
- `ui/*Screen.kt` — pure Compose; clears the manual-entry field explicitly on success AND error (never self-clear).

---

## Pre-flight notes (read once)

- **factoryId:** read from `AppContainer.sessionManager.current().factoryId` (default 2 lives in `SessionManager`, not at call sites). Query param name is lowercase **`factoryid`** (also `materialcode`, `barcode`). The Flutter code hard-coded `2` (and the handover query hard-coded `factoryId:2` in the bloc) — do NOT replicate; thread it through the repository.
- **JSON casing (bug source):** WMS responses use **`barCode`** (capital C); request bodies use **`barcode`/`barCodes`** (lower). Stock id is **`id` OR `stockId`**. `byBarcode` `data` may be **`false`** (a JSON boolean, not an object) on not-found → decode to null → "未找到". Model these exactly in `LineStockDtos.kt` / `LineStockMapping.kt`.
- **Transfer success = `isSuccess==true` AND `data==true`.** A `200` with `isSuccess:true, data:false` is the business failure 「上架失败」. Do NOT assume HTTP 200 == success.
- **HandoverConfirm** returns the server `message` (e.g. 「标签收货确认完成！」) as the success payload; `data` is ignored.
- **Min lengths:** barcode ≥ 9, location ≥ 4, material ≥ 1. (Flutter constants said 1/1 but the field widgets and spec enforce 9/4/1 — honor 9/4/1.)
- **Fixed location:** Removal locks `'2200-100'` (线边库). Return uses the magic string `'RETURN'` via the SAME `transfer` endpoint (spec §9 #5 — keep magic string until backend confirms `returnToWMS`).
- **bugLessons re-encoded (see each task):** (1) per-flow ViewModel, no `runtimeType`/`previousState` recursion; (2) errors are one-shot events that never wipe the list; (3) duplicate-barcode rejection keeps list; (4) already-at-target rejection in shelving; (5) transfer needs `isSuccess && data==true`; (6) empty material list = error; (7) Return starts in an empty in-progress state (NOT Reset→Initial); (8) JSON casing; (9) explicit field-clear on success+error; (10) no debug prints.
- **Commit cadence:** one commit per task (final step). Conventional Commits, Chinese summary acceptable.
- **Test count baseline:** Plan 1 leaves 28 passing tests. This plan adds ~33 → total ~61.

---

## Task 1: Add the 5 LineStock endpoints to WmsApi

**Files:**
- Modify: `app/src/main/java/com/bizlink/wmpda/core/network/WmsApi.kt`
- Create: `app/src/main/java/com/bizlink/wmpda/feature/linestock/data/LineStockDtos.kt`

- [ ] **Step 1: Write `LineStockDtos.kt`** (DTOs + request bodies + domain value objects; note exact JSON casing)

```kotlin
package com.bizlink.wmpda.feature.linestock.data

import com.google.gson.annotations.SerializedName

// ---- Responses (typed reads via WmsEnvelope<T>) ----

// byBarcode / byMaterialCode item. Response field is 'barCode' (capital C).
// id may arrive as 'id' OR 'stockId' — Gson can only bind one name per field, so we
// model BOTH and resolve in mapping (LineStockMapping.resolveStockId).
data class LineStockDto(
    @SerializedName("id") val id: Int? = null,
    @SerializedName("stockId") val stockId: Int? = null,
    @SerializedName("materialCode") val materialCode: String? = null,
    @SerializedName("materialDesc") val materialDesc: String? = null,
    @SerializedName("quantity") val quantity: Double? = null,
    @SerializedName("lastQuantity") val lastQuantity: Double? = null, // 剩余
    @SerializedName("baseUnit") val baseUnit: String? = null,
    @SerializedName("batchCode") val batchCode: String? = null,
    @SerializedName("locationCode") val locationCode: String? = null,
    @SerializedName("locationDesc") val locationDesc: String? = null,
    @SerializedName("barCode") val barCode: String? = null, // 大 C
)

// GetHandoverListByBarcode item. Entity only keeps a subset; we model what we show.
data class HandoverItemDto(
    @SerializedName("id") val id: Int? = null,
    @SerializedName("materialCode") val materialCode: String? = null,
    @SerializedName("materialDesc") val materialDesc: String? = null,
    @SerializedName("baseUnit") val baseUnit: String? = null, // default 'M'
    @SerializedName("batchCode") val batchCode: String? = null,
    @SerializedName("barCode") val barCode: String? = null, // 大 C
    @SerializedName("quantity") val quantity: Double? = null,
    @SerializedName("lastQuantity") val lastQuantity: Double? = null,
)

// ---- Request bodies (lower-case 'barcode'/'barCodes', no factoryId in body) ----

data class TransferRequest(
    @SerializedName("locationCode") val locationCode: String,
    @SerializedName("barCodes") val barCodes: List<String>,
)

data class HandoverConfirmRequest(
    @SerializedName("barCodes") val barCodes: List<String>,
)

// ---- Domain value objects (UI-facing) ----

// A cable accumulated in the shelving/removal/return in-progress list.
data class CableItem(
    val barcode: String,
    val batchCode: String,
    val materialCode: String,
    val materialDesc: String,
    val quantity: Double,
    val baseUnit: String,
    val currentLocation: String,
) {
    val displayInfo: String get() = "$materialCode - $materialDesc"
    val quantityInfo: String get() = "$quantity $baseUnit"
}

// A handover (待入库) item accumulated in the receiving list.
data class HandoverItem(
    val barCode: String,
    val materialCode: String,
    val materialDesc: String,
    val baseUnit: String,
    val batchCode: String,
    val quantity: Double,
) {
    val quantityInfo: String get() = "$quantity $baseUnit"
}

// Per-batch row + header for the material-code query result.
data class MaterialBatch(
    val batchCode: String,
    val locationCode: String,
    val locationDesc: String,
    val inboundQuantity: Double, // quantity 入库数量
    val stockQuantity: Double,   // lastQuantity 库存数量(剩余)
    val usedQuantity: Double,    // quantity - lastQuantity 已用数量
    val baseUnit: String,
)

data class MaterialSummary(
    val materialCode: String,
    val batchCount: Int,
    val totalStock: Double, // Σ lastQuantity
    val batches: List<MaterialBatch>,
)
```

- [ ] **Step 2: Add the 5 endpoints to `WmsApi.kt`** (additive — keep the existing `login`)

Open `core/network/WmsApi.kt`. Add these imports at the top (alongside the existing imports):

```kotlin
import com.bizlink.wmpda.core.network.WmsEnvelope
import com.bizlink.wmpda.feature.linestock.data.HandoverConfirmRequest
import com.bizlink.wmpda.feature.linestock.data.HandoverItemDto
import com.bizlink.wmpda.feature.linestock.data.LineStockDto
import com.bizlink.wmpda.feature.linestock.data.TransferRequest
import retrofit2.http.GET
import retrofit2.http.Query
```

Add these functions inside the `interface WmsApi { … }` body (after `login`):

```kotlin
    // ---- 断线线边管理 LineStock ----

    // data may be a LineStock object OR boolean false on not-found.
    // We read it as raw ResponseBody so LineStockMapping can decode false→null safely
    // (Gson into WmsEnvelope<LineStockDto> would crash on data:false).
    @GET("api/LineStock/byBarcode")
    suspend fun lineStockByBarcode(
        @Query("barcode") barcode: String,
        @Query("factoryid") factoryId: Int,
    ): retrofit2.Response<okhttp3.ResponseBody>

    @GET("api/LineStock/byMaterialCode")
    suspend fun lineStockByMaterialCode(
        @Query("materialcode") materialCode: String,
        @Query("factoryid") factoryId: Int,
    ): retrofit2.Response<WmsEnvelope<List<LineStockDto>>>

    // transfer reused by 上架 / 下架(2200-100) / 退库(RETURN); decoded via ResponseInterpreter + data==true.
    @POST("api/LineStock/transfer")
    suspend fun lineStockTransfer(
        @Body body: TransferRequest,
    ): retrofit2.Response<okhttp3.ResponseBody>

    @GET("api/LineStock/GetHandoverListByBarcode")
    suspend fun handoverByBarcode(
        @Query("barcode") barcode: String,
        @Query("factoryid") factoryId: Int,
    ): retrofit2.Response<WmsEnvelope<HandoverItemDto>>

    @POST("api/LineStock/HandoverConfirm")
    suspend fun handoverConfirm(
        @Body body: HandoverConfirmRequest,
    ): retrofit2.Response<okhttp3.ResponseBody>
```

- [ ] **Step 3: Build to verify the API + DTOs compile**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Commit**

```bash
cd /Users/benque/Projects/WMPDA
git add -A && git commit -m "feat(linestock): add 5 LineStock endpoints to WmsApi + DTOs"
```

---

## Task 2: Pure mapping + validators + transfer decode (TDD)

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/linestock/data/LineStockMapping.kt`
- Test: `app/src/test/java/com/bizlink/wmpda/feature/linestock/LineStockMappingTest.kt`

- [ ] **Step 1: Write the failing test `LineStockMappingTest.kt`**

```kotlin
package com.bizlink.wmpda.feature.linestock

import com.bizlink.wmpda.feature.linestock.data.CableItem
import com.bizlink.wmpda.feature.linestock.data.LineStockDto
import com.bizlink.wmpda.feature.linestock.data.LineStockMapping
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class LineStockMappingTest {

    private fun dto(
        id: Int? = null, stockId: Int? = null, loc: String? = "Z-01",
        barCode: String? = "CB000000001", qty: Double? = 100.0, last: Double? = 60.0,
        unit: String? = "米", batch: String? = "B01", mc: String? = "M001", md: String? = "电缆A",
        locDesc: String? = "库区Z",
    ) = LineStockDto(id, stockId, mc, md, qty, last, unit, batch, loc, locDesc, barCode)

    // ---- validators ----
    @Test fun `barcode shorter than 9 is invalid`() {
        assertFalse(LineStockMapping.isValidBarcode("12345678"))
        assertTrue(LineStockMapping.isValidBarcode("123456789"))
    }
    @Test fun `location shorter than 4 is invalid`() {
        assertFalse(LineStockMapping.isValidLocation("ABC"))
        assertTrue(LineStockMapping.isValidLocation("2200-100"))
    }
    @Test fun `material code needs at least 1 char`() {
        assertFalse(LineStockMapping.isValidMaterial(""))
        assertTrue(LineStockMapping.isValidMaterial("M"))
    }

    // ---- id resolution (id OR stockId) ----
    @Test fun `resolveStockId prefers id then stockId`() {
        assertEquals(7, LineStockMapping.resolveStockId(dto(id = 7, stockId = 9)))
        assertEquals(9, LineStockMapping.resolveStockId(dto(id = null, stockId = 9)))
        assertNull(LineStockMapping.resolveStockId(dto(id = null, stockId = null)))
    }

    // ---- baseUnit defaulting ----
    @Test fun `cable defaults baseUnit to 米 when missing`() {
        val c = LineStockMapping.toCable(dto(unit = null))
        assertEquals("米", c.baseUnit)
    }

    // ---- duplicate guard (keeps list semantics: returns true if present) ----
    @Test fun `isDuplicate detects existing barcode`() {
        val list = listOf(cable("CB000000001"), cable("CB000000002"))
        assertTrue(LineStockMapping.isDuplicate(list, "CB000000001"))
        assertFalse(LineStockMapping.isDuplicate(list, "CB000000999"))
    }

    // ---- already-at-target guard (shelving only, when target set) ----
    @Test fun `alreadyAtTarget true when locations equal`() {
        assertTrue(LineStockMapping.isAlreadyAtTarget(currentLocation = "Z-09", target = "Z-09"))
    }
    @Test fun `alreadyAtTarget false when target null`() {
        assertFalse(LineStockMapping.isAlreadyAtTarget(currentLocation = "Z-09", target = null))
    }
    @Test fun `alreadyAtTarget false when different`() {
        assertFalse(LineStockMapping.isAlreadyAtTarget(currentLocation = "Z-09", target = "Z-10"))
    }

    // ---- transfer decode: success requires isSuccess && data==true ----
    @Test fun `transfer isSuccess true data true is true`() {
        assertTrue(LineStockMapping.decodeTransferData("""{"isSuccess":true,"message":"ok","data":true}"""))
    }
    @Test fun `transfer isSuccess true data false is false`() {
        assertFalse(LineStockMapping.decodeTransferData("""{"isSuccess":true,"message":"ok","data":false}"""))
    }
    @Test fun `transfer missing data is false`() {
        assertFalse(LineStockMapping.decodeTransferData("""{"isSuccess":true,"message":"ok"}"""))
    }
    @Test fun `transfer null or blank body is false`() {
        assertFalse(LineStockMapping.decodeTransferData(null))
        assertFalse(LineStockMapping.decodeTransferData(""))
    }

    // ---- byBarcode data can be boolean false (not-found) -> null ----
    @Test fun `decodeSingleStock returns null when data is false`() {
        val body = """{"isSuccess":false,"message":"未找到该物料的库存信息","data":false}"""
        assertNull(LineStockMapping.decodeSingleStock(body))
    }
    @Test fun `decodeSingleStock parses object with barCode capital C and stockId`() {
        val body = """{"isSuccess":true,"message":"查询成功","data":{"stockId":42,"materialCode":"M001","materialDesc":"电缆A","quantity":100,"lastQuantity":60,"baseUnit":"米","batchCode":"B01","locationCode":"Z-01","locationDesc":"库区Z","barCode":"CB000000001"}}"""
        val c = LineStockMapping.decodeSingleStock(body)!!
        assertEquals("CB000000001", c.barcode)
        assertEquals("Z-01", c.currentLocation)
        assertEquals(100.0, c.quantity, 0.001)
    }

    // ---- material summary: usedQuantity, totals, ordering ----
    @Test fun `materialSummary computes totals and used quantity`() {
        val list = listOf(
            dto(batch = "B01", qty = 100.0, last = 60.0),
            dto(batch = "B02", qty = 50.0, last = 50.0),
        )
        val s = LineStockMapping.toMaterialSummary("M001", list)
        assertEquals("M001", s.materialCode)
        assertEquals(2, s.batchCount)
        assertEquals(110.0, s.totalStock, 0.001) // 60 + 50
        assertEquals(40.0, s.batches[0].usedQuantity, 0.001) // 100 - 60
        assertEquals(0.0, s.batches[1].usedQuantity, 0.001)
    }

    private fun cable(bc: String) = CableItem(bc, "B01", "M001", "电缆A", 100.0, "米", "Z-01")
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.feature.linestock.LineStockMappingTest"`
Expected: FAIL — `LineStockMapping` unresolved reference.

- [ ] **Step 3: Write `LineStockMapping.kt`** (pure functions, no Android/Retrofit)

```kotlin
package com.bizlink.wmpda.feature.linestock.data

import com.bizlink.wmpda.core.network.WmsEnvelope
import com.google.gson.Gson
import com.google.gson.JsonParser
import com.google.gson.reflect.TypeToken

/**
 * Pure mapping + validation for LineStock. No Android, no Retrofit — fully unit-testable.
 * Re-encodes the Flutter business rules (duplicate guard, already-at-target, transfer
 * data==true, id|stockId, barCode casing, baseUnit defaults, material summary).
 */
object LineStockMapping {

    const val MIN_BARCODE = 9
    const val MIN_LOCATION = 4
    const val MIN_MATERIAL = 1
    const val DEFAULT_CABLE_UNIT = "米"
    const val DEFAULT_HANDOVER_UNIT = "M"

    private val gson = Gson()

    fun isValidBarcode(s: String): Boolean = s.trim().length >= MIN_BARCODE
    fun isValidLocation(s: String): Boolean = s.trim().length >= MIN_LOCATION
    fun isValidMaterial(s: String): Boolean = s.trim().length >= MIN_MATERIAL

    fun resolveStockId(dto: LineStockDto): Int? = dto.id ?: dto.stockId

    fun isDuplicate(list: List<CableItem>, barcode: String): Boolean =
        list.any { it.barcode == barcode }

    fun isDuplicateHandover(list: List<HandoverItem>, barcode: String): Boolean =
        list.any { it.barCode == barcode }

    /** Only meaningful when a target location is set. */
    fun isAlreadyAtTarget(currentLocation: String, target: String?): Boolean =
        target != null && currentLocation == target

    fun toCable(dto: LineStockDto): CableItem = CableItem(
        barcode = dto.barCode.orEmpty(),
        batchCode = dto.batchCode.orEmpty(),
        materialCode = dto.materialCode.orEmpty(),
        materialDesc = dto.materialDesc.orEmpty(),
        quantity = dto.quantity ?: 0.0,
        baseUnit = dto.baseUnit ?: DEFAULT_CABLE_UNIT,
        currentLocation = dto.locationCode.orEmpty(),
    )

    fun toHandover(dto: HandoverItemDto): HandoverItem = HandoverItem(
        barCode = dto.barCode.orEmpty(),
        materialCode = dto.materialCode.orEmpty(),
        materialDesc = dto.materialDesc.orEmpty(),
        baseUnit = dto.baseUnit ?: DEFAULT_HANDOVER_UNIT,
        batchCode = dto.batchCode.orEmpty(),
        quantity = dto.quantity ?: 0.0,
    )

    /** transfer / HandoverConfirm raw body → did data==true? (Plus isSuccess true.) */
    fun decodeTransferData(body: String?): Boolean {
        if (body.isNullOrBlank()) return false
        val json = runCatching { JsonParser.parseString(body).asJsonObject }.getOrNull() ?: return false
        val data = json.get("data")
        val dataTrue = data != null && data.isJsonPrimitive && data.asJsonPrimitive.isBoolean && data.asBoolean
        val successEl = json.get("isSuccess")
        val successTrue = successEl == null ||
            !(successEl.isJsonPrimitive && successEl.asJsonPrimitive.isBoolean) ||
            successEl.asBoolean
        return dataTrue && successTrue
    }

    /** byBarcode raw body → CableItem, or null when data is boolean false / not an object. */
    fun decodeSingleStock(body: String?): CableItem? {
        if (body.isNullOrBlank()) return null
        val json = runCatching { JsonParser.parseString(body).asJsonObject }.getOrNull() ?: return null
        val data = json.get("data")
        if (data == null || data.isJsonNull) return null
        if (data.isJsonPrimitive) return null // boolean false / string → not-found
        if (!data.isJsonObject) return null
        val dto = runCatching { gson.fromJson(data, LineStockDto::class.java) }.getOrNull() ?: return null
        return toCable(dto)
    }

    fun toMaterialSummary(materialCode: String, dtos: List<LineStockDto>): MaterialSummary {
        val batches = dtos.map { d ->
            val inbound = d.quantity ?: 0.0
            val stock = d.lastQuantity ?: inbound
            MaterialBatch(
                batchCode = d.batchCode.orEmpty(),
                locationCode = d.locationCode.orEmpty(),
                locationDesc = d.locationDesc.orEmpty(),
                inboundQuantity = inbound,
                stockQuantity = stock,
                usedQuantity = inbound - stock,
                baseUnit = d.baseUnit ?: DEFAULT_CABLE_UNIT,
            )
        }
        return MaterialSummary(
            materialCode = materialCode,
            batchCount = batches.size,
            totalStock = batches.sumOf { it.stockQuantity },
            batches = batches,
        )
    }

    /** Parse a typed envelope body when Retrofit handed us a WmsEnvelope (list/handover reads). */
    fun parseHandover(env: WmsEnvelope<HandoverItemDto>?): HandoverItem? =
        env?.data?.let { toHandover(it) }

    // Helper kept for symmetry with typed list reads (used by repository).
    fun parseMaterialList(body: String): List<LineStockDto> {
        val type = object : TypeToken<WmsEnvelope<List<LineStockDto>>>() {}.type
        return gson.fromJson<WmsEnvelope<List<LineStockDto>>>(body, type)?.data ?: emptyList()
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.feature.linestock.LineStockMappingTest"`
Expected: PASS (17 tests).

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(linestock): add pure mapping/validators/transfer-decode with tests"
```

---

## Task 3: Envelope parse tests (Gson casing — barCode / id|stockId / data:false) (TDD)

**Files:**
- Test: `app/src/test/java/com/bizlink/wmpda/feature/linestock/LineStockResponseParseTest.kt`

> No production code in this task — it locks the DTO Gson bindings so a casing regression fails loudly. (This re-encodes bugLesson #8.)

- [ ] **Step 1: Write `LineStockResponseParseTest.kt`**

```kotlin
package com.bizlink.wmpda.feature.linestock

import com.bizlink.wmpda.core.network.WmsEnvelope
import com.bizlink.wmpda.feature.linestock.data.HandoverItemDto
import com.bizlink.wmpda.feature.linestock.data.LineStockDto
import com.bizlink.wmpda.feature.linestock.data.LineStockMapping
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class LineStockResponseParseTest {

    private val gson = Gson()

    @Test fun `byMaterialCode envelope parses list with barCode capital C`() {
        val body = """{"isSuccess":true,"message":"查询成功","data":[
            {"id":1,"materialCode":"M001","materialDesc":"电缆A","quantity":100,"lastQuantity":60,"baseUnit":"米","batchCode":"B01","locationCode":"Z-01","locationDesc":"库区Z","barCode":"CB000000001"},
            {"stockId":2,"materialCode":"M001","materialDesc":"电缆A","quantity":50,"lastQuantity":50,"baseUnit":"米","batchCode":"B02","locationCode":"Z-02","locationDesc":"库区Z","barCode":"CB000000002"}
        ]}"""
        val type = object : TypeToken<WmsEnvelope<List<LineStockDto>>>() {}.type
        val env: WmsEnvelope<List<LineStockDto>> = gson.fromJson(body, type)
        assertEquals(2, env.data?.size)
        assertEquals("CB000000001", env.data!![0].barCode)
        assertEquals(1, LineStockMapping.resolveStockId(env.data!![0]))
        assertEquals(2, LineStockMapping.resolveStockId(env.data!![1])) // from stockId
    }

    @Test fun `empty material list yields not-found semantics`() {
        val body = """{"isSuccess":true,"message":"查询成功","data":[]}"""
        val list = LineStockMapping.parseMaterialList(body)
        assertTrue(list.isEmpty()) // ViewModel turns empty → 未找到 error
    }

    @Test fun `handover envelope parses single item with capital-C barCode`() {
        val body = """{"isSuccess":true,"message":"查询成功","data":{"id":5,"materialCode":"M001","materialDesc":"电缆A","baseUnit":"M","batchCode":"B01","barCode":"CB000000001","quantity":12,"lastQuantity":12}}"""
        val type = object : TypeToken<WmsEnvelope<HandoverItemDto>>() {}.type
        val env: WmsEnvelope<HandoverItemDto> = gson.fromJson(body, type)
        val item = LineStockMapping.parseHandover(env)!!
        assertEquals("CB000000001", item.barCode)
        assertEquals("M", item.baseUnit)
        assertEquals(12.0, item.quantity, 0.001)
    }

    @Test fun `byBarcode data false decodes to null not-found`() {
        assertNull(LineStockMapping.decodeSingleStock("""{"isSuccess":false,"message":"未找到","data":false}"""))
    }
}
```

- [ ] **Step 2: Run the test to verify it passes** (DTOs + mapping already exist)

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.feature.linestock.LineStockResponseParseTest"`
Expected: PASS (4 tests).

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "test(linestock): lock Gson casing (barCode/id|stockId/data:false)"
```

---

## Task 4: LineStockRepository + AppContainer wiring

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/linestock/data/LineStockRepository.kt`
- Modify: `app/src/main/java/com/bizlink/wmpda/AppContainer.kt`

- [ ] **Step 1: Write `LineStockRepository.kt`** (thin; reads factoryId from SessionManager; sealed results; no debug prints)

```kotlin
package com.bizlink.wmpda.feature.linestock.data

import com.bizlink.wmpda.core.network.NetworkClient
import com.bizlink.wmpda.core.network.ResponseInterpreter
import com.bizlink.wmpda.core.network.WmsResult
import com.bizlink.wmpda.core.session.SessionManager

/**
 * Online-only LineStock repository. One suspend fn per WMS endpoint.
 * - Reads + transfers go through ResponseInterpreter (command outcomes) and
 *   LineStockMapping (typed decode). factoryId comes from SessionManager — never hardcoded.
 * - Errors surface as sealed results; ViewModels turn them into one-shot events that
 *   never wipe the in-progress list.
 */
class LineStockRepository(
    private val network: NetworkClient,
    private val session: SessionManager,
) {
    sealed class StockResult {
        data class Found(val cable: CableItem) : StockResult()
        data class NotFound(val message: String) : StockResult()
        data class Error(val message: String) : StockResult()
    }

    sealed class MaterialResult {
        data class Found(val summary: MaterialSummary) : MaterialResult()
        data class NotFound(val message: String) : MaterialResult()
        data class Error(val message: String) : MaterialResult()
    }

    sealed class TransferResult {
        object Ok : TransferResult()
        data class Failed(val message: String) : TransferResult()
    }

    sealed class HandoverQueryResult {
        data class Found(val item: HandoverItem) : HandoverQueryResult()
        data class NotFound(val message: String) : HandoverQueryResult()
        data class Error(val message: String) : HandoverQueryResult()
    }

    sealed class HandoverConfirmResult {
        data class Ok(val message: String) : HandoverConfirmResult()
        data class Failed(val message: String) : HandoverConfirmResult()
    }

    private suspend fun factoryId(): Int = session.current().factoryId

    suspend fun queryByBarcode(barcode: String): StockResult = runCatching {
        val resp = network.api().lineStockByBarcode(barcode.trim(), factoryId())
        val body = resp.body()?.string() ?: resp.errorBody()?.string()
        when (val r = ResponseInterpreter.interpret(resp.code(), body)) {
            is WmsResult.BusinessFailure -> return@runCatching StockResult.NotFound(r.msg)
            WmsResult.AuthFailure -> return@runCatching StockResult.Error("身份验证失败")
            is WmsResult.RetryableFailure -> return@runCatching StockResult.Error("服务器繁忙，请重试 (${r.cause})")
            WmsResult.Success, WmsResult.IdempotentSuccess -> Unit
        }
        val cable = LineStockMapping.decodeSingleStock(body)
            ?: return@runCatching StockResult.NotFound("未找到该条码的库存信息")
        StockResult.Found(cable)
    }.getOrElse { StockResult.Error("网络异常：${it.message ?: "无法连接服务器"}") }

    suspend fun queryByMaterialCode(materialCode: String): MaterialResult = runCatching {
        val resp = network.api().lineStockByMaterialCode(materialCode.trim(), factoryId())
        if (!resp.isSuccessful) {
            val msg = resp.errorBody()?.string()?.let { extractMessage(it) } ?: "服务器错误"
            return@runCatching MaterialResult.Error(msg)
        }
        val env = resp.body()
        if (env?.isSuccess == false) {
            return@runCatching MaterialResult.NotFound(env.message ?: "未找到该物料的库存信息")
        }
        val list = env?.data.orEmpty()
        if (list.isEmpty()) {
            return@runCatching MaterialResult.NotFound("未找到该物料的库存信息: ${materialCode.trim()}")
        }
        MaterialResult.Found(LineStockMapping.toMaterialSummary(materialCode.trim(), list))
    }.getOrElse { MaterialResult.Error("网络异常：${it.message ?: "无法连接服务器"}") }

    suspend fun transfer(locationCode: String, barCodes: List<String>): TransferResult = runCatching {
        val resp = network.api().lineStockTransfer(TransferRequest(locationCode, barCodes))
        val body = resp.body()?.string() ?: resp.errorBody()?.string()
        when (val r = ResponseInterpreter.interpret(resp.code(), body)) {
            is WmsResult.BusinessFailure -> return@runCatching TransferResult.Failed(r.msg)
            WmsResult.AuthFailure -> return@runCatching TransferResult.Failed("身份验证失败")
            is WmsResult.RetryableFailure -> return@runCatching TransferResult.Failed("服务器繁忙，请重试 (${r.cause})")
            WmsResult.Success, WmsResult.IdempotentSuccess -> Unit
        }
        // success requires data==true even when isSuccess true
        if (LineStockMapping.decodeTransferData(body)) TransferResult.Ok
        else TransferResult.Failed("上架失败")
    }.getOrElse { TransferResult.Failed("网络异常：${it.message ?: "无法连接服务器"}") }

    suspend fun getHandoverByBarcode(barcode: String): HandoverQueryResult = runCatching {
        val resp = network.api().handoverByBarcode(barcode.trim(), factoryId())
        if (!resp.isSuccessful) {
            val msg = resp.errorBody()?.string()?.let { extractMessage(it) } ?: "服务器错误"
            return@runCatching HandoverQueryResult.NotFound(msg)
        }
        val env = resp.body()
        if (env?.isSuccess == false) {
            return@runCatching HandoverQueryResult.NotFound(env.message ?: "未找到待入库条码")
        }
        val item = LineStockMapping.parseHandover(env)
            ?: return@runCatching HandoverQueryResult.NotFound("未找到待入库条码")
        HandoverQueryResult.Found(item)
    }.getOrElse { HandoverQueryResult.Error("网络异常：${it.message ?: "无法连接服务器"}") }

    suspend fun confirmHandover(barCodes: List<String>): HandoverConfirmResult = runCatching {
        val resp = network.api().handoverConfirm(HandoverConfirmRequest(barCodes))
        val body = resp.body()?.string() ?: resp.errorBody()?.string()
        when (val r = ResponseInterpreter.interpret(resp.code(), body)) {
            is WmsResult.BusinessFailure -> return@runCatching HandoverConfirmResult.Failed(r.msg)
            WmsResult.AuthFailure -> return@runCatching HandoverConfirmResult.Failed("身份验证失败")
            is WmsResult.RetryableFailure -> return@runCatching HandoverConfirmResult.Failed("服务器繁忙，请重试 (${r.cause})")
            WmsResult.Success, WmsResult.IdempotentSuccess -> Unit
        }
        HandoverConfirmResult.Ok(extractMessage(body) ?: "标签收货确认完成！")
    }.getOrElse { HandoverConfirmResult.Failed("网络异常：${it.message ?: "无法连接服务器"}") }

    private fun extractMessage(body: String?): String? {
        if (body.isNullOrBlank()) return null
        return runCatching {
            com.google.gson.JsonParser.parseString(body).asJsonObject
                .let { o -> o.get("message") ?: o.get("msg") }
                ?.takeIf { it.isJsonPrimitive }?.asString
        }.getOrNull()
    }
}
```

- [ ] **Step 2: Add `lineStockRepository` to `AppContainer.kt`**

Open `AppContainer.kt`. Add the import (with the existing imports):

```kotlin
import com.bizlink.wmpda.feature.linestock.data.LineStockRepository
```

Add this `by lazy` property after the existing `authRepository` block:

```kotlin
    val lineStockRepository: LineStockRepository by lazy {
        LineStockRepository(network = networkClient, session = sessionManager)
    }
```

- [ ] **Step 3: Build to verify the repository + wiring compile**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(linestock): add LineStockRepository + AppContainer wiring"
```

---

## Task 5: Shared list/card composables

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/linestock/ui/CableListItem.kt`

> Pure UI; verified by build. Reused by shelving/removal/return (CableListItem), receiving (HandoverListItem), and stock query (StockInfoCard) — re-encodes the Flutter shared-widget reuse.

- [ ] **Step 1: Write `CableListItem.kt`**

```kotlin
package com.bizlink.wmpda.feature.linestock.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import com.bizlink.wmpda.core.components.QFCard
import com.bizlink.wmpda.core.theme.JetMono
import com.bizlink.wmpda.core.theme.OnSurfaceDim
import com.bizlink.wmpda.core.theme.Primary
import com.bizlink.wmpda.core.theme.StatusError
import com.bizlink.wmpda.feature.linestock.data.CableItem
import com.bizlink.wmpda.feature.linestock.data.HandoverItem
import com.bizlink.wmpda.feature.linestock.data.MaterialBatch

@Composable
fun CableListItemRow(item: CableItem, onRemove: (String) -> Unit) {
    QFCard(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                Text(item.barcode, style = MaterialTheme.typography.titleMedium, fontFamily = JetMono)
                Text(item.displayInfo, style = MaterialTheme.typography.bodySmall, color = OnSurfaceDim)
                Text("${item.quantityInfo} · 当前: ${item.currentLocation}", style = MaterialTheme.typography.bodySmall, color = OnSurfaceDim)
            }
            IconButton(onClick = { onRemove(item.barcode) }) {
                Icon(Icons.Filled.Delete, contentDescription = "删除", tint = StatusError)
            }
        }
    }
}

@Composable
fun HandoverListItemRow(item: HandoverItem, onRemove: (String) -> Unit) {
    QFCard(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                Text(item.barCode, style = MaterialTheme.typography.titleMedium, fontFamily = JetMono)
                Text("${item.materialCode} - ${item.materialDesc}", style = MaterialTheme.typography.bodySmall, color = OnSurfaceDim)
                Text("${item.quantityInfo} · 批次: ${item.batchCode}", style = MaterialTheme.typography.bodySmall, color = OnSurfaceDim)
            }
            IconButton(onClick = { onRemove(item.barCode) }) {
                Icon(Icons.Filled.Delete, contentDescription = "删除", tint = StatusError)
            }
        }
    }
}

@Composable
fun StockInfoCard(item: CableItem) {
    QFCard(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(item.barcode, style = MaterialTheme.typography.titleLarge, fontFamily = JetMono, color = Primary)
            Text(item.displayInfo, style = MaterialTheme.typography.bodyMedium)
            Text("数量: ${item.quantityInfo}", style = MaterialTheme.typography.bodyMedium, color = OnSurfaceDim)
            Text("当前库位: ${item.currentLocation}", style = MaterialTheme.typography.bodyMedium, color = OnSurfaceDim)
        }
    }
}

@Composable
fun MaterialBatchCard(batch: MaterialBatch) {
    QFCard(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.fillMaxWidth().padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("批次: ${batch.batchCode}", style = MaterialTheme.typography.titleMedium)
            Text("库位: ${batch.locationCode} ${batch.locationDesc}", style = MaterialTheme.typography.bodySmall, color = OnSurfaceDim)
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                QtyColumn("入库数量", batch.inboundQuantity, batch.baseUnit)
                QtyColumn("库存数量", batch.stockQuantity, batch.baseUnit)
                QtyColumn("已用数量", batch.usedQuantity, batch.baseUnit)
            }
        }
    }
}

@Composable
private fun QtyColumn(label: String, value: Double, unit: String) {
    Column {
        Text(label, style = MaterialTheme.typography.labelSmall, color = OnSurfaceDim)
        Text("$value $unit", style = MaterialTheme.typography.bodyMedium, fontFamily = FontFamily.Default)
    }
}
```

- [ ] **Step 2: Build to verify the composables compile**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(linestock): add shared cable/handover/stock list composables"
```

---

## Task 6: Stock Query — ViewModel + Screen (/linestock)

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/linestock/ui/StockQueryViewModel.kt`
- Create: `app/src/main/java/com/bizlink/wmpda/feature/linestock/ui/StockQueryScreen.kt`

- [ ] **Step 1: Write `StockQueryViewModel.kt`** (single UiState source of truth; one-shot events; scan collection)

```kotlin
package com.bizlink.wmpda.feature.linestock.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bizlink.wmpda.AppContainer
import com.bizlink.wmpda.feature.linestock.data.CableItem
import com.bizlink.wmpda.feature.linestock.data.LineStockMapping
import com.bizlink.wmpda.feature.linestock.data.LineStockRepository
import com.bizlink.wmpda.feature.linestock.data.MaterialSummary
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

enum class QueryMode { BARCODE, MATERIAL }

data class StockQueryUiState(
    val mode: QueryMode = QueryMode.BARCODE,
    val querying: Boolean = false,
    val barcodeResult: CableItem? = null,
    val materialResult: MaterialSummary? = null,
)

sealed class StockQueryEvent {
    data class Error(val message: String) : StockQueryEvent()
}

class StockQueryViewModel : ViewModel() {
    private val repo: LineStockRepository = AppContainer.lineStockRepository

    private val _state = MutableStateFlow(StockQueryUiState())
    val state: StateFlow<StockQueryUiState> = _state.asStateFlow()

    private val _events = MutableSharedFlow<StockQueryEvent>(extraBufferCapacity = 4)
    val events: SharedFlow<StockQueryEvent> = _events.asSharedFlow()

    init {
        viewModelScope.launch {
            AppContainer.scanFlow.collect { code -> onScan(code) }
        }
    }

    fun switchMode(mode: QueryMode) {
        if (_state.value.mode == mode) return
        _state.value = StockQueryUiState(mode = mode) // clears prior result on mode switch
    }

    /** Hardware scan or manual submit, routed by current mode. */
    fun onScan(raw: String) {
        when (_state.value.mode) {
            QueryMode.BARCODE -> queryByBarcode(raw)
            QueryMode.MATERIAL -> queryByMaterial(raw)
        }
    }

    fun queryByBarcode(raw: String) {
        val barcode = raw.trim()
        if (!LineStockMapping.isValidBarcode(barcode)) {
            emit(StockQueryEvent.Error("条码长度不足（至少 9 位）")); return
        }
        if (_state.value.querying) return
        _state.value = _state.value.copy(querying = true)
        viewModelScope.launch {
            when (val r = repo.queryByBarcode(barcode)) {
                is LineStockRepository.StockResult.Found ->
                    _state.value = _state.value.copy(querying = false, barcodeResult = r.cable)
                is LineStockRepository.StockResult.NotFound -> {
                    _state.value = _state.value.copy(querying = false); emit(StockQueryEvent.Error(r.message))
                }
                is LineStockRepository.StockResult.Error -> {
                    _state.value = _state.value.copy(querying = false); emit(StockQueryEvent.Error(r.message))
                }
            }
        }
    }

    fun queryByMaterial(raw: String) {
        val material = raw.trim()
        if (!LineStockMapping.isValidMaterial(material)) {
            emit(StockQueryEvent.Error("请输入物料号")); return
        }
        if (_state.value.querying) return
        _state.value = _state.value.copy(querying = true)
        viewModelScope.launch {
            when (val r = repo.queryByMaterialCode(material)) {
                is LineStockRepository.MaterialResult.Found ->
                    _state.value = _state.value.copy(querying = false, materialResult = r.summary)
                is LineStockRepository.MaterialResult.NotFound -> {
                    _state.value = _state.value.copy(querying = false); emit(StockQueryEvent.Error(r.message))
                }
                is LineStockRepository.MaterialResult.Error -> {
                    _state.value = _state.value.copy(querying = false); emit(StockQueryEvent.Error(r.message))
                }
            }
        }
    }

    fun clearResult() {
        _state.value = _state.value.copy(barcodeResult = null, materialResult = null)
    }

    private fun emit(e: StockQueryEvent) { _events.tryEmit(e) }
}
```

- [ ] **Step 2: Write `StockQueryScreen.kt`** (SegmentedButton modes; manual TextField cleared on success+error; '开始上架' passes barcode to shelving)

```kotlin
package com.bizlink.wmpda.feature.linestock.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.item
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.bizlink.wmpda.core.theme.OnSurfaceDim
import kotlinx.coroutines.launch

@androidx.annotation.OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
fun StockQueryScreen(
    onBack: () -> Unit,
    onStartShelving: (String) -> Unit,
    viewModel: StockQueryViewModel = viewModel(),
) {
    val state by viewModel.state.collectAsState()
    val snackbar = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    var input by remember { mutableStateOf("") }
    val keyboard = LocalSoftwareKeyboardController.current

    androidx.compose.runtime.LaunchedEffect(Unit) {
        viewModel.events.collect { e ->
            when (e) {
                is StockQueryEvent.Error -> { input = ""; scope.launch { snackbar.showSnackbar(e.message) } }
            }
        }
    }
    // clear manual field after a successful result populates
    androidx.compose.runtime.LaunchedEffect(state.barcodeResult, state.materialResult) {
        if (state.barcodeResult != null || state.materialResult != null) input = ""
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("库存查询") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "返回") } },
            )
        },
        snackbarHost = { SnackbarHost(snackbar) },
    ) { pad ->
        Column(Modifier.fillMaxSize().padding(pad).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                SegmentedButton(
                    selected = state.mode == QueryMode.BARCODE,
                    onClick = { viewModel.switchMode(QueryMode.BARCODE); input = "" },
                    shape = SegmentedButtonDefaults.itemShape(0, 2),
                ) { Text("按条码查询") }
                SegmentedButton(
                    selected = state.mode == QueryMode.MATERIAL,
                    onClick = { viewModel.switchMode(QueryMode.MATERIAL); input = "" },
                    shape = SegmentedButtonDefaults.itemShape(1, 2),
                ) { Text("按物料查询") }
            }
            OutlinedTextField(
                value = input,
                onValueChange = { input = it },
                label = { Text(if (state.mode == QueryMode.BARCODE) "扫描/输入条码" else "输入物料号") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = androidx.compose.foundation.text.KeyboardActions(onSearch = {
                    keyboard?.hide(); viewModel.onScan(input)
                }),
            )
            if (state.querying) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
                    CircularProgressIndicator()
                }
            }
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                state.barcodeResult?.let { cable ->
                    item { StockInfoCard(cable) }
                    item {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            Button(onClick = { onStartShelving(cable.barcode) }, modifier = Modifier.weight(1f).height(52.dp)) {
                                Text("开始上架")
                            }
                            OutlinedButton(onClick = viewModel::clearResult, modifier = Modifier.weight(1f).height(52.dp)) {
                                Text("清除结果")
                            }
                        }
                    }
                }
                state.materialResult?.let { summary ->
                    item {
                        Text(
                            "物料 ${summary.materialCode} · ${summary.batchCount} 批次 · 总库存 ${summary.totalStock}",
                            style = MaterialTheme.typography.titleMedium, color = OnSurfaceDim,
                        )
                    }
                    items(summary.batches) { batch -> MaterialBatchCard(batch) }
                    item {
                        OutlinedButton(onClick = viewModel::clearResult, modifier = Modifier.fillMaxWidth().height(52.dp)) {
                            Text("清除结果")
                        }
                    }
                }
            }
            Spacer(Modifier.height(4.dp))
        }
    }
}
```

- [ ] **Step 3: Build to verify Stock Query compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(linestock): add Stock Query view model + screen"
```

---

## Task 7: List-retention + duplicate + already-at-target ViewModel tests (TDD)

**Files:**
- Test: `app/src/test/java/com/bizlink/wmpda/feature/linestock/LineStockViewModelTest.kt`

> This task writes the tests that pin the three hardest bugLessons (#2 list retention, #3 duplicate keeps list, #4 already-at-target). It uses a **fake** repository injected via a test-only secondary constructor on `ShelvingViewModel` (added in Task 8). Write the test now; it will fail to compile until Task 8 adds that constructor — then it goes green. Run order is enforced by the steps below.

- [ ] **Step 1: Write `LineStockViewModelTest.kt`**

```kotlin
package com.bizlink.wmpda.feature.linestock

import com.bizlink.wmpda.feature.linestock.data.CableItem
import com.bizlink.wmpda.feature.linestock.data.LineStockRepository
import com.bizlink.wmpda.feature.linestock.ui.ShelvingEvent
import com.bizlink.wmpda.feature.linestock.ui.ShelvingViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class LineStockViewModelTest {

    private val dispatcher = StandardTestDispatcher()

    @Before fun setUp() { Dispatchers.setMain(dispatcher) }
    @After fun tearDown() { Dispatchers.resetMain() }

    private fun cable(bc: String, loc: String = "Z-01") =
        CableItem(bc, "B01", "M001", "电缆A", 100.0, "米", loc)

    /** Fake that returns a scripted result per barcode. */
    private class FakeRepo(
        val results: MutableMap<String, LineStockRepository.StockResult> = mutableMapOf(),
        var transfer: LineStockRepository.TransferResult = LineStockRepository.TransferResult.Ok,
    ) {
        suspend fun queryByBarcode(barcode: String) =
            results[barcode] ?: LineStockRepository.StockResult.NotFound("未找到")
        suspend fun transfer(loc: String, codes: List<String>) = transfer
    }

    @Test fun `duplicate barcode is rejected and list is preserved`() = runTest(dispatcher) {
        val repo = FakeRepo(mutableMapOf("CB000000001" to LineStockRepository.StockResult.Found(cable("CB000000001"))))
        val vm = ShelvingViewModel.forTest(
            queryByBarcode = { repo.queryByBarcode(it) },
            transfer = { l, c -> repo.transfer(l, c) },
        )
        val events = mutableListOf<ShelvingEvent>()
        val job = launch { vm.events.toList(events) }

        vm.onScanCable("CB000000001"); advanceUntilIdle()
        assertEquals(1, vm.state.value.cableList.size)

        vm.onScanCable("CB000000001"); advanceUntilIdle() // duplicate
        // list still has exactly one item; an error event was emitted
        assertEquals(1, vm.state.value.cableList.size)
        assertTrue(events.any { it is ShelvingEvent.Error })
        job.cancel()
    }

    @Test fun `network error on add keeps existing list intact`() = runTest(dispatcher) {
        val repo = FakeRepo(mutableMapOf(
            "CB000000001" to LineStockRepository.StockResult.Found(cable("CB000000001")),
            "CB000000002" to LineStockRepository.StockResult.Error("网络异常"),
        ))
        val vm = ShelvingViewModel.forTest(
            queryByBarcode = { repo.queryByBarcode(it) },
            transfer = { l, c -> repo.transfer(l, c) },
        )
        vm.onScanCable("CB000000001"); advanceUntilIdle()
        vm.onScanCable("CB000000002"); advanceUntilIdle() // errors
        assertEquals(1, vm.state.value.cableList.size) // list NOT wiped
    }

    @Test fun `already at target location is rejected`() = runTest(dispatcher) {
        val repo = FakeRepo(mutableMapOf("CB000000009" to LineStockRepository.StockResult.Found(cable("CB000000009", loc = "T-99"))))
        val vm = ShelvingViewModel.forTest(
            queryByBarcode = { repo.queryByBarcode(it) },
            transfer = { l, c -> repo.transfer(l, c) },
        )
        val events = mutableListOf<ShelvingEvent>()
        val job = launch { vm.events.toList(events) }
        vm.setTargetLocation("T-99"); advanceUntilIdle()
        vm.onScanCable("CB000000009"); advanceUntilIdle()
        assertEquals(0, vm.state.value.cableList.size)
        assertTrue(events.any { it is ShelvingEvent.Error })
        job.cancel()
    }
}
```

- [ ] **Step 2: Run the test to verify it fails (won't compile yet — ShelvingViewModel not built)**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.feature.linestock.LineStockViewModelTest"`
Expected: FAIL — `ShelvingViewModel` / `ShelvingEvent` unresolved (compilation error). Proceed to Task 8.

> Do NOT commit a broken test alone. Task 8 makes this green; commit happens at the end of Task 8.

---

## Task 8: Shelving — ViewModel + Screen (/linestock/shelving)

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/linestock/ui/ShelvingViewModel.kt`
- Create: `app/src/main/java/com/bizlink/wmpda/feature/linestock/ui/ShelvingScreen.kt`

- [ ] **Step 1: Write `ShelvingViewModel.kt`** (list in StateFlow = single source of truth; one-shot events; testable secondary `forTest` constructor; honors already-at-target + duplicate; never wipes list on error)

```kotlin
package com.bizlink.wmpda.feature.linestock.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bizlink.wmpda.AppContainer
import com.bizlink.wmpda.feature.linestock.data.CableItem
import com.bizlink.wmpda.feature.linestock.data.LineStockMapping
import com.bizlink.wmpda.feature.linestock.data.LineStockRepository
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class ShelvingUiState(
    val targetLocation: String? = null,
    val cableList: List<CableItem> = emptyList(),
    val busy: Boolean = false,
) {
    val hasTargetLocation: Boolean get() = !targetLocation.isNullOrBlank()
    val canSubmit: Boolean get() = hasTargetLocation && cableList.isNotEmpty() && !busy
    val count: Int get() = cableList.size
}

sealed class ShelvingEvent {
    data class Error(val message: String) : ShelvingEvent()
    data class Flash(val unit: Unit = Unit) : ShelvingEvent()
    data class Success(val count: Int, val location: String) : ShelvingEvent()
}

/**
 * Shelving = scan a target location (optional order) + accumulate cables, then transfer.
 * The cableList lives ONLY in StateFlow; errors are one-shot events that never touch it.
 * No runtimeType-sniffing, no previousState recursion (Flutter anti-pattern dropped).
 */
class ShelvingViewModel private constructor(
    private val queryByBarcode: suspend (String) -> LineStockRepository.StockResult,
    private val transfer: suspend (String, List<String>) -> LineStockRepository.TransferResult,
    collectScans: Boolean,
    initialLocation: String?,
) : ViewModel() {

    constructor() : this(
        queryByBarcode = { AppContainer.lineStockRepository.queryByBarcode(it) },
        transfer = { l, c -> AppContainer.lineStockRepository.transfer(l, c) },
        collectScans = true,
        initialLocation = null,
    )

    protected val _state = MutableStateFlow(ShelvingUiState(targetLocation = initialLocation))
    val state: StateFlow<ShelvingUiState> = _state.asStateFlow()

    protected val _events = MutableSharedFlow<ShelvingEvent>(extraBufferCapacity = 8)
    val events: SharedFlow<ShelvingEvent> = _events.asSharedFlow()

    init {
        if (collectScans) {
            viewModelScope.launch { AppContainer.scanFlow.collect { onScan(it) } }
        }
    }

    /** Route a scan to location (if not yet set & looks like a location) or cable. We keep it
     *  explicit: the screen calls setTargetLocation for the location field and onScanCable for cables.
     *  The hardware scanFlow defaults to cable scanning (the common case). */
    fun onScan(raw: String) = onScanCable(raw)

    fun setTargetLocation(raw: String) {
        val loc = raw.trim()
        if (!LineStockMapping.isValidLocation(loc)) { emit(ShelvingEvent.Error("库位长度不足（至少 4 位）")); return }
        _state.value = _state.value.copy(targetLocation = loc)
    }

    fun modifyTargetLocation() {
        _state.value = _state.value.copy(targetLocation = null) // keep cables, clear location
    }

    fun onScanCable(raw: String) {
        val barcode = raw.trim()
        if (!LineStockMapping.isValidBarcode(barcode)) { emit(ShelvingEvent.Error("条码长度不足（至少 9 位）")); return }
        val s = _state.value
        if (s.busy) return
        if (LineStockMapping.isDuplicate(s.cableList, barcode)) {
            emit(ShelvingEvent.Error("⚠️ 重复条码：$barcode\n该电缆已在上架清单中")); return // list preserved
        }
        _state.value = s.copy(busy = true)
        viewModelScope.launch {
            when (val r = queryByBarcode(barcode)) {
                is LineStockRepository.StockResult.Found -> {
                    val target = _state.value.targetLocation
                    if (LineStockMapping.isAlreadyAtTarget(r.cable.currentLocation, target)) {
                        _state.value = _state.value.copy(busy = false)
                        emit(ShelvingEvent.Error("电缆已在目标库位 $target，无需转移")) // list preserved
                    } else {
                        _state.value = _state.value.copy(busy = false, cableList = _state.value.cableList + r.cable)
                        emit(ShelvingEvent.Flash())
                    }
                }
                is LineStockRepository.StockResult.NotFound -> {
                    _state.value = _state.value.copy(busy = false); emit(ShelvingEvent.Error("条码验证失败：${r.message}"))
                }
                is LineStockRepository.StockResult.Error -> {
                    _state.value = _state.value.copy(busy = false); emit(ShelvingEvent.Error(r.message))
                }
            }
        }
    }

    fun removeCable(barcode: String) {
        _state.value = _state.value.copy(cableList = _state.value.cableList.filterNot { it.barcode == barcode })
    }

    fun clearList() { _state.value = _state.value.copy(cableList = emptyList()) }

    fun confirm() {
        val s = _state.value
        val target = s.targetLocation
        if (target.isNullOrBlank() || s.cableList.isEmpty() || s.busy) return
        _state.value = s.copy(busy = true)
        viewModelScope.launch {
            val codes = s.cableList.map { it.barcode }
            when (val r = transfer(target, codes)) {
                LineStockRepository.TransferResult.Ok -> {
                    emit(ShelvingEvent.Success(codes.size, target))
                    _state.value = ShelvingUiState() // reset to empty after success
                }
                is LineStockRepository.TransferResult.Failed -> {
                    _state.value = _state.value.copy(busy = false); emit(ShelvingEvent.Error(r.message)) // list preserved
                }
            }
        }
    }

    private fun emit(e: ShelvingEvent) { _events.tryEmit(e) }

    companion object {
        /** Test-only factory: inject fakes, no scan collection. */
        fun forTest(
            queryByBarcode: suspend (String) -> LineStockRepository.StockResult,
            transfer: suspend (String, List<String>) -> LineStockRepository.TransferResult,
            initialLocation: String? = null,
        ): ShelvingViewModel = ShelvingViewModel(queryByBarcode, transfer, collectScans = false, initialLocation = initialLocation)
    }
}
```

- [ ] **Step 2: Run the Task-7 ViewModel test to verify it passes**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.feature.linestock.LineStockViewModelTest"`
Expected: PASS (3 tests).

- [ ] **Step 3: Write `ShelvingScreen.kt`** (location row + cable list; manual fields cleared on success+error; FlashOverlay on add; success dialog 返回查询/继续上架)

```kotlin
package com.bizlink.wmpda.feature.linestock.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.bizlink.wmpda.core.components.FeedbackPlayer
import com.bizlink.wmpda.core.components.FlashOverlay
import com.bizlink.wmpda.core.theme.OnSurfaceDim
import com.bizlink.wmpda.core.theme.Primary

@androidx.annotation.OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
fun ShelvingScreen(
    onBack: () -> Unit,
    initialBarcode: String? = null,
    viewModel: ShelvingViewModel = viewModel(),
) {
    val state by viewModel.state.collectAsState()
    val snackbar = remember { SnackbarHostState() }
    val context = LocalContext.current
    var locationInput by remember { mutableStateOf("") }
    var cableInput by remember { mutableStateOf("") }
    var flash by remember { mutableStateOf(false) }
    var showConfirm by remember { mutableStateOf(false) }
    var successCount by remember { mutableStateOf(0) }
    var showSuccess by remember { mutableStateOf(false) }

    // Pre-fill the first cable when arriving from Stock Query '开始上架'.
    LaunchedEffect(initialBarcode) { if (!initialBarcode.isNullOrBlank()) viewModel.onScanCable(initialBarcode) }

    LaunchedEffect(Unit) {
        viewModel.events.collect { e ->
            when (e) {
                is ShelvingEvent.Error -> { cableInput = ""; FeedbackPlayer.play(context, FeedbackPlayer.Kind.ERROR); snackbar.showSnackbar(e.message) }
                is ShelvingEvent.Flash -> { cableInput = ""; flash = true; FeedbackPlayer.play(context, FeedbackPlayer.Kind.SUCCESS) }
                is ShelvingEvent.Success -> { cableInput = ""; locationInput = ""; successCount = e.count; showSuccess = true; FeedbackPlayer.play(context, FeedbackPlayer.Kind.SUCCESS) }
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("电缆上架") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "返回") } },
            )
        },
        snackbarHost = { SnackbarHost(snackbar) },
    ) { pad ->
        Box(Modifier.fillMaxSize().padding(pad)) {
            Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                if (state.hasTargetLocation) {
                    Row(Modifier.fillMaxWidth(), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                        Text("目标库位: ${state.targetLocation}", style = MaterialTheme.typography.titleMedium, color = Primary, modifier = Modifier.weight(1f))
                        TextButton(onClick = { viewModel.modifyTargetLocation(); locationInput = "" }) { Text("修改") }
                    }
                } else {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedTextField(
                            value = locationInput, onValueChange = { locationInput = it },
                            label = { Text("扫描/输入目标库位") }, singleLine = true, modifier = Modifier.weight(1f),
                            keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(imeAction = ImeAction.Done),
                        )
                        Button(onClick = { viewModel.setTargetLocation(locationInput) }, modifier = Modifier.height(56.dp)) { Text("确认") }
                    }
                }
                OutlinedTextField(
                    value = cableInput, onValueChange = { cableInput = it },
                    label = { Text("扫描电缆条码") }, singleLine = true, modifier = Modifier.fillMaxWidth(),
                    keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(imeAction = ImeAction.Done),
                    keyboardActions = androidx.compose.foundation.text.KeyboardActions(onDone = { viewModel.onScanCable(cableInput) }),
                )
                Row(Modifier.fillMaxWidth(), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                    Text("已扫 ${state.count} 盘", style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
                    if (state.count > 0) TextButton(onClick = viewModel::clearList) { Text("清空") }
                }
                LazyColumn(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(state.cableList, key = { it.barcode }) { c -> CableListItemRow(c, viewModel::removeCable) }
                }
                Button(
                    onClick = { showConfirm = true },
                    enabled = state.canSubmit,
                    modifier = Modifier.fillMaxWidth().height(56.dp),
                ) { Text("确认上架 (${state.count} 盘)") }
            }
            FlashOverlay(visible = flash, onConsumed = { flash = false })
        }
    }

    if (showConfirm) {
        AlertDialog(
            onDismissRequest = { showConfirm = false },
            title = { Text("确认上架") },
            text = { Text("将 ${state.count} 盘电缆上架到 ${state.targetLocation}？") },
            confirmButton = { TextButton(onClick = { showConfirm = false; viewModel.confirm() }) { Text("确认") } },
            dismissButton = { TextButton(onClick = { showConfirm = false }) { Text("取消") } },
        )
    }
    if (showSuccess) {
        AlertDialog(
            onDismissRequest = { showSuccess = false },
            title = { Text("上架成功") },
            text = { Text("已成功上架 $successCount 盘电缆。", color = OnSurfaceDim) },
            confirmButton = { TextButton(onClick = { showSuccess = false; onBack() }) { Text("返回查询") } },
            dismissButton = { TextButton(onClick = { showSuccess = false }) { Text("继续上架") } },
        )
    }
}
```

- [ ] **Step 4: Build to verify Shelving compiles, then re-run all linestock tests**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.feature.linestock.*"`
Expected: `BUILD SUCCESSFUL`; tests PASS (LineStockMappingTest 17 + LineStockResponseParseTest 4 + LineStockViewModelTest 3 = 24).

- [ ] **Step 5: Commit** (includes the Task-7 test that now passes)

```bash
git add -A && git commit -m "feat(linestock): add Shelving view model + screen, list-retention tests green"
```

---

## Task 9: Removal — ViewModel + Screen (/linestock/removal, fixed 2200-100)

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/linestock/ui/RemovalViewModel.kt`
- Create: `app/src/main/java/com/bizlink/wmpda/feature/linestock/ui/RemovalScreen.kt`

> Removal = shelving with a LOCKED target. We give it its own ViewModel (per the no-shared-state rule) seeded with the fixed location `'2200-100'`; the already-at-target guard applies automatically against that location.

- [ ] **Step 1: Write `RemovalViewModel.kt`**

```kotlin
package com.bizlink.wmpda.feature.linestock.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bizlink.wmpda.AppContainer
import com.bizlink.wmpda.feature.linestock.data.CableItem
import com.bizlink.wmpda.feature.linestock.data.LineStockMapping
import com.bizlink.wmpda.feature.linestock.data.LineStockRepository
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

const val LINE_STOCK_LOCATION = "2200-100" // 线边库

data class RemovalUiState(
    val cableList: List<CableItem> = emptyList(),
    val busy: Boolean = false,
) {
    val canSubmit: Boolean get() = cableList.isNotEmpty() && !busy
    val count: Int get() = cableList.size
}

class RemovalViewModel : ViewModel() {
    private val repo = AppContainer.lineStockRepository

    private val _state = MutableStateFlow(RemovalUiState())
    val state: StateFlow<RemovalUiState> = _state.asStateFlow()

    private val _events = MutableSharedFlow<ShelvingEvent>(extraBufferCapacity = 8)
    val events: SharedFlow<ShelvingEvent> = _events.asSharedFlow()

    init { viewModelScope.launch { AppContainer.scanFlow.collect { onScanCable(it) } } }

    fun onScanCable(raw: String) {
        val barcode = raw.trim()
        if (!LineStockMapping.isValidBarcode(barcode)) { emit(ShelvingEvent.Error("条码长度不足（至少 9 位）")); return }
        val s = _state.value
        if (s.busy) return
        if (LineStockMapping.isDuplicate(s.cableList, barcode)) {
            emit(ShelvingEvent.Error("⚠️ 重复条码：$barcode\n该电缆已在下架清单中")); return
        }
        _state.value = s.copy(busy = true)
        viewModelScope.launch {
            when (val r = repo.queryByBarcode(barcode)) {
                is LineStockRepository.StockResult.Found -> {
                    if (LineStockMapping.isAlreadyAtTarget(r.cable.currentLocation, LINE_STOCK_LOCATION)) {
                        _state.value = _state.value.copy(busy = false)
                        emit(ShelvingEvent.Error("电缆已在线边库 $LINE_STOCK_LOCATION，无需下架"))
                    } else {
                        _state.value = _state.value.copy(busy = false, cableList = _state.value.cableList + r.cable)
                        emit(ShelvingEvent.Flash())
                    }
                }
                is LineStockRepository.StockResult.NotFound -> { _state.value = _state.value.copy(busy = false); emit(ShelvingEvent.Error("条码验证失败：${r.message}")) }
                is LineStockRepository.StockResult.Error -> { _state.value = _state.value.copy(busy = false); emit(ShelvingEvent.Error(r.message)) }
            }
        }
    }

    fun removeCable(barcode: String) { _state.value = _state.value.copy(cableList = _state.value.cableList.filterNot { it.barcode == barcode }) }
    fun clearList() { _state.value = _state.value.copy(cableList = emptyList()) }

    fun confirm() {
        val s = _state.value
        if (s.cableList.isEmpty() || s.busy) return
        _state.value = s.copy(busy = true)
        viewModelScope.launch {
            val codes = s.cableList.map { it.barcode }
            when (val r = repo.transfer(LINE_STOCK_LOCATION, codes)) {
                LineStockRepository.TransferResult.Ok -> { emit(ShelvingEvent.Success(codes.size, LINE_STOCK_LOCATION)); _state.value = RemovalUiState() }
                is LineStockRepository.TransferResult.Failed -> { _state.value = _state.value.copy(busy = false); emit(ShelvingEvent.Error(r.message)) }
            }
        }
    }

    private fun emit(e: ShelvingEvent) { _events.tryEmit(e) }
}
```

- [ ] **Step 2: Write `RemovalScreen.kt`** (locked location header; success dialog 返回工作台/继续下架)

```kotlin
package com.bizlink.wmpda.feature.linestock.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.bizlink.wmpda.core.components.FeedbackPlayer
import com.bizlink.wmpda.core.components.FlashOverlay
import com.bizlink.wmpda.core.theme.Primary

@androidx.annotation.OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
fun RemovalScreen(
    onBack: () -> Unit,
    onHome: () -> Unit,
    viewModel: RemovalViewModel = viewModel(),
) {
    val state by viewModel.state.collectAsState()
    val snackbar = remember { SnackbarHostState() }
    val context = LocalContext.current
    var cableInput by remember { mutableStateOf("") }
    var flash by remember { mutableStateOf(false) }
    var showConfirm by remember { mutableStateOf(false) }
    var successCount by remember { mutableStateOf(0) }
    var showSuccess by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.events.collect { e ->
            when (e) {
                is ShelvingEvent.Error -> { cableInput = ""; FeedbackPlayer.play(context, FeedbackPlayer.Kind.ERROR); snackbar.showSnackbar(e.message) }
                is ShelvingEvent.Flash -> { cableInput = ""; flash = true; FeedbackPlayer.play(context, FeedbackPlayer.Kind.SUCCESS) }
                is ShelvingEvent.Success -> { cableInput = ""; successCount = e.count; showSuccess = true; FeedbackPlayer.play(context, FeedbackPlayer.Kind.SUCCESS) }
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("电缆下架") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "返回") } },
            )
        },
        snackbarHost = { SnackbarHost(snackbar) },
    ) { pad ->
        Box(Modifier.fillMaxSize().padding(pad)) {
            Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(Icons.Filled.Lock, contentDescription = null, tint = Primary)
                    Text("线边库 (锁定): $LINE_STOCK_LOCATION", style = MaterialTheme.typography.titleMedium, color = Primary)
                }
                OutlinedTextField(
                    value = cableInput, onValueChange = { cableInput = it },
                    label = { Text("扫描电缆条码") }, singleLine = true, modifier = Modifier.fillMaxWidth(),
                    keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(imeAction = ImeAction.Done),
                    keyboardActions = androidx.compose.foundation.text.KeyboardActions(onDone = { viewModel.onScanCable(cableInput) }),
                )
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text("已扫 ${state.count} 盘", style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
                    if (state.count > 0) TextButton(onClick = viewModel::clearList) { Text("清空") }
                }
                LazyColumn(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(state.cableList, key = { it.barcode }) { c -> CableListItemRow(c, viewModel::removeCable) }
                }
                Button(onClick = { showConfirm = true }, enabled = state.canSubmit, modifier = Modifier.fillMaxWidth().height(56.dp)) {
                    Text("确认下架 (${state.count} 盘)")
                }
            }
            FlashOverlay(visible = flash, onConsumed = { flash = false })
        }
    }

    if (showConfirm) {
        AlertDialog(
            onDismissRequest = { showConfirm = false },
            title = { Text("确认下架") },
            text = { Text("将 ${state.count} 盘电缆下架到线边库 $LINE_STOCK_LOCATION？") },
            confirmButton = { TextButton(onClick = { showConfirm = false; viewModel.confirm() }) { Text("确认") } },
            dismissButton = { TextButton(onClick = { showConfirm = false }) { Text("取消") } },
        )
    }
    if (showSuccess) {
        AlertDialog(
            onDismissRequest = { showSuccess = false },
            title = { Text("下架成功") },
            text = { Text("已成功下架 $successCount 盘电缆到 $LINE_STOCK_LOCATION。") },
            confirmButton = { TextButton(onClick = { showSuccess = false; onHome() }) { Text("返回工作台") } },
            dismissButton = { TextButton(onClick = { showSuccess = false }) { Text("继续下架") } },
        )
    }
}
```

- [ ] **Step 3: Build to verify Removal compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(linestock): add Removal view model + screen (fixed 2200-100)"
```

---

## Task 10: Receiving — ViewModel + Screen (/linestock/receiving, handover)

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/linestock/ui/ReceivingViewModel.kt`
- Create: `app/src/main/java/com/bizlink/wmpda/feature/linestock/ui/ReceivingScreen.kt`

> Receiving uses the handover endpoints. Per bugLesson #6, keep the list IN state and use an `isLoading`/`busy` flag (the receiving-style pattern) — never drop the list mid-scan. Success returns to workbench (no '继续' option), surfacing the server message.

- [ ] **Step 1: Write `ReceivingViewModel.kt`**

```kotlin
package com.bizlink.wmpda.feature.linestock.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bizlink.wmpda.AppContainer
import com.bizlink.wmpda.feature.linestock.data.HandoverItem
import com.bizlink.wmpda.feature.linestock.data.LineStockMapping
import com.bizlink.wmpda.feature.linestock.data.LineStockRepository
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class ReceivingUiState(
    val itemList: List<HandoverItem> = emptyList(),
    val busy: Boolean = false,
) {
    val canSubmit: Boolean get() = itemList.isNotEmpty() && !busy
    val count: Int get() = itemList.size
}

sealed class ReceivingEvent {
    data class Error(val message: String) : ReceivingEvent()
    object Flash : ReceivingEvent()
    data class Success(val message: String, val count: Int) : ReceivingEvent()
}

class ReceivingViewModel : ViewModel() {
    private val repo = AppContainer.lineStockRepository

    private val _state = MutableStateFlow(ReceivingUiState())
    val state: StateFlow<ReceivingUiState> = _state.asStateFlow()

    private val _events = MutableSharedFlow<ReceivingEvent>(extraBufferCapacity = 8)
    val events: SharedFlow<ReceivingEvent> = _events.asSharedFlow()

    init { viewModelScope.launch { AppContainer.scanFlow.collect { onScan(it) } } }

    fun onScan(raw: String) {
        val barcode = raw.trim()
        if (!LineStockMapping.isValidBarcode(barcode)) { emit(ReceivingEvent.Error("条码长度不足（至少 9 位）")); return }
        val s = _state.value
        if (s.busy) return
        if (LineStockMapping.isDuplicateHandover(s.itemList, barcode)) {
            emit(ReceivingEvent.Error("该条码已在待入库列表中")); return // list preserved
        }
        _state.value = s.copy(busy = true) // isLoading flag — list stays in state
        viewModelScope.launch {
            when (val r = repo.getHandoverByBarcode(barcode)) {
                is LineStockRepository.HandoverQueryResult.Found -> {
                    _state.value = _state.value.copy(busy = false, itemList = _state.value.itemList + r.item)
                    emit(ReceivingEvent.Flash)
                }
                is LineStockRepository.HandoverQueryResult.NotFound -> { _state.value = _state.value.copy(busy = false); emit(ReceivingEvent.Error(r.message)) }
                is LineStockRepository.HandoverQueryResult.Error -> { _state.value = _state.value.copy(busy = false); emit(ReceivingEvent.Error(r.message)) }
            }
        }
    }

    fun removeItem(barcode: String) { _state.value = _state.value.copy(itemList = _state.value.itemList.filterNot { it.barCode == barcode }) }
    fun clearList() { _state.value = _state.value.copy(itemList = emptyList()) }

    fun confirm() {
        val s = _state.value
        if (s.itemList.isEmpty() || s.busy) return
        _state.value = s.copy(busy = true)
        viewModelScope.launch {
            val codes = s.itemList.map { it.barCode }
            when (val r = repo.confirmHandover(codes)) {
                is LineStockRepository.HandoverConfirmResult.Ok -> { emit(ReceivingEvent.Success(r.message, codes.size)); _state.value = ReceivingUiState() }
                is LineStockRepository.HandoverConfirmResult.Failed -> { _state.value = _state.value.copy(busy = false); emit(ReceivingEvent.Error(r.message)) }
            }
        }
    }

    private fun emit(e: ReceivingEvent) { _events.tryEmit(e) }
}
```

- [ ] **Step 2: Write `ReceivingScreen.kt`** (title card; handover list; success dialog single 返回工作台)

```kotlin
package com.bizlink.wmpda.feature.linestock.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.MoveToInbox
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.bizlink.wmpda.core.components.FeedbackPlayer
import com.bizlink.wmpda.core.components.FlashOverlay
import com.bizlink.wmpda.core.theme.Primary

@androidx.annotation.OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
fun ReceivingScreen(
    onBack: () -> Unit,
    onHome: () -> Unit,
    viewModel: ReceivingViewModel = viewModel(),
) {
    val state by viewModel.state.collectAsState()
    val snackbar = remember { SnackbarHostState() }
    val context = LocalContext.current
    var barcodeInput by remember { mutableStateOf("") }
    var flash by remember { mutableStateOf(false) }
    var showConfirm by remember { mutableStateOf(false) }
    var successMsg by remember { mutableStateOf("") }
    var showSuccess by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.events.collect { e ->
            when (e) {
                is ReceivingEvent.Error -> { barcodeInput = ""; FeedbackPlayer.play(context, FeedbackPlayer.Kind.ERROR); snackbar.showSnackbar(e.message) }
                ReceivingEvent.Flash -> { barcodeInput = ""; flash = true; FeedbackPlayer.play(context, FeedbackPlayer.Kind.SUCCESS) }
                is ReceivingEvent.Success -> { barcodeInput = ""; successMsg = "${e.message}（${e.count} 个）"; showSuccess = true; FeedbackPlayer.play(context, FeedbackPlayer.Kind.SUCCESS) }
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("断线电缆收货") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "返回") } },
            )
        },
        snackbarHost = { SnackbarHost(snackbar) },
    ) { pad ->
        Box(Modifier.fillMaxSize().padding(pad)) {
            Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(Icons.Filled.MoveToInbox, contentDescription = null, tint = Primary)
                    Text("扫描待入库电缆条码", style = MaterialTheme.typography.titleMedium, color = Primary)
                }
                OutlinedTextField(
                    value = barcodeInput, onValueChange = { barcodeInput = it },
                    label = { Text("扫描条码") }, singleLine = true, modifier = Modifier.fillMaxWidth(),
                    keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(imeAction = ImeAction.Done),
                    keyboardActions = androidx.compose.foundation.text.KeyboardActions(onDone = { viewModel.onScan(barcodeInput) }),
                )
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text("待入库 ${state.count} 个", style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
                    if (state.busy) CircularProgressIndicator(Modifier.height(20.dp))
                    if (state.count > 0) TextButton(onClick = viewModel::clearList) { Text("清空") }
                }
                LazyColumn(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(state.itemList, key = { it.barCode }) { item -> HandoverListItemRow(item, viewModel::removeItem) }
                }
                Button(onClick = { showConfirm = true }, enabled = state.canSubmit, modifier = Modifier.fillMaxWidth().height(56.dp)) {
                    Text("确认入库 (${state.count} 个)")
                }
            }
            FlashOverlay(visible = flash, onConsumed = { flash = false })
        }
    }

    if (showConfirm) {
        AlertDialog(
            onDismissRequest = { showConfirm = false },
            title = { Text("确认入库") },
            text = { Text("确认收货 ${state.count} 个电缆标签？") },
            confirmButton = { TextButton(onClick = { showConfirm = false; viewModel.confirm() }) { Text("确认") } },
            dismissButton = { TextButton(onClick = { showConfirm = false }) { Text("取消") } },
        )
    }
    if (showSuccess) {
        AlertDialog(
            onDismissRequest = {},
            title = { Text("入库成功") },
            text = { Text(successMsg) },
            confirmButton = { TextButton(onClick = { showSuccess = false; onHome() }) { Text("返回工作台") } },
        )
    }
}
```

- [ ] **Step 3: Build to verify Receiving compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(linestock): add Receiving (handover) view model + screen"
```

---

## Task 11: Return — ViewModel + Screen (/linestock/return, magic 'RETURN')

**Files:**
- Create: `app/src/main/java/com/bizlink/wmpda/feature/linestock/ui/ReturnViewModel.kt`
- Create: `app/src/main/java/com/bizlink/wmpda/feature/linestock/ui/ReturnScreen.kt`

> bugLesson #7: the Flutter return screen was dead because it init'd with Reset→Initial and only rendered the input under ShelvingInProgress. Here the ViewModel STARTS in an empty in-progress `ReturnUiState()` so the input is always shown. Transfer uses the magic string `'RETURN'`.

- [ ] **Step 1: Write `ReturnViewModel.kt`**

```kotlin
package com.bizlink.wmpda.feature.linestock.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bizlink.wmpda.AppContainer
import com.bizlink.wmpda.feature.linestock.data.CableItem
import com.bizlink.wmpda.feature.linestock.data.LineStockMapping
import com.bizlink.wmpda.feature.linestock.data.LineStockRepository
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

const val RETURN_LOCATION = "RETURN" // 魔法串:后端解释为退回 WMS(spec §9 #5)

data class ReturnUiState(
    val cableList: List<CableItem> = emptyList(),
    val busy: Boolean = false,
) {
    val canSubmit: Boolean get() = cableList.isNotEmpty() && !busy
    val count: Int get() = cableList.size
}

class ReturnViewModel : ViewModel() {
    private val repo = AppContainer.lineStockRepository

    // Starts in an EMPTY in-progress state (NOT Reset→Initial) — fixes the Flutter dead-flow bug.
    private val _state = MutableStateFlow(ReturnUiState())
    val state: StateFlow<ReturnUiState> = _state.asStateFlow()

    private val _events = MutableSharedFlow<ShelvingEvent>(extraBufferCapacity = 8)
    val events: SharedFlow<ShelvingEvent> = _events.asSharedFlow()

    init { viewModelScope.launch { AppContainer.scanFlow.collect { onScanCable(it) } } }

    fun onScanCable(raw: String) {
        val barcode = raw.trim()
        if (!LineStockMapping.isValidBarcode(barcode)) { emit(ShelvingEvent.Error("条码长度不足（至少 9 位）")); return }
        val s = _state.value
        if (s.busy) return
        if (LineStockMapping.isDuplicate(s.cableList, barcode)) { emit(ShelvingEvent.Error("⚠️ 重复条码：$barcode\n该电缆已在退库清单中")); return }
        _state.value = s.copy(busy = true)
        viewModelScope.launch {
            when (val r = repo.queryByBarcode(barcode)) {
                is LineStockRepository.StockResult.Found -> { _state.value = _state.value.copy(busy = false, cableList = _state.value.cableList + r.cable); emit(ShelvingEvent.Flash()) }
                is LineStockRepository.StockResult.NotFound -> { _state.value = _state.value.copy(busy = false); emit(ShelvingEvent.Error("条码验证失败：${r.message}")) }
                is LineStockRepository.StockResult.Error -> { _state.value = _state.value.copy(busy = false); emit(ShelvingEvent.Error(r.message)) }
            }
        }
    }

    fun removeCable(barcode: String) { _state.value = _state.value.copy(cableList = _state.value.cableList.filterNot { it.barcode == barcode }) }
    fun clearList() { _state.value = _state.value.copy(cableList = emptyList()) }

    fun confirm() {
        val s = _state.value
        if (s.cableList.isEmpty() || s.busy) return
        _state.value = s.copy(busy = true)
        viewModelScope.launch {
            val codes = s.cableList.map { it.barcode }
            when (val r = repo.transfer(RETURN_LOCATION, codes)) {
                LineStockRepository.TransferResult.Ok -> { emit(ShelvingEvent.Success(codes.size, RETURN_LOCATION)); _state.value = ReturnUiState() }
                is LineStockRepository.TransferResult.Failed -> { _state.value = _state.value.copy(busy = false); emit(ShelvingEvent.Error(r.message)) }
            }
        }
    }

    private fun emit(e: ShelvingEvent) { _events.tryEmit(e) }
}
```

- [ ] **Step 2: Write `ReturnScreen.kt`** (instruction card; cable list; success dialog single 确定)

```kotlin
package com.bizlink.wmpda.feature.linestock.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Unarchive
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.bizlink.wmpda.core.components.FeedbackPlayer
import com.bizlink.wmpda.core.components.FlashOverlay
import com.bizlink.wmpda.core.theme.StatusError

@androidx.annotation.OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
fun ReturnScreen(
    onBack: () -> Unit,
    viewModel: ReturnViewModel = viewModel(),
) {
    val state by viewModel.state.collectAsState()
    val snackbar = remember { SnackbarHostState() }
    val context = LocalContext.current
    var cableInput by remember { mutableStateOf("") }
    var flash by remember { mutableStateOf(false) }
    var showConfirm by remember { mutableStateOf(false) }
    var successCount by remember { mutableStateOf(0) }
    var showSuccess by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.events.collect { e ->
            when (e) {
                is ShelvingEvent.Error -> { cableInput = ""; FeedbackPlayer.play(context, FeedbackPlayer.Kind.ERROR); snackbar.showSnackbar(e.message) }
                is ShelvingEvent.Flash -> { cableInput = ""; flash = true; FeedbackPlayer.play(context, FeedbackPlayer.Kind.SUCCESS) }
                is ShelvingEvent.Success -> { cableInput = ""; successCount = e.count; showSuccess = true; FeedbackPlayer.play(context, FeedbackPlayer.Kind.SUCCESS) }
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("电缆退库") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "返回") } },
            )
        },
        snackbarHost = { SnackbarHost(snackbar) },
    ) { pad ->
        Box(Modifier.fillMaxSize().padding(pad)) {
            Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(Icons.Filled.Unarchive, contentDescription = null, tint = StatusError)
                    Text("扫描电缆条码以退回 WMS", style = MaterialTheme.typography.titleMedium, color = StatusError)
                }
                OutlinedTextField(
                    value = cableInput, onValueChange = { cableInput = it },
                    label = { Text("扫描电缆条码") }, singleLine = true, modifier = Modifier.fillMaxWidth(),
                    keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(imeAction = ImeAction.Done),
                    keyboardActions = androidx.compose.foundation.text.KeyboardActions(onDone = { viewModel.onScanCable(cableInput) }),
                )
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text("待退库 ${state.count} 盘", style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
                    if (state.count > 0) TextButton(onClick = viewModel::clearList) { Text("清空") }
                }
                LazyColumn(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(state.cableList, key = { it.barcode }) { c -> CableListItemRow(c, viewModel::removeCable) }
                }
                Button(
                    onClick = { showConfirm = true }, enabled = state.canSubmit,
                    colors = ButtonDefaults.buttonColors(containerColor = StatusError),
                    modifier = Modifier.fillMaxWidth().height(56.dp),
                ) { Text("确认退库 (${state.count} 盘)") }
            }
            FlashOverlay(visible = flash, onConsumed = { flash = false })
        }
    }

    if (showConfirm) {
        AlertDialog(
            onDismissRequest = { showConfirm = false },
            title = { Text("确认退库") },
            text = { Text("将 ${state.count} 盘电缆退回 WMS？") },
            confirmButton = { TextButton(onClick = { showConfirm = false; viewModel.confirm() }) { Text("确认") } },
            dismissButton = { TextButton(onClick = { showConfirm = false }) { Text("取消") } },
        )
    }
    if (showSuccess) {
        AlertDialog(
            onDismissRequest = {},
            title = { Text("退库成功") },
            text = { Text("已退回 $successCount 盘电缆。") },
            confirmButton = { TextButton(onClick = { showSuccess = false }) { Text("确定") } },
        )
    }
}
```

- [ ] **Step 3: Build to verify Return compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(linestock): add Return view model + screen (magic RETURN), fix dead-flow init"
```

---

## Task 12: Wire the 5 screens into NavGraph (replace placeholders)

**Files:**
- Modify: `app/src/main/java/com/bizlink/wmpda/core/nav/NavGraph.kt`

> Plan 1 routes `STOCK_QUERY/SHELVING/REMOVAL/RECEIVING/RETURN` to a `listOf(...).forEach { composable(route){ … "待实现" } }` placeholder block. We REMOVE those five routes from that list and add real `composable(route){ … }` entries. The shelving route accepts an optional `barcode` argument passed from Stock Query's '开始上架'.

- [ ] **Step 1: Add imports to `NavGraph.kt`** (alongside the existing imports)

```kotlin
import androidx.navigation.NavType
import androidx.navigation.navArgument
import com.bizlink.wmpda.core.nav.Routes
import com.bizlink.wmpda.feature.linestock.ui.ReceivingScreen
import com.bizlink.wmpda.feature.linestock.ui.RemovalScreen
import com.bizlink.wmpda.feature.linestock.ui.ReturnScreen
import com.bizlink.wmpda.feature.linestock.ui.ShelvingScreen
import com.bizlink.wmpda.feature.linestock.ui.StockQueryScreen
```

- [ ] **Step 2: Shrink the placeholder list** — remove the five LineStock routes so only warehouse/picking placeholders remain

Find this block (from Plan 1 Task 9):

```kotlin
        // Placeholder destinations — replaced by feature plans 2–4.
        listOf(
            Routes.PICKING, Routes.STOCK_QUERY, Routes.SHELVING, Routes.REMOVAL,
            Routes.RECEIVING, Routes.RETURN, Routes.WAREHOUSE_INBOUND, Routes.WAREHOUSE_RETURN,
        ).forEach { route ->
```

Replace ONLY the `listOf(...)` argument with (PICKING + warehouse routes remain placeholders; the 5 LineStock routes are removed):

```kotlin
        // Placeholder destinations — replaced by feature plans 2 & 4.
        listOf(
            Routes.PICKING, Routes.WAREHOUSE_INBOUND, Routes.WAREHOUSE_RETURN,
        ).forEach { route ->
```

- [ ] **Step 3: Add the five real composables** inside the `NavHost { … }` (after the `WORKBENCH` composable, before the placeholder `listOf` block). The shelving route is registered twice: a no-arg base route (`SHELVING`) and an arg route (`SHELVING?barcode={barcode}`) so Stock Query can deep-link with a pre-filled cable.

```kotlin
        composable(Routes.STOCK_QUERY) {
            StockQueryScreen(
                onBack = { navController.popBackStack() },
                onStartShelving = { barcode -> navController.navigate("${Routes.SHELVING}?barcode=$barcode") },
            )
        }
        composable(Routes.SHELVING) {
            ShelvingScreen(onBack = { navController.popBackStack() }, initialBarcode = null)
        }
        composable(
            route = "${Routes.SHELVING}?barcode={barcode}",
            arguments = listOf(navArgument("barcode") { type = NavType.StringType; nullable = true; defaultValue = null }),
        ) { entry ->
            ShelvingScreen(
                onBack = { navController.popBackStack() },
                initialBarcode = entry.arguments?.getString("barcode"),
            )
        }
        composable(Routes.REMOVAL) {
            RemovalScreen(
                onBack = { navController.popBackStack() },
                onHome = { navController.navigate(Routes.WORKBENCH) { popUpTo(Routes.WORKBENCH) { inclusive = true } } },
            )
        }
        composable(Routes.RECEIVING) {
            ReceivingScreen(
                onBack = { navController.popBackStack() },
                onHome = { navController.navigate(Routes.WORKBENCH) { popUpTo(Routes.WORKBENCH) { inclusive = true } } },
            )
        }
        composable(Routes.RETURN) {
            ReturnScreen(onBack = { navController.popBackStack() })
        }
```

- [ ] **Step 4: Build to verify navigation compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 5: Run the full unit-test suite**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest`
Expected: PASS — Plan 1 (28) + LineStockMappingTest (17) + LineStockResponseParseTest (4) + LineStockViewModelTest (3) = 52 tests green. (If Plan 2 already merged, its tests add on top.)

- [ ] **Step 6: Manual verification on device (note only)**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:installDebug` then launch.
Manual: Login → Workbench → 库存查询: scan/enter a known barcode → StockInfoCard shows; tap 开始上架 → Shelving opens with 1 cable pre-filled. Set a location (≥4 chars) → 确认 → list submits → 上架成功 dialog. 库存查询 物料模式: enter material → per-batch cards with 入库/库存/已用. 电缆下架: locked 2200-100 header; scan → list → 确认下架. 电缆入库: scan handover barcode → list → 确认入库 → server message → 返回工作台. 电缆退库: input shown immediately (NOT 初始化中); scan → 确认退库 → 退库成功. Verify: duplicate scan shows a snackbar and DOES NOT clear the list; an error does not wipe the list; the manual field clears after every success and error. (Without a reachable WMS, scans surface the network-error snackbar — confirms the error path renders and the list survives.)

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat(linestock): wire 5 LineStock screens into NavGraph (replace placeholders)"
```

---

## Self-Review (performed by plan author)

**Spec §5.4 coverage:**
- 库存查询 byBarcode/byMaterialCode → Task 1 (WmsApi) + Task 6 (ViewModel/Screen). ✓
- 电缆上架 transfer {scanned location} → Task 8. ✓
- 电缆下架 transfer {'2200-100'} → Task 9. ✓
- 电缆入库 GetHandoverListByBarcode → HandoverConfirm → Task 10. ✓
- 电缆退库 transfer {'RETURN'} → Task 11. ✓
- factoryId from SessionManager → Task 4 (`factoryId()` reads `session.current().factoryId`). ✓
- Routes replaced: STOCK_QUERY, SHELVING, REMOVAL, RECEIVING, RETURN → Task 12. ✓

**bugLessons re-encoded:** (1) per-flow ViewModel, no runtimeType/previousState — Tasks 6/8/9/10/11 (separate VMs). (2) errors = one-shot SharedFlow events, list lives in StateFlow — all VMs; pinned by `LineStockViewModelTest`. (3) duplicate rejection keeps list — Task 8 test + `isDuplicate`. (4) already-at-target rejection — Task 8 test + `isAlreadyAtTarget`. (5) transfer needs isSuccess && data==true — `decodeTransferData` (Task 2 tests). (6) empty material list = error — `MaterialResult.NotFound` (Task 4) + parse test (Task 3). (7) Return starts in empty in-progress state — Task 11 (`ReturnUiState()` initial). (8) JSON casing barCode/id|stockId/data:false — Task 1 DTOs + Task 3 parse tests. (9) explicit field clear on success+error — every Screen's `events.collect` sets `input=""`. (10) no debug prints — repository/VMs contain none.

**Type consistency:** `LineStockRepository` sealed result names (`StockResult`, `MaterialResult`, `TransferResult`, `HandoverQueryResult`, `HandoverConfirmResult`) are referenced identically in Tasks 6/8/9/10/11 and the fake in Task 7. `ShelvingEvent` is reused by Removal and Return; Receiving uses its own `ReceivingEvent`. `LineStockMapping` function names (`isValidBarcode/Location/Material`, `isDuplicate`, `isDuplicateHandover`, `isAlreadyAtTarget`, `toCable`, `toHandover`, `decodeTransferData`, `decodeSingleStock`, `toMaterialSummary`, `parseHandover`, `parseMaterialList`, `resolveStockId`) are consistent across tasks. Constants `LINE_STOCK_LOCATION="2200-100"` and `RETURN_LOCATION="RETURN"` defined once each.

**Placeholder scan:** No TBD/TODO/"handle errors"/"similar to" — all code blocks complete.

---

## Done criteria

- `./gradlew :app:assembleDebug` succeeds.
- `./gradlew :app:testDebugUnitTest` green: 24 new linestock tests (17 mapping + 4 parse + 3 view model) on top of Plan 1's 28 (≥52 total).
- Five routes (`STOCK_QUERY`, `SHELVING`, `REMOVAL`, `RECEIVING`, `RETURN`) resolve to real screens; the NavGraph placeholder list no longer contains them.
- Each of the five flows has its OWN ViewModel + immutable UiState (`StockQueryUiState`/`ShelvingUiState`/`RemovalUiState`/`ReceivingUiState`/`ReturnUiState`); no shared state union, no `runtimeType` sniffing, no `previousState` recursion.
- The in-progress list lives in StateFlow and survives error events (verified by `LineStockViewModelTest`); duplicate and already-at-target scans are rejected without wiping the list; manual entry fields clear on success AND error.
- `transfer` success is gated on `isSuccess==true && data==true`; empty material-query list surfaces 「未找到」; Return opens directly in an empty in-progress state (no 初始化中 dead-flow).
- `factoryId` is read from `SessionManager` (never hardcoded `2`); request bodies use `barcode/barCodes`, responses decode `barCode` and `id|stockId`, and `byBarcode` `data:false` decodes to not-found.
- No debug prints anywhere in `feature/linestock/`.

## Hand-off note for other plans

- `WmsApi.kt` now also has the 5 LineStock endpoints — Plan 4 (中央立库) must keep its additions purely additive and not touch these.
- `AppContainer.lineStockRepository` is now a wired `by lazy` property — mirror this pattern for the warehouse repository.
- `ShelvingEvent` is shared by Shelving/Removal/Return; if Plan 4 needs a similar one-shot event type, define its OWN (do not reuse `ShelvingEvent`).
- `LineStockMapping.decodeTransferData` (success = isSuccess && data==true) and the `extractMessage` helper pattern are reusable references for warehouse command decoding, but copy/rename rather than depend across features.
