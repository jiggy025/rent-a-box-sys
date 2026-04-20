# Rent-a-Box Ledger Design

**Date:** 2026-04-18
**Platform:** Android phone
**App Type:** Local-first Flutter + Dart app with full offline operation
**Primary Users:** Store owner and cashier managing rentable display boxes and seller sales logs

## 1. Goal

Build an Android-first ledger app for a concept store that lets the store owner or cashier:
- manage sellers and boxes locally on-device
- assign sellers to boxes
- log item claims or sales quickly
- see live totals for the current renter of each box
- preserve long-term seller history across changing box rentals

The app must work fully offline and must not depend on any cloud service for V1.

## 2. Product Principles

- **Local-first:** All data is stored and queried on-device with SQLite.
- **Offline-first:** Core usage must work without internet access.
- **Fast-entry:** Logging an item sale should be quick from a phone screen.
- **Clear box identity:** The dashboard must visually communicate that each tile represents a rentable box.
- **Accurate current totals:** A box total must only reflect the current active rental assignment.
- **Persistent seller history:** A returning seller must reuse the same seller record so long-term history stays intact.

## 3. Core Domain Model

The original seed spec is adjusted to support persistent seller history and assignment-scoped totals.

### 3.1 Seller

Represents a seller identity that persists over time.

Fields:
- `id`
- `name`
- `contactInfo`
- `isActive`
- `inactiveAt`
- `createdAt`
- `updatedAt`

Rules:
- A seller record is reused if the seller leaves and later returns.
- A seller can be associated with multiple boxes at the same time through multiple active rental assignments.

### 3.2 Box

Represents a physical rentable box in the store.

Fields:
- `id`
- `boxNumber`
- `isActive`
- `createdAt`
- `updatedAt`

Rules:
- A box can have at most one active rental assignment at a time.
- A box may exist in a vacant state with no active assignment.

### 3.3 RentalAssignment

Represents a rental period linking one seller to one box.

Fields:
- `id`
- `sellerId`
- `boxId`
- `startedAt`
- `endedAt` nullable
- `createdAt`

Rules:
- `endedAt == null` means the assignment is active.
- Reassigning a box ends the current assignment and creates a new one.
- This record is the boundary for live totals and current history.

### 3.4 LogEntry

Represents a single logged item claim or sale.

Fields:
- `id`
- `rentalAssignmentId`
- `itemName`
- `price`
- `claimerName`
- `timestamp`

Rules:
- Each entry belongs to exactly one rental assignment.
- Dashboard totals are computed from entries under the active assignment only.
- Historical entries remain attached to the assignment they were created under.

### 3.5 SellerAdjustment

Represents seller-level money going out of the ledger.

Fields:
- `id`
- `sellerId`
- `type`
- `amount`
- `reason`
- `createdAt`

Rules:
- `type` is either `cashOut` or `manualDeduction`.
- seller adjustments reduce available balance but do not reduce lifetime sales
- manual deductions require a reason
- amounts cannot exceed the seller's current available balance

## 4. Business Rules

### 4.1 Seller and Box Rules

- A seller may rent multiple boxes at the same time.
- A box may only have one active seller at a time.
- Seller reuse is required for long-term history and records.
- Box reassignment is a normal workflow and must be supported directly in the app.

### 4.2 Totals and History Rules

- A box card on the dashboard shows the total for the current active assignment only.
- When a box is reassigned, the new seller starts with a clean live total for that box.
- Previous totals and entries remain available in historical records through the closed assignment.
- Seller history may aggregate across all past and present assignments linked to that seller.
- `Lifetime Sales` is the total of all seller sales across all assignments and never decreases.
- `Available Balance` is seller sales minus seller adjustments and is the amount available for cash out or deduction.
- `Active Boxes Total` may still exist as a derived value in the data model, but it should not be surfaced as a primary top-line seller summary because it duplicates information shown elsewhere.

### 4.3 Vacancy Rules

- Boxes with no active assignment are shown as vacant.
- Vacant boxes remain visible on the dashboard.
- Vacant boxes cannot accept new log entries until a seller is assigned.

### 4.4 Seller Status and Payout Rules

- Sellers can be marked inactive without deleting their history.
- Marking a seller inactive closes all active assignments for that seller and makes those boxes vacant.
- Inactive sellers remain reusable if they return later.
- Cash out and manual deduction are separate actions so the ledger stays understandable for the cashier and seller.
- The seller transaction history merges:
  - positive sale entries from `log_entries`
  - negative `cashOut` entries from `seller_adjustments`
  - negative `manualDeduction` entries from `seller_adjustments`

