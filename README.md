# DineFlowX

DineFlowX is a full restaurant operations platform built with Flutter + Firebase for modern dine-in, takeaway, and delivery businesses.

It provides two connected experiences in one codebase:
- Admin app for business operations, menu control, order flow, staff/roles/permissions, reporting, printer setup, and expenses.
- Client app for browsing menu items, cart/checkout, ordering, favorites, and profile/history flows.

The system is designed for multi-business, multi-branch usage, with role-based access control and real-time cloud data.

---

## Core Highlights

- Multi-tenant data model: business -> branch -> operational collections.
- Role and permission-based access control (fine-grained module visibility).
- Real-time order and table workflows.
- Menu, category, and product management with image upload to Firebase Storage.
- Sales analytics dashboard with revenue tracking.
- Expense management with profit/loss calculation in reports.
- QR-code and table support for dine-in operations.
- Thermal printer support for receipt workflows.
- Cross-platform Flutter target support (Web, Android, iOS, Windows, macOS, Linux).

---

## Feature Set

## Admin Features

- Authentication and startup initialization flow.
- Dashboard overview of live operations.
- Business and branch management.
- Room and table management.
- QR code management for table workflows.
- Staff management.
- Role management.
- Permission management.
- Order management:
	- Active orders
	- Completed orders
	- Create/order edit flows
	- Waiter assignment
	- Status updates
	- Receipt generation and print options
- Menu management.
- Category management.
- Product management:
	- Product CRUD
	- Availability toggles
	- Product image upload and update
- Sales report dashboard:
	- Revenue trend
	- Order type breakdown
	- Top-selling products
	- Exportable PDF report
- Expense management:
	- Add/edit/delete expenses
	- Date-aware expense tracking
	- Total expense summary
- Profit and Loss reporting:
	- Profit/Loss = Total Revenue - Total Expenses
	- Included in report stats and PDF export summary
- Printer integration for operational printing.

## Client Features

- Onboarding flow.
- Login and signup.
- Home/menu browsing.
- Category and product views.
- Product detail and favorites.
- Cart and checkout flows.
- Order history.
- Profile view.

---

## Tech Stack

- Flutter + Dart
- Riverpod (state management)
- Firebase Core
- Cloud Firestore (primary database)
- Firebase Auth
- Firebase Storage (product/category/menu image storage)
- PDF + Printing packages (report/receipt exports)
- Image Picker / image processing utilities

---

## Data Architecture (High Level)

Data is organized per business and branch to keep operations isolated:

- businesses/{businessId}
- businesses/{businessId}/branches/{branchId}
- businesses/{businessId}/branches/{branchId}/orders
- businesses/{businessId}/branches/{branchId}/products
- businesses/{businessId}/branches/{branchId}/categories
- businesses/{businessId}/branches/{branchId}/menus
- businesses/{businessId}/branches/{branchId}/rooms
- businesses/{businessId}/branches/{branchId}/diningTables
- businesses/{businessId}/branches/{branchId}/roles
- businesses/{businessId}/branches/{branchId}/permissions
- businesses/{businessId}/branches/{branchId}/expenses

Storage paths follow the same tenancy model:

- businesses/{businessId}/branches/{branchId}/product_images
- businesses/{businessId}/branches/{branchId}/category_images
- businesses/{businessId}/branches/{branchId}/menu_images

---

## Run Locally

## Prerequisites

- Flutter SDK installed
- Firebase project configured
- Platform-specific Firebase files generated (already included in this repository)

## Commands

```bash
flutter clean
flutter pub get
flutter run -d chrome
```

Use other device targets similarly:

```bash
flutter run -d android
flutter run -d windows
```

---

## Firebase Notes

- Firestore is the source of truth for business, menu, order, role, report, and expense data.
- Firebase Storage is used for media assets (especially product images).
- For web image rendering, ensure Storage is initialized and rules/CORS are correctly configured in your Firebase project.

---

## Current Status

DineFlowX is an actively evolving production-style app with rich admin operations and client ordering features. The codebase includes startup management, seeded demo paths, and modular service/repository/state layers for maintainability and scale.

---

## License

This project currently does not define a public open-source license in repository settings. Add a license if you want to allow public reuse.
