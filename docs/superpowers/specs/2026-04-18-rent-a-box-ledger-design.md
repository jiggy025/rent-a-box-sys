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

### 4.3 Vacancy Rules

- Boxes with no active assignment are shown as vacant.
- Vacant boxes remain visible on the dashboard.
- Vacant boxes cannot accept new log entries until a seller is assigned.

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

## 6. Screen Design

### 6.1 First-Launch Setup

Shown only when there are no active rental assignments yet.

Purpose:
- eliminate empty-state confusion
- ensure the user can reach a usable dashboard with real data quickly

Recommended flow:
1. Create first seller
2. Create first box
3. Create first rental assignment linking the seller to the box
4. Enter dashboard

Notes:
- keep this setup lightweight and fast
- do not turn first launch into a long onboarding sequence

### 6.2 Dashboard

This is the main home screen for daily use.

Content:
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

Navigation:
- tap a box card to open box detail
- tap a seller name to open seller history

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

### 6.4 Seller History

This screen exists to preserve seller-centric records across multiple rental periods.

Content:
- seller profile information
- active boxes currently rented by the seller
- previous box assignments
- lifetime summaries and totals across all assignments

Purpose:
- keep long-term records on the seller side
- avoid mixing previous renters into a box's current live total

### 6.5 Reassign Box Flow

Used when a box changes renter.

Flow:
1. open reassign action from dashboard or box detail
2. confirm the current assignment will be closed
3. select an existing seller or create a new seller
4. create a new active rental assignment for the box

Result:
- old assignment becomes historical
- new assignment becomes the source of the live total and visible current history

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

Supporting query patterns:
- active dashboard boxes joined with active assignments and sellers
- assignment-scoped totals using `SUM(price)`
- seller history across assignments
- vacancy detection for boxes with no active assignment

### 7.3 Reactive Data Flow

- dashboard watches the current set of boxes and active assignments
- each box total is calculated from log entries tied to that active assignment
- box detail watches one assignment and its entries
- seller history watches one seller and all related assignments
- first-launch setup state is derived from whether active assignments exist

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
- first-launch setup appears when there are no active assignments
- dashboard renders occupied and vacant boxes correctly
- box detail rapid-entry form validates and submits correctly
- totals update immediately after a new entry is added
- seller history shows cross-assignment records

## 11. V1 Scope

Included:
- first-launch setup
- seller creation
- box creation
- rental assignment creation
- box reassignment
- dashboard with search
- modern box-style dashboard cards
- box detail rapid-entry logging
- seller history view
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
- complete first launch setup quickly
- see a dashboard of boxes that visually feels like rentable boxes
- add sellers and boxes from the dashboard
- reassign a box without losing historical seller records
- log entries quickly from a phone
- trust that each box total reflects only the current renter
- review seller history across multiple rental periods
- use the app fully offline
