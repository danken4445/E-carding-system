# E-Carding Schema - Quick Start Guide

## Setup Instructions

### 1. Database Configuration

Ensure your `.env` file has the correct database settings:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ecarding
DB_USERNAME=root
DB_PASSWORD=your_password
```

### 2. Create Database

```bash
mysql -u root -p
CREATE DATABASE ecarding CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;
```

### 3. Run Migrations

```bash
# Run all migrations
php artisan migrate

# If you need to refresh (WARNING: drops all tables)
php artisan migrate:fresh

# Check migration status
php artisan migrate:status
```

### 4. Migration Order

The migrations will run in this sequence:

1. **Users & Permissions** (existing Laravel + Spatie)
   - users
   - permissions, roles, model_has_permissions, model_has_roles, role_has_permissions
   - activity_log

2. **Core HR** (2026_03_19_140000-140002)
   - departments
   - positions
   - employees

3. **Payroll** (2026_03_19_140003)
   - payroll_periods
   - payroll
   - payroll_deductions, payroll_benefits
   - deduction_types, benefit_types

4. **Loans** (2026_03_19_140004)
   - loan_types
   - loans
   - loan_payments
   - loan_restructures

5. **ORS/Budget** (2026_03_19_140005)
   - budget_years
   - budget_categories
   - budget_allocations
   - obligation_requests
   - obligation_items
   - disbursement_vouchers

6. **General Ledger** (2026_03_19_140006)
   - chart_of_accounts
   - ledger_entries
   - ledger_lines
   - account_balances
   - bank_accounts
   - bank_transactions

7. **Approval Workflow** (2026_03_19_140007)
   - approval_workflows
   - approval_levels
   - approval_requests
   - approval_actions
   - approval_notifications
   - approval_delegates
   - approval_templates

8. **Audit System** (2026_03_19_140008)
   - audit_logs
   - financial_audit_logs
   - data_access_logs
   - system_event_logs
   - audit_log_summaries

9. **Foreign Key Fix** (2026_03_19_140009)
   - Add department head foreign key

---

## Schema Statistics

### Total Tables Created: 48+

**By Module:**
- HR: 3 tables
- Payroll: 6 tables
- Loans: 4 tables
- ORS/Budget: 6 tables
- Ledger: 6 tables
- Approvals: 7 tables
- Audit: 5 tables
- Core (Laravel): 11+ tables

---

## Key Features Implemented

### 1. **Immutable Audit System**
- ✅ Blockchain-style hash chains
- ✅ Tamper-proof record logging
- ✅ Financial transaction audit
- ✅ Data access monitoring
- ✅ System event logging
- ✅ PII and compliance tracking

### 2. **Comprehensive Approval Workflow**
- ✅ Multi-level approvals
- ✅ Sequential & parallel workflows
- ✅ Role-based routing
- ✅ SLA tracking
- ✅ Delegation support
- ✅ Digital signatures

### 3. **Complete Financial System**
- ✅ Double-entry bookkeeping
- ✅ Chart of accounts
- ✅ Journal entries
- ✅ Bank reconciliation
- ✅ Budget tracking
- ✅ ORS/ALOBS management

### 4. **Advanced Payroll**
- ✅ Multiple pay periods
- ✅ Government contributions
- ✅ Tax calculations
- ✅ Loan deductions
- ✅ Benefits management
- ✅ Overtime & night diff

### 5. **Loan Management**
- ✅ Multiple loan types
- ✅ Amortization schedules
- ✅ Guarantor support
- ✅ Payment tracking
- ✅ Loan restructuring
- ✅ Overdue monitoring

---

## Security & Compliance

- ✅ Soft deletes for data retention
- ✅ Foreign key constraints
- ✅ Indexed for performance
- ✅ Full-text search support
- ✅ Polymorphic relationships
- ✅ COA/DBM/BIR compliant structure
- ✅ Data Privacy Act ready

---

## Next Steps After Migration

### 1. Generate Models
```bash
# Example model generation
php artisan make:model Employee
php artisan make:model Payroll
php artisan make:model Loan
php artisan make:model ObligationRequest
php artisan make:model LedgerEntry
php artisan make:model ApprovalRequest
# ... etc
```

### 2. Create Seeders
```bash
php artisan make:seeder ChartOfAccountsSeeder
php artisan make:seeder BudgetCategorySeeder
php artisan make:seeder LoanTypeSeeder
php artisan make:seeder DeductionTypeSeeder
php artisan make:seeder BenefitTypeSeeder
php artisan make:seeder ApprovalWorkflowSeeder
```

### 3. Create Observers (for Auto-Audit)
```bash
php artisan make:observer PayrollObserver --model=Payroll
php artisan make:observer LoanObserver --model=Loan
php artisan make:observer LedgerEntryObserver --model=LedgerEntry
# Observers will auto-generate audit logs
```

### 4. Create Controllers & Routes
```bash
php artisan make:controller EmployeeController --resource
php artisan make:controller PayrollController --resource
php artisan make:controller LoanController --resource
php artisan make:controller ORSController --resource
# ... etc
```

### 5. Implement Services
Create service classes for business logic:
- `App\Services\PayrollService`
- `App\Services\LoanService`
- `App\Services\ORSService`
- `App\Services\LedgerService`
- `App\Services\ApprovalService`
- `App\Services\AuditService`

---

## Testing

### Run Tests After Setup
```bash
# Create test database
CREATE DATABASE ecarding_test;

# Update phpunit.xml with test DB
# Run tests
php artisan test
```

### Create Feature Tests
```bash
php artisan make:test PayrollTest
php artisan make:test LoanTest
php artisan make:test ORSTest
php artisan make:test ApprovalWorkflowTest
```

---

## Performance Optimization

### After Initial Setup:

1. **Add Indexes** (already included in migrations)
2. **Configure Query Cache**
3. **Setup Redis** for session/cache
4. **Enable MySQL Query Cache**
5. **Consider Partitioning** for audit_logs table

### Partition Example for Audit Logs:
```sql
ALTER TABLE audit_logs
PARTITION BY RANGE (YEAR(created_at)) (
    PARTITION p2026 VALUES LESS THAN (2027),
    PARTITION p2027 VALUES LESS THAN (2028),
    PARTITION p2028 VALUES LESS THAN (2029),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);
```

---

## Documentation

- 📄 **Full Schema Documentation**: `database/SCHEMA_DOCUMENTATION.md`
- 📄 **Quick Reference SQL**: `database/schema_reference.sql`
- 📄 **This Guide**: `database/QUICK_START.md`

---

## Support & Maintenance

### Regular Tasks:
1. **Daily**: Monitor audit logs for anomalies
2. **Weekly**: Review approval SLA compliance
3. **Monthly**: Archive old audit logs
4. **Quarterly**: Review and optimize indexes
5. **Yearly**: Budget year rollover

### Backup Strategy:
- Daily incremental backups
- Weekly full backups
- Keep audit logs for minimum 7 years
- Test restore procedures quarterly

---

**System Ready!** 🚀

The E-Carding schema is now complete and ready for application development.

---

**Created**: March 19, 2026
**Database**: MySQL 8.0+
**Framework**: Laravel 11.x
**PHP**: 8.2+
