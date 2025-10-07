# System Architecture

## Overview

Shop1 CMMS is a modern, multi-tenant Computerized Maintenance Management System built with Phoenix LiveView that integrates seamlessly with the existing Shop1FinishLine ERP system.

## Architecture Diagram

```text
┌─────────────────────────────────────────────────────────────┐
│                        Frontend Layer                       │
├─────────────────────────────────────────────────────────────┤
│  Phoenix LiveView  │  Tailwind CSS  │  Alpine.js (Future)   │
├─────────────────────────────────────────────────────────────┤
│                     Application Layer                       │
├─────────────────────────────────────────────────────────────┤
│    Contexts    │   LiveViews   │  Controllers  │   Auth     │
├─────────────────────────────────────────────────────────────┤
│                      Database Layer                         │
├─────────────────────────────────────────────────────────────┤
│  PostgreSQL 14+  │  Row-Level Security  │  Shop1 Integration│
└─────────────────────────────────────────────────────────────┘
```

## Design Principles

### 1. Multi-Tenant Architecture

- **Data Isolation**: Row-Level Security (RLS) at database level
- **Tenant Context**: Session-based tenant switching
- **Scalability**: Horizontal scaling support

### 2. Integration-First Design

- Seamless integration with Shop1FinishLine ERP
- Shared user authentication and authorization
- Unified data model across systems

### 3. Real-Time Updates

- Phoenix LiveView for real-time UI updates
- WebSocket connections for instant notifications
- Optimistic UI updates for better user experience

## Technology Stack

- **Framework**: Phoenix LiveView 1.7.14
- **Language**: Elixir 1.15+ / OTP 26+
- **Database**: PostgreSQL 14+ with Row-Level Security
- **CSS Framework**: Tailwind CSS 3.x
- **JavaScript**: Minimal vanilla JS, Alpine.js (future)
- **Authentication**: Shared with Shop1FinishLine
- **Deployment**: Docker containerization

## Core Components

### Contexts (Business Logic)

- **Assets**: Asset management and tracking
- **WorkOrders**: Work order lifecycle management
- **PreventiveMaintenance**: PM scheduling and execution
- **Accounts**: User management and authentication
- **Tenants**: Multi-tenant support

### LiveViews (UI Components)

- **DashboardLive**: Main dashboard with metrics
- **AssetsLive**: Asset listing and management
- **AssetDetailLive**: Individual asset details
- **WorkOrdersLive**: Work order management
- **PreventiveMaintenanceLive**: PM management

### Database Schema

- Multi-tenant with `tenant_id` on all tables
- Row-Level Security policies
- Integration tables for Shop1FinishLine data
- Audit trails for compliance

## Security Model

### Authentication

- Shared authentication with Shop1FinishLine
- Session-based authentication
- Role-based access control (RBAC)

### Authorization

- Five user roles: System Admin, Tenant Admin, Maintenance Manager, Technician, Viewer
- Permission-based access to features
- Tenant-specific data access

### Data Protection

- Row-Level Security (RLS) at database level
- Encrypted sensitive data
- Audit logging for compliance
- SQL injection protection through Ecto

## Integration Points

### Shop1FinishLine ERP

- Shared user database
- Asset data synchronization
- Cost center integration
- Report data sharing

### External Systems (Future)

- Equipment manufacturer APIs
- Parts supplier systems
- IoT sensor data
- Mobile applications

## Performance Considerations

### Database Optimization

- Proper indexing strategy
- Query optimization
- Connection pooling
- Read replicas for reporting

### Application Performance

- Efficient LiveView updates
- Proper caching strategies
- Background job processing with Oban
- Memory management

### Scalability

- Horizontal scaling support
- Load balancing
- Database sharding (future)
- CDN for static assets

---

**Note:** This document consolidates information from ARCHITECTURE.md and CMMS_ARCHITECTURE.md