## 5. User Experience Design

### 5.1 Visual Direction

The app should feel practical, warm, and easy to use on an Android phone rather than like a generic CRUD admin tool.

UI direction:
- Material 3 base with custom styling
- warm neutral palette inspired by packaging and display-box materials
- strong legibility for seller names and totals
- generous tap targets and spacing for cashier use
- a polished visual language that still feels operational and trustworthy

### 5.2 Dashboard Card Direction

The selected dashboard direction is the **Modern Box Card**.

Characteristics:
- each dashboard tile clearly communicates that it is a physical box
- cards use subtle packaging cues such as folded-corner or panel details
- occupied versus vacant state is visually obvious
- current seller and live total are readable at a glance
- design stays modern and clean instead of cartoonish or overly decorative

### 5.3 Splash and Onboarding Direction

The app should feel branded and welcoming on launch, but onboarding should not block the cashier from reaching the actual working dashboard.

Selected direction:
- show a short branded `Espasyo` splash screen on launch
- always land on the dashboard after the splash
- replace the old forced first-launch setup flow with a dashboard-based step-by-step guide

Onboarding principles:
- guide users inside the real product instead of a separate wizard
- keep setup instructional, not mandatory
- allow reopening the guide later through a dashboard help action

## 6. Screen Design

### 6.1 Splash Screen

Shown on app launch before entering the dashboard.

Behavior:
- display the `Espasyo.png` artwork centered on a warm cream background
- use a full-screen presentation with a short automatic transition of about `1.8 seconds`
- no interactive controls are needed

Purpose:
- introduce the app brand cleanly
- make startup feel intentional rather than abrupt

### 6.2 Dashboard

This is the main home screen for daily use.

Content:
- optional dashboard guide card at the top when the app is empty or only partly configured
- search bar for box number or seller name
- phone-friendly two-column grid of box cards
- each card shows:
  - box number
  - occupancy status
  - current seller name if occupied
  - live total for the current active assignment
- vacant boxes stay visible and clearly labeled

Actions:
- `Add Seller`
- `Add Box`
- `Reassign Box`
- `Help`
- `Sellers`

Navigation:
- tap a box card to open box detail
- tap a seller name to open seller detail/history

Dashboard guide behavior:
- while the app is incomplete, show a large `How to use Espasyo` guide card above the search bar
- the guide is reactive to actual data state
- completed steps show as done
- the next incomplete step gets the strongest emphasis
- once the user has at least one seller, one box, and one active assignment, replace the large guide card with a smaller help card
- the app bar help action always reopens the full guide

Guide steps:
1. `Add your first seller`
2. `Add your first box`
3. `Occupy a vacant box`
4. `Tap a box to add sales`
5. `Manage seller payouts`

### 6.3 Box Detail

This is the rapid-entry screen for the current box assignment.

Content:
- box number
- current seller name
- current live total
- fast entry form with:
  - item name
  - price
  - claimer name
- current assignment history list ordered newest first

Behavior:
- adding a new entry updates total and history immediately
- only entries from the current assignment are shown in the default history list
- if the box is vacant, the screen should show a clear action such as `Occupy this vacant box`

### 6.4 Seller Detail and History

This screen exists to preserve seller-centric records across multiple rental periods while also supporting cashier payout workflows.

Content:
- seller name and status
- top-line summary cards for:
  - `Available Balance`
  - `Lifetime Sales`
- action buttons for:
  - `Cash Out`
  - `Manual Deduction`
  - `Mark Inactive`
- active boxes currently rented by the seller
- merged transaction history
- previous box assignments

Purpose:
- keep long-term records on the seller side
- avoid mixing previous renters into a box's current live total
- keep the payout and deduction workflow attached to the seller ledger

Notes:
- do not show `Active Boxes Total` as a top summary card
- the `Active Boxes` section already communicates the current live box state and values

### 6.5 Sellers List

This screen gives the cashier a searchable overview of all sellers.

Content:
- search by seller name
- active sellers first, inactive sellers after
- each seller card shows:
  - seller name
  - active or inactive status
  - available balance
  - lifetime sales
  - a small active box count line such as `1 active box`

