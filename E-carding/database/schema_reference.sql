-- E-CARDING SCHEMA QUICK REFERENCE
-- Run this after migrations to see table structures

-- HUMAN RESOURCES
DESCRIBE departments;
DESCRIBE positions;
DESCRIBE employees;

-- PAYROLL
DESCRIBE payroll_periods;
DESCRIBE payrolls;
DESCRIBE payroll_deductions;
DESCRIBE payroll_benefits;
DESCRIBE deduction_types;
DESCRIBE benefit_types;

-- LOANS
DESCRIBE loan_types;
DESCRIBE loans;
DESCRIBE loan_payments;
DESCRIBE loan_restructures;

-- ORS (OBLIGATION REQUEST STATUS)
DESCRIBE budget_years;
DESCRIBE budget_categories;
DESCRIBE budget_allocations;
DESCRIBE obligation_requests;
DESCRIBE obligation_items;
DESCRIBE disbursement_vouchers;

-- GENERAL LEDGER
DESCRIBE chart_of_accounts;
DESCRIBE ledger_entries;
DESCRIBE ledger_lines;
DESCRIBE account_balances;
DESCRIBE bank_accounts;
DESCRIBE bank_transactions;

-- APPROVAL WORKFLOW
DESCRIBE approval_workflows;
DESCRIBE approval_levels;
DESCRIBE approval_requests;
DESCRIBE approval_actions;
DESCRIBE approval_notifications;
DESCRIBE approval_delegates;
DESCRIBE approval_templates;

-- AUDIT SYSTEM
DESCRIBE audit_logs;
DESCRIBE financial_audit_logs;
DESCRIBE data_access_logs;
DESCRIBE system_event_logs;
DESCRIBE audit_log_summaries;

-- QUICK TABLE COUNT
SELECT
    'departments' as table_name, COUNT(*) as rows FROM departments
UNION ALL SELECT 'employees', COUNT(*) FROM employees
UNION ALL SELECT 'payrolls', COUNT(*) FROM payrolls
UNION ALL SELECT 'loans', COUNT(*) FROM loans
UNION ALL SELECT 'obligation_requests', COUNT(*) FROM obligation_requests
UNION ALL SELECT 'ledger_entries', COUNT(*) FROM ledger_entries
UNION ALL SELECT 'approval_requests', COUNT(*) FROM approval_requests
UNION ALL SELECT 'audit_logs', COUNT(*) FROM audit_logs;
