# E-Carding Database Schema Documentation

## Overview
Comprehensive E-Carding system schema for MySQL with immutable audit trails, designed for government payroll and financial management systems.

## Core Modules

### 1. **Human Resources Module**

#### Tables:
- **departments**: Organizational departments with hierarchical structure
- **positions**: Job positions with salary grades and levels
- **employees**: Complete employee records with personal, employment, and government ID information

**Key Features:**
- Hierarchical department structure (parent-child relationships)
- Department heads linked to employees
- Comprehensive employee information (personal, contact, employment, compensation)
- Support for multiple employment types and statuses
- Government IDs (SSS, PhilHealth, PAG-IBIG, TIN, GSIS)
- Soft deletes for data retention

---

### 2. **Payroll Module**

#### Tables:
- **payroll_periods**: Pay period definitions (monthly, semi-monthly, bi-weekly)
- **payrolls**: Individual payroll records with earnings and deductions
- **payroll_deductions**: Itemized deductions per payroll
- **payroll_benefits**: Itemized benefits per payroll
- **deduction_types**: Master list of deduction types
- **benefit_types**: Master list of benefit types

**Key Features:**
- Flexible pay period configurations
- Comprehensive earnings tracking (base, overtime, night diff, hazard pay, allowances, bonuses)
- Government contributions (SSS, PhilHealth, PAG-IBIG, GSIS)
- Withholding tax calculations
- Loan deductions integration
- Approval workflow integration
- Work hours and days tracking

---

### 3. **Loan Management Module**

#### Tables:
- **loan_types**: Configurable loan types with interest rates and terms
- **loans**: Individual loan records with amortization schedules
- **loan_payments**: Detailed payment tracking per loan
- **loan_restructures**: Loan modification history

**Key Features:**
- Multiple loan types with configurable parameters
- Interest rate calculations
- Guarantor support (up to 2 guarantors)
- Automated amortization scheduling
- Payment tracking with principal/interest breakdown
- Overdue payment monitoring
- Loan restructuring capability
- Integration with payroll deductions

---

### 4. **Obligation Request Status (ORS) Module**

#### Tables:
- **budget_years**: Fiscal year management
- **budget_categories**: Hierarchical budget classification
- **budget_allocations**: Department budget allocations per category
- **obligation_requests**: ORS/ALOBS requests for obligations
- **obligation_items**: Line items for obligation requests
- **disbursement_vouchers**: Payment vouchers for approved obligations

**Key Features:**
- Multi-year budget tracking
- Department-based budget allocation
- Category-based budget classification
- Comprehensive ORS workflow
- Support for multiple payment modes
- Budget utilization monitoring (allocated, obligated, disbursed)
- Check and bank transfer management
- Integration with approval workflow

---

### 5. **General Ledger Module**

#### Tables:
- **chart_of_accounts**: Complete chart of accounts with hierarchical structure
- **ledger_entries**: Journal entries (standard, adjusting, closing)
- **ledger_lines**: Individual debit/credit lines per entry
- **account_balances**: Monthly account balance tracking
- **bank_accounts**: Bank account management
- **bank_transactions**: Bank transaction monitoring and reconciliation

**Key Features:**
- Hierarchical chart of accounts
- Double-entry accounting
- Multiple entry types (standard, adjusting, closing, reversing)
- Source document tracking (polymorphic relationships)
- Cost center and project tracking
- Monthly balance aggregation
- Bank reconciliation support
- Multi-dimensional analysis (department, cost center, project, program)

---

### 6. **Approval Workflow Module**

#### Tables:
- **approval_workflows**: Workflow definitions per model type
- **approval_levels**: Multi-level approval hierarchy
- **approval_requests**: Individual approval requests
- **approval_actions**: Detailed approval actions and history
- **approval_notifications**: User notifications for pending approvals
- **approval_delegates**: Temporary delegation of approval authority
- **approval_templates**: Notification templates

**Key Features:**
- Flexible multi-level approval workflows
- Sequential or parallel approval support
- Role-based or position-based approvers
- SLA tracking and enforcement
- Approval delegation capability
- Digital signature support
- Comprehensive notification system
- Approval history and audit trail
- Conditional workflow routing