Purpose:
- provide a fast entry point into seller payout and history management
- keep the summary list readable without duplicating too many metrics

### 6.6 Reassign Box Flow

Used when a box changes renter.

Flow:
1. open reassign action from dashboard or box detail
2. confirm the current assignment will be closed
3. select an existing seller from the database
4. create a new active rental assignment for the box

Result:
- old assignment becomes historical
- new assignment becomes the source of the live total and visible current history
- if the chosen seller was inactive, the seller is reactivated automatically

## 7. Technical Architecture

### 7.1 Stack

- `Flutter`
- `Dart`
- `Drift` for SQLite access and typed queries
- `sqlite3_flutter_libs`
- `Riverpod` for state management
- `Material 3`
- `google_fonts`
- `intl`
- `uuid`

### 7.2 Storage Model

The app uses on-device SQLite through Drift.

Expected tables:
- `sellers`
- `boxes`
- `rental_assignments`
- `log_entries`
- `seller_adjustments`

Supporting query patterns:
- active dashboard boxes joined with active assignments and sellers
- assignment-scoped totals using `SUM(price)`
- seller history across assignments
- seller available balance from sales minus adjustments
- merged seller transaction history from sales and adjustments
- vacancy detection for boxes with no active assignment

### 7.3 Reactive Data Flow

- splash transitions into a dashboard-first home flow
- dashboard watches the current set of boxes and active assignments
- dashboard guide state is derived from whether sellers, boxes, and active assignments exist
- each box total is calculated from log entries tied to that active assignment
- box detail watches one assignment and its entries
- seller detail watches seller summary, active boxes, transaction history, and assignment history
- seller list watches searchable seller ledger summaries

Drift streams should drive the UI so new entries appear without manual refresh.

## 8. Offline and Local-First Requirements

- the app must function without internet access
- there is no account, sync, or server dependency in V1
- all inserts, updates, and reads happen locally
- data remains available after app restarts because it is stored in SQLite
- no core workflow may require network connectivity

## 9. Validation and Error Handling

### 9.1 Input Validation

- seller name is required
- box number is required and should be unique
- item name is required
- price is required and must be a valid numeric currency value
- claimer name is required

### 9.2 Workflow Guards

- a box cannot receive a new log entry if it has no active assignment
- reassigning a box requires explicit confirmation
- cash out and manual deduction cannot exceed available balance
- manual deduction requires a reason
- marking a seller inactive requires explicit confirmation because it vacates active boxes
- delete flows are excluded from V1

### 9.3 State Visibility

- inactive sellers should be visibly labeled rather than silently hidden
- vacant boxes should be clearly marked
- invalid states should show understandable feedback to the user

## 10. Testing Strategy

### 10.1 Database and Domain Tests

Test coverage should verify:
- creating sellers, boxes, assignments, and log entries
- one seller holding multiple active boxes
- one box limited to one active assignment at a time
- reassignment closing the old assignment and opening a new one
- dashboard totals only including entries from the active assignment
- seller history reusing the same seller record across time

### 10.2 Widget and UI Tests

Test coverage should verify:
- splash screen appears and transitions into dashboard
- dashboard guide appears when setup is incomplete and can be reopened from help
- dashboard renders occupied and vacant boxes correctly
- box detail rapid-entry form validates and submits correctly
- totals update immediately after a new entry is added
- seller detail shows cross-assignment records
- seller cash out and manual deduction update available balance and ledger history correctly
- marking a seller inactive vacates active boxes without deleting seller history

## 11. V1 Scope

Included:
- branded splash screen
- dashboard-first how-to guide
- seller creation
- box creation
- rental assignment creation
- box reassignment
- dashboard with search
- modern box-style dashboard cards
- box detail rapid-entry logging
- sellers list
- seller detail and payout workflows
- full offline local storage

Not required for V1:
- cloud sync
- authentication
- multi-device data sharing
- advanced analytics
- bulk admin tooling

## 12. Success Criteria

V1 is successful if the user can:
- install and open the Android app with no preloaded data
- see a short branded splash before entering the app
- learn the initial workflow from the dashboard guide without being forced through a setup wizard
- see a dashboard of boxes that visually feels like rentable boxes
- add sellers and boxes from the dashboard
- reassign a box without losing historical seller records
- log entries quickly from a phone
- trust that each box total reflects only the current renter
- review seller history and payouts across multiple rental periods
- use the app fully offline
