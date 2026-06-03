# DineFlowX App Features Documentation

## 1. Product Overview
DineFlowX is a multi-tenant restaurant management and online ordering platform built with Flutter and Firebase.
It has two primary web experiences:
- Main/Admin app for owners, managers, and staff
- Client app for guest ordering via direct links and QR codes

## 2. Core Architecture
- Flutter app with Riverpod-based state management
- Firebase Firestore for data storage
- Firebase Authentication for admin/staff authentication
- Firebase Hosting with multi-site setup:
  - Main app: dineflowx.web.app
  - Client app: dineflowx-client.web.app
- Multi-tenant data model centered around:
  - businesses/{businessId}
  - businesses/{businessId}/branches/{branchId}/...

## 3. Multi-Tenant Business Model
Each business is isolated by businessId and branchId.
Main entities include:
- Business profile and settings
- Branches
- Roles and permissions
- Users/staff
- Menus, categories, products
- Dining tables and table QR
- Orders and order lifecycle
- Expenses and reporting data

## 4. Admin/Main App Features
### 4.1 Authentication and Access
- Admin and staff login flows
- Super-admin access path for platform-level management
- Role + permission based UI and action control
- Business and branch contextual access

### 4.2 Dashboard
- Operational overview of business activity
- Active order visibility
- Entry points to major management screens

### 4.3 Business Branding and Profile
- User profile management
- Business branding management (name/logo)
- Copyable online ordering link generation
- Current reliable client link format:
  - https://dineflowx-client.web.app/{businessId}

### 4.4 Menu Management
- Category CRUD
- Product CRUD
- Menu linking and menu visibility management
- Product-level image handling via storage service

### 4.5 Table and Floor Operations
- Dining table CRUD
- Room/table assignment support
- Table state transitions (available/occupied/reserved/cleaning)
- QR generation for table-based ordering context

### 4.6 Order Management
- Create and manage orders
- Active orders workflow
- Order history and status updates
- Checkout orchestration and totals
- Receipt generation and thermal print support

### 4.7 Sales and Expenses
- Expense tracking modules
- Sales repository and analytics hooks
- Profit/loss-oriented reporting paths

## 5. Client App Features
### 5.1 Public Entry and Routing
- Public client app access without admin login
- Business-specific entry route:
  - /{businessId}
- Backward-compatible route support for older URLs
- Branch and table context through query parameters when needed

### 5.2 Guest Ordering Experience
- Browse categories and products
- Add-to-cart and checkout flow
- Order placement from table context (QR)
- Profile and order history screens for client users

### 5.3 QR and Direct Link Flow
- QR links include tenant context (business/branch/table)
- Public menu read and guest order creation enabled by Firestore rules
- Works in logged-out browser sessions for customer ordering

## 6. Offline-First and Sync Enhancements
The codebase includes offline-oriented services and queueing patterns for resilient operations:
- Firestore write queue support for deferred sync
- Offline order queue and retry behavior
- Offline media upload queue support
- Local cache and merge-safe update behavior to reduce data loss
- Best-effort side effects to prevent hard blocking of core writes

Related architecture note:
- docs/OFFLINE_FIRST_ARCHITECTURE.md

## 7. Security and Rules
Firestore rules are implemented to support:
- Tenant isolation for admin/staff data
- Super-admin controls
- Public read access for active business client-menu paths
- Guest order create permissions with guard checks
- Additional key documents used by client URL resolution flow

## 8. URL and Hosting Strategy
### 8.1 Current Production Hosts
- Main/Admin: https://dineflowx.web.app
- Client: https://dineflowx-client.web.app

### 8.2 Recommended Stable Client Link
Use businessId-based URLs for maximum reliability:
- https://dineflowx-client.web.app/RLX1016

## 9. Platform and Build Notes
- Flutter web builds may show Wasm dry-run compatibility warnings
- These warnings do not block standard JS web deploys
- Main and client targets are built separately and deployed via Firebase hosting targets

## 10. Typical Deployment Commands
From project root:

```powershell
flutter build web --release --target lib/main.dart --output build/web-main
flutter build web --release --target lib/main_client.dart --output build/web-client
firebase deploy --only hosting:main,hosting:client
```

Rules deploy when needed:

```powershell
firebase deploy --only firestore:rules
```

## 11. Current Known Operational Guidance
- For share links, prefer businessId path links
- If a business name URL is requested, keep businessId fallback available
- Keep admin and client deployments in sync after routing or link-generation changes

## 12. Future Enhancement Ideas
- Add explicit slug field per business with uniqueness constraints
- Provide slug management UI in admin profile
- Add automated key backfill/migration for existing businesses
- Add integration tests for public client route resolution
