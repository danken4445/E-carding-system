<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('approval_workflows', function (Blueprint $table) {
            $table->id();
            $table->string('workflow_code', 50)->unique();
            $table->string('workflow_name');
            $table->text('description')->nullable();
            $table->string('model_type'); // payroll, loan, ors, ledger_entry, etc.
            $table->integer('required_approvals')->default(1);
            $table->boolean('require_sequential')->default(true); // Sequential or parallel approval
            $table->boolean('allow_rejection')->default(true);
            $table->boolean('is_active')->default(true);
            $table->json('conditions')->nullable(); // Dynamic conditions for workflow triggering
            $table->timestamps();
            $table->softDeletes();

            $table->index(['model_type', 'is_active']);
        });

        Schema::create('approval_levels', function (Blueprint $table) {
            $table->id();
            $table->foreignId('workflow_id')->constrained('approval_workflows')->onDelete('cascade');
            $table->integer('level_order'); // 1, 2, 3, etc.
            $table->string('level_name');
            $table->text('description')->nullable();
            $table->enum('approver_type', ['user', 'role', 'position', 'department_head', 'specific_user'])->default('role');
            $table->string('approver_identifier')->nullable(); // role name, user_id, position_id, etc.
            $table->integer('required_approvers')->default(1); // Support multiple approvers at same level
            $table->boolean('can_delegate')->default(false);
            $table->integer('sla_hours')->nullable(); // Service Level Agreement in hours
            $table->json('conditions')->nullable(); // Conditions for requiring this level
            $table->timestamps();

            $table->index(['workflow_id', 'level_order']);
        });

        Schema::create('approval_requests', function (Blueprint $table) {
            $table->id();
            $table->string('request_number', 50)->unique();
            $table->foreignId('workflow_id')->constrained('approval_workflows')->onDelete('restrict');
            $table->foreignId('requested_by')->constrained('users')->onDelete('restrict');
            $table->foreignId('department_id')->nullable()->constrained()->onDelete('set null');

            // Polymorphic relationship to the entity being approved
            $table->morphs('approvable'); // approvable_type, approvable_id

            $table->integer('current_level')->default(1);
            $table->integer('total_levels');
            $table->integer('approvals_received')->default(0);
            $table->integer('approvals_required');

            $table->enum('status', ['pending', 'in_progress', 'approved', 'rejected', 'cancelled', 'expired'])->default('pending');
            $table->timestamp('submitted_at');
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('expires_at')->nullable();

            $table->text('request_summary')->nullable();
            $table->json('request_data')->nullable(); // Store snapshot of data at submission
            $table->decimal('amount', 15, 2)->nullable(); // For amount-based approvals
            $table->string('priority', 20)->default('normal');

            $table->text('remarks')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['status', 'current_level']);
            $table->index(['requested_by', 'status']);
            $table->index('submitted_at');
        });

        Schema::create('approval_actions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('approval_request_id')->constrained()->onDelete('cascade');
            $table->foreignId('approval_level_id')->constrained()->onDelete('restrict');
            $table->foreignId('user_id')->constrained()->onDelete('restrict');
            $table->foreignId('delegated_by')->nullable()->constrained('users')->onDelete('set null');

            $table->integer('level_order');
            $table->enum('action', ['approved', 'rejected', 'returned', 'delegated', 'cancelled'])->index();
            $table->timestamp('action_date');
            $table->text('comments')->nullable();
            $table->json('action_data')->nullable(); // Additional action-specific data

            // SLA tracking
            $table->integer('response_time_hours')->nullable();
            $table->boolean('is_within_sla')->nullable();

            // Digital signature support
            $table->string('signature_hash')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();

            $table->timestamps();

            $table->index(['approval_request_id', 'level_order']);
            $table->index(['user_id', 'action']);
            $table->index('action_date');
        });

        Schema::create('approval_notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('approval_request_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('approval_level_id')->nullable()->constrained()->onDelete('set null');

            $table->enum('notification_type', ['pending_approval', 'approved', 'rejected', 'reminder', 'escalation', 'delegated'])->index();
            $table->text('notification_message');
            $table->timestamp('sent_at')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->boolean('is_read')->default(false);

            $table->timestamps();

            $table->index(['user_id', 'is_read']);
            $table->index(['approval_request_id', 'notification_type'], 'appr_notif_req_type_idx');
        });

        Schema::create('approval_delegates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delegator_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('delegate_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('workflow_id')->nullable()->constrained('approval_workflows')->onDelete('cascade');

            $table->date('start_date');
            $table->date('end_date');
            $table->text('reason')->nullable();
            $table->boolean('is_active')->default(true);

            $table->timestamps();

            $table->index(['delegator_id', 'is_active']);
            $table->index(['delegate_id', 'is_active']);
            $table->index(['start_date', 'end_date']);
        });

        Schema::create('approval_templates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('workflow_id')->constrained('approval_workflows')->onDelete('cascade');
            $table->string('template_name');
            $table->text('description')->nullable();
            $table->enum('template_type', ['email', 'sms', 'notification', 'document'])->index();
            $table->text('subject')->nullable();
            $table->longText('body');
            $table->json('variables')->nullable(); // List of available template variables
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['workflow_id', 'template_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('approval_templates');
        Schema::dropIfExists('approval_delegates');
        Schema::dropIfExists('approval_notifications');
        Schema::dropIfExists('approval_actions');
        Schema::dropIfExists('approval_requests');
        Schema::dropIfExists('approval_levels');
        Schema::dropIfExists('approval_workflows');
    }
};
