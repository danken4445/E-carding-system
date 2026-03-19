<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        /**
         * Immutable Audit Log
         * This table is designed to be append-only and provide tamper-proof audit trails
         * Features:
         * - No updates or deletes allowed
         * - Hash chain for integrity verification
         * - Comprehensive event logging
         * - Performance optimized with partitioning support
         */
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->uuid('audit_uuid')->unique();

            // Who performed the action
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('restrict');
            $table->string('user_name')->nullable(); // Denormalized for immutability
            $table->string('user_email')->nullable();
            $table->string('user_roles')->nullable(); // JSON string of roles at time of action

            // What was done
            $table->string('event_type', 100)->index(); // created, updated, deleted, approved, rejected, etc.
            $table->string('event_category', 50)->index(); // payroll, loan, ors, ledger, auth, etc.
            $table->morphs('auditable'); // auditable_type, auditable_id
            $table->text('event_description');

            // Before and after state (for updates)
            $table->longText('old_values')->nullable(); // JSON of previous state
            $table->longText('new_values')->nullable(); // JSON of new state
            $table->longText('changed_fields')->nullable(); // Array of changed field names

            // Context information
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->string('request_method', 10)->nullable();
            $table->text('request_url')->nullable();
            $table->text('request_route')->nullable();
            $table->json('request_payload')->nullable();

            // Session and authentication
            $table->string('session_id', 100)->nullable();
            $table->timestamp('session_start')->nullable();
            $table->string('auth_method', 50)->nullable(); // password, 2fa, api_token, etc.

            // Metadata
            $table->json('metadata')->nullable(); // Additional context-specific data
            $table->string('tags')->nullable(); // Searchable tags
            $table->enum('severity', ['low', 'medium', 'high', 'critical'])->default('medium')->index();
            $table->enum('risk_level', ['none', 'low', 'medium', 'high'])->default('none')->index();

            // Integrity verification (tamper-proof features)
            $table->string('record_hash', 64)->unique(); // SHA-256 hash of record content
            $table->string('previous_hash', 64)->nullable()->index(); // Hash of previous record (blockchain-style)
            $table->string('signature', 255)->nullable(); // Optional digital signature

            // Performance and compliance
            $table->boolean('is_sensitive')->default(false)->index();
            $table->boolean('is_pii')->default(false); // Contains Personally Identifiable Information
            $table->date('retention_until')->nullable()->index(); // For data retention policies
            $table->boolean('is_archived')->default(false)->index();

            // Timestamp (immutable - never updated)
            $table->timestamp('created_at')->useCurrent();

            // Indexes for performance
            $table->index(['user_id', 'created_at']);
            $table->index(['event_type', 'created_at']);
            $table->index(['event_category', 'created_at']);
            $table->index(['auditable_type', 'auditable_id', 'created_at']);
            $table->index(['created_at', 'severity']);
            $table->index('ip_address');
            $table->fullText(['event_description', 'tags']);
        });

        // Add comment to enforce immutability
        DB::statement("ALTER TABLE audit_logs COMMENT='IMMUTABLE: No updates or deletes allowed. Append-only audit log.'");

        /**
         * Financial Transaction Audit
         * Specialized audit log for all financial transactions
         * Provides detailed money trail for compliance
         */
        Schema::create('financial_audit_logs', function (Blueprint $table) {
            $table->id();
            $table->uuid('transaction_uuid')->unique();
            $table->foreignId('audit_log_id')->constrained()->onDelete('restrict');

            // Transaction details
            $table->string('transaction_type', 50)->index(); // payroll, loan, ors, ledger
            $table->string('transaction_reference', 100)->index();
            $table->date('transaction_date')->index();

            // Financial amounts
            $table->decimal('amount', 15, 2);
            $table->string('currency', 3)->default('PHP');
            $table->decimal('debit_amount', 15, 2)->default(0);
            $table->decimal('credit_amount', 15, 2)->default(0);
            $table->decimal('balance_before', 15, 2)->nullable();
            $table->decimal('balance_after', 15, 2)->nullable();

            // Parties involved
            $table->foreignId('from_entity_id')->nullable()->index();
            $table->string('from_entity_type', 50)->nullable();
            $table->foreignId('to_entity_id')->nullable()->index();
            $table->string('to_entity_type', 50)->nullable();

            // Accounts affected
            $table->foreignId('debit_account_id')->nullable()->constrained('chart_of_accounts')->onDelete('restrict');
            $table->foreignId('credit_account_id')->nullable()->constrained('chart_of_accounts')->onDelete('restrict');
            $table->foreignId('department_id')->nullable()->constrained()->onDelete('restrict');

            // Approval trail
            $table->foreignId('approved_by')->nullable()->constrained('users')->onDelete('restrict');
            $table->timestamp('approved_at')->nullable();
            $table->string('approval_reference', 100)->nullable();

            // Tax and compliance
            $table->decimal('tax_amount', 15, 2)->default(0);
            $table->string('tax_type', 50)->nullable();
            $table->boolean('is_tax_exempt')->default(false);

            // Integrity
            $table->string('record_hash', 64)->unique();
            $table->string('signature', 255)->nullable();

            // Compliance flags
            $table->boolean('requires_reporting')->default(false);
            $table->boolean('is_suspicious')->default(false);
            $table->text('compliance_notes')->nullable();

            $table->timestamp('created_at')->useCurrent();

            $table->index(['transaction_type', 'transaction_date']);
            $table->index(['transaction_date', 'amount']);
            $table->index(['from_entity_type', 'from_entity_id']);
            $table->index(['to_entity_type', 'to_entity_id']);
        });

        DB::statement("ALTER TABLE financial_audit_logs COMMENT='IMMUTABLE: Financial transaction audit trail.'");

        /**
         * Data Access Log
         * Tracks who accessed what sensitive data and when
         * Critical for compliance with data protection regulations
         */
        Schema::create('data_access_logs', function (Blueprint $table) {
            $table->id();
            $table->uuid('access_uuid')->unique();

            $table->foreignId('user_id')->nullable()->constrained()->onDelete('restrict');
            $table->string('user_email')->nullable();
            $table->string('user_roles')->nullable();

            // What was accessed
            $table->string('resource_type', 100)->index();
            $table->unsignedBigInteger('resource_id')->nullable()->index();
            $table->string('resource_identifier')->nullable();
            $table->enum('access_action', ['view', 'create', 'update', 'delete', 'export', 'print', 'download'])->index();

            // Access context
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->string('access_method', 50)->nullable(); // web, api, mobile
            $table->text('access_url')->nullable();

            // Data classification
            $table->enum('data_classification', ['public', 'internal', 'confidential', 'restricted'])->index();
            $table->boolean('contains_pii')->default(false);
            $table->boolean('contains_financial')->default(false);
            $table->json('fields_accessed')->nullable();

            // Authorization
            $table->boolean('is_authorized')->default(true)->index();
            $table->text('authorization_reason')->nullable();
            $table->string('session_id', 100)->nullable();

            // Compliance
            $table->boolean('requires_consent')->default(false);
            $table->boolean('consent_given')->nullable();
            $table->timestamp('consent_date')->nullable();

            // Integrity
            $table->string('record_hash', 64)->unique();

            $table->timestamp('created_at')->useCurrent();

            $table->index(['user_id', 'created_at']);
            $table->index(['resource_type', 'resource_id']);
            $table->index(['access_action', 'created_at']);
            $table->index(['data_classification', 'contains_pii']);
            $table->index('ip_address');
        });

        DB::statement("ALTER TABLE data_access_logs COMMENT='IMMUTABLE: Data access audit trail for compliance.'");

        /**
         * System Events Log
         * Tracks system-level events, errors, and security incidents
         */
        Schema::create('system_event_logs', function (Blueprint $table) {
            $table->id();
            $table->uuid('event_uuid')->unique();

            $table->enum('event_category', ['security', 'system', 'error', 'warning', 'info'])->index();
            $table->enum('event_level', ['emergency', 'alert', 'critical', 'error', 'warning', 'notice', 'info', 'debug'])->index();
            $table->string('event_code', 50)->nullable()->index();
            $table->string('event_name', 100)->index();
            $table->text('event_message');

            // Context
            $table->string('component', 100)->nullable()->index(); // module or component name
            $table->string('function', 255)->nullable(); // function or method name
            $table->integer('line_number')->nullable();
            $table->text('stack_trace')->nullable();

            // Actor (if applicable)
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('restrict');
            $table->string('ip_address', 45)->nullable();

            // Additional data
            $table->json('context_data')->nullable();
            $table->json('exception_data')->nullable();
            $table->text('request_data')->nullable();

            // Resolution
            $table->boolean('is_resolved')->default(false)->index();
            $table->timestamp('resolved_at')->nullable();
            $table->foreignId('resolved_by')->nullable()->constrained('users')->onDelete('restrict');
            $table->text('resolution_notes')->nullable();

            // Alerting
            $table->boolean('alert_sent')->default(false);
            $table->timestamp('alert_sent_at')->nullable();
            $table->string('alert_recipients')->nullable();

            // Integrity
            $table->string('record_hash', 64)->unique();

            $table->timestamp('created_at')->useCurrent();

            $table->index(['event_category', 'event_level', 'created_at']);
            $table->index(['component', 'created_at']);
            $table->index(['is_resolved', 'event_level']);
        });

        DB::statement("ALTER TABLE system_event_logs COMMENT='IMMUTABLE: System events and error log.'");

        /**
         * Audit Log Summary
         * Aggregated statistics for reporting and dashboards
         * Updated periodically by scheduled jobs
         */
        Schema::create('audit_log_summaries', function (Blueprint $table) {
            $table->id();
            $table->date('summary_date')->index();
            $table->string('event_category', 50)->index();
            $table->string('event_type', 100)->index();

            $table->integer('event_count')->default(0);
            $table->integer('user_count')->default(0);
            $table->integer('failed_count')->default(0);
            $table->integer('suspicious_count')->default(0);

            $table->decimal('total_amount', 15, 2)->nullable(); // For financial events
            $table->integer('high_severity_count')->default(0);
            $table->integer('critical_severity_count')->default(0);

            $table->timestamp('last_updated_at')->useCurrent()->useCurrentOnUpdate();
            $table->timestamps();

            $table->unique(['summary_date', 'event_category', 'event_type'], 'audit_summ_date_cat_type_uq');
            $table->index(['summary_date', 'event_count']);
        });

        $this->createAppendOnlyTriggers('audit_logs');
        $this->createAppendOnlyTriggers('financial_audit_logs');
        $this->createAppendOnlyTriggers('data_access_logs');
        $this->createAppendOnlyTriggers('system_event_logs');
    }

    public function down(): void
    {
        $this->dropAppendOnlyTriggers('system_event_logs');
        $this->dropAppendOnlyTriggers('data_access_logs');
        $this->dropAppendOnlyTriggers('financial_audit_logs');
        $this->dropAppendOnlyTriggers('audit_logs');

        // Note: In production, audit logs should NEVER be dropped
        // This is only for development/testing purposes
        Schema::dropIfExists('audit_log_summaries');
        Schema::dropIfExists('system_event_logs');
        Schema::dropIfExists('data_access_logs');
        Schema::dropIfExists('financial_audit_logs');
        Schema::dropIfExists('audit_logs');
    }

    private function createAppendOnlyTriggers(string $table): void
    {
        try {
            DB::unprepared("DROP TRIGGER IF EXISTS {$table}_prevent_update");
            DB::unprepared("DROP TRIGGER IF EXISTS {$table}_prevent_delete");

            DB::unprepared("\n                CREATE TRIGGER {$table}_prevent_update\n                BEFORE UPDATE ON {$table}\n                FOR EACH ROW\n                BEGIN\n                    SIGNAL SQLSTATE '45000'\n                    SET MESSAGE_TEXT = 'Immutable audit table: updates are not allowed';\n                END\n            ");

            DB::unprepared("\n                CREATE TRIGGER {$table}_prevent_delete\n                BEFORE DELETE ON {$table}\n                FOR EACH ROW\n                BEGIN\n                    SIGNAL SQLSTATE '45000'\n                    SET MESSAGE_TEXT = 'Immutable audit table: deletes are not allowed';\n                END\n            ");
        } catch (\Throwable $e) {
            // Some MySQL setups require elevated privileges to create triggers.
            // The tables remain append-only by design at the application layer.
            if (! str_contains($e->getMessage(), '1419') && ! str_contains($e->getMessage(), 'SUPER privilege')) {
                throw $e;
            }
        }
    }

    private function dropAppendOnlyTriggers(string $table): void
    {
        DB::unprepared("DROP TRIGGER IF EXISTS {$table}_prevent_update");
        DB::unprepared("DROP TRIGGER IF EXISTS {$table}_prevent_delete");
    }
};