---

### 7. **Immutable Audit System**

#### Tables:
- **audit_logs**: Comprehensive system-wide audit trail
- **financial_audit_logs**: Specialized financial transaction audit
- **data_access_logs**: Data access monitoring for compliance
- **system_event_logs**: System events, errors, and security incidents
- **audit_log_summaries**: Aggregated audit statistics

**Key Features:**
- **Append-only design**: No updates or deletes allowed
- **Hash chain integrity**: Blockchain-style record linking
- **Tamper detection**: SHA-256 hashing of records
- **Comprehensive context**: User, IP, session, request details
- **Before/after snapshots**: Complete state tracking
- **Financial compliance**: Specialized money trail
- **Data protection**: PII and sensitive data tracking
- **Risk classification**: Severity and risk level tracking
- **Retention policies**: Automated data lifecycle management
- **Performance optimized**: Partitioning-ready design

---

## Security Features

1. **Data Integrity**
   - Hash chains for audit logs
   - Digital signature support
   - Immutable audit trails

2. **Access Control**
   - Role-based permissions (via Spatie)
   - Activity logging
   - Data access monitoring

3. **Compliance**
   - PII tracking and protection
   - Financial transaction audit
   - Data retention policies
   - GDPR-ready architecture

4. **Audit Trail**
   - Complete change history
   - User action tracking
   - IP and session logging
   - Request/response logging

---

## Relationships & Integrity

### Foreign Key Constraints
- All critical relationships use RESTRICT on delete to prevent data loss
- Non-critical relationships use SET NULL or CASCADE appropriately
- Soft deletes preserve referential integrity

### Polymorphic Relationships
- Approval workflow: `approvable_type` / `approvable_id`
- Audit logs: `auditable_type` / `auditable_id`
- Ledger entries: `source_type` / `source_id`

### Indexing Strategy
- Primary keys on all tables
- Foreign key indexes for join performance
- Composite indexes for common query patterns
- Full-text indexes for search functionality
- Date-based indexes for temporal queries

---

## Data Types & Precision

### Financial Amounts
- `DECIMAL(15,2)`: Standard for money amounts (up to 999,999,999,999.99)

### Status Fields
- ENUMs for predefined status values
- Indexed for query performance

### Dates & Times
- `DATE`: For business dates
- `TIMESTAMP`: For audit and event tracking
- Uses Laravel's timestamp helpers

---

## Migration Order

1. `2026_03_19_140000` - departments (without fk to employees)
2. `2026_03_19_140001` - positions
3. `2026_03_19_140002` - employees
4. `2026_03_19_140003` - payroll tables
5. `2026_03_19_140004` - loans tables
6. `2026_03_19_140005` - ORS tables
7. `2026_03_19_140006` - ledger tables
8. `2026_03_19_140007` - approval workflow tables
9. `2026_03_19_140008` - immutable audit tables

---

## Next Steps

### 1. Run Migrations
```bash
php artisan migrate
```

### 2. Create Eloquent Models
Generate models for all tables with relationships

### 3. Create Seeders
- Default chart of accounts
- Budget categories
- Loan types
- Deduction/benefit types
- Default approval workflows

### 4. Implement Observers
- Generate audit logs automatically
- Calculate hash chains
- Update account balances
- Track data access

### 5. Create Services
- PayrollService
- LoanService
- ORSService
- LedgerService
- ApprovalService
- AuditService

---

## Performance Considerations

1. **Partitioning**: Audit tables should be partitioned by date
2. **Archiving**: Old audit logs should be archived periodically
3. **Indexing**: Monitor slow queries and add indexes as needed
4. **Caching**: Consider Redis for frequently accessed data
5. **Read Replicas**: For reporting queries

---

## Compliance & Regulations

This schema supports:
- COA (Commission on Audit) requirements
- DBM (Department of Budget and Management) guidelines
- BIR (Bureau of Internal Revenue) reporting
- SSS, PhilHealth, PAG-IBIG reporting
- GSIS compliance
- Data Privacy Act compliance

---

**Generated**: March 19, 2026
**Version**: 1.0
**Database**: MySQL 8.0+
**Framework**: Laravel 11.x
