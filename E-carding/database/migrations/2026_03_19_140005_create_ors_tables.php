<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('budget_years', function (Blueprint $table) {
            $table->id();
            $table->year('fiscal_year')->unique();
            $table->date('start_date');
            $table->date('end_date');
            $table->enum('status', ['draft', 'active', 'closed'])->default('draft');
            $table->decimal('total_budget', 15, 2)->default(0);
            $table->decimal('allocated_amount', 15, 2)->default(0);
            $table->decimal('obligated_amount', 15, 2)->default(0);
            $table->decimal('disbursed_amount', 15, 2)->default(0);
            $table->decimal('available_balance', 15, 2)->default(0);
            $table->timestamps();
        });

        Schema::create('budget_categories', function (Blueprint $table) {
            $table->id();
            $table->string('code', 50)->unique();
            $table->string('name');
            $table->text('description')->nullable();
            $table->foreignId('parent_category_id')->nullable()->constrained('budget_categories')->onDelete('set null');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['code', 'is_active']);
        });

        Schema::create('budget_allocations', function (Blueprint $table) {
            $table->id();
            $table->string('allocation_code', 50)->unique();
            $table->foreignId('budget_year_id')->constrained()->onDelete('restrict');
            $table->foreignId('department_id')->constrained()->onDelete('restrict');
            $table->foreignId('budget_category_id')->constrained()->onDelete('restrict');

            $table->decimal('allocated_amount', 15, 2);
            $table->decimal('obligated_amount', 15, 2)->default(0);
            $table->decimal('disbursed_amount', 15, 2)->default(0);
            $table->decimal('available_balance', 15, 2);

            $table->enum('status', ['active', 'exhausted', 'cancelled'])->default('active');
            $table->text('remarks')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['department_id', 'budget_year_id', 'status']);
            $table->index(['budget_category_id', 'status']);
        });

        Schema::create('obligation_requests', function (Blueprint $table) {
            $table->id();
            $table->string('ors_number', 50)->unique();
            $table->foreignId('budget_allocation_id')->constrained()->onDelete('restrict');
            $table->foreignId('department_id')->constrained()->onDelete('restrict');
            $table->foreignId('requested_by')->constrained('users')->onDelete('restrict');

            // Request Details
            $table->string('payee_name');
            $table->text('payee_address')->nullable();
            $table->string('payee_tin', 50)->nullable();
            $table->text('purpose');
            $table->date('request_date');
            $table->date('needed_date')->nullable();

            // Amounts
            $table->decimal('amount', 15, 2);
            $table->decimal('tax_amount', 15, 2)->default(0);
            $table->decimal('net_amount', 15, 2);

            // Supporting Documents
            $table->json('attachments')->nullable();
            $table->string('reference_number', 100)->nullable();

            // Status & Workflow
            $table->enum('status', ['draft', 'pending', 'approved', 'obligated', 'partially_paid', 'fully_paid', 'cancelled', 'rejected'])->default('draft');
            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamp('obligated_at')->nullable();
            $table->foreignId('obligated_by')->nullable()->constrained('users')->onDelete('set null');

            $table->text('remarks')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['department_id', 'status']);
            $table->index(['requested_by', 'status']);
            $table->index(['request_date', 'status']);
            $table->fullText(['ors_number', 'payee_name', 'purpose']);
        });

        Schema::create('obligation_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('obligation_request_id')->constrained()->onDelete('cascade');
            $table->string('item_code', 50)->nullable();
            $table->text('description');
            $table->string('unit_of_measure', 50)->nullable();
            $table->integer('quantity')->default(1);
            $table->decimal('unit_price', 15, 2);
            $table->decimal('total_amount', 15, 2);
            $table->timestamps();

            $table->index('obligation_request_id');
        });

        Schema::create('disbursement_vouchers', function (Blueprint $table) {
            $table->id();
            $table->string('dv_number', 50)->unique();
            $table->foreignId('obligation_request_id')->constrained()->onDelete('restrict');
            $table->foreignId('payroll_period_id')->nullable()->constrained()->onDelete('set null');

            $table->date('voucher_date');
            $table->decimal('voucher_amount', 15, 2);
            $table->enum('payment_mode', ['check', 'cash', 'bank_transfer', 'e-payment'])->default('check');
            $table->string('check_number', 50)->nullable();
            $table->date('check_date')->nullable();
            $table->string('bank_name')->nullable();
            $table->string('account_number')->nullable();

            $table->enum('status', ['draft', 'approved', 'paid', 'cancelled'])->default('draft');
            $table->timestamp('approved_at')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamp('paid_at')->nullable();
            $table->foreignId('paid_by')->nullable()->constrained('users')->onDelete('set null');

            $table->text('remarks')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['obligation_request_id', 'status']);
            $table->index(['voucher_date', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('disbursement_vouchers');
        Schema::dropIfExists('obligation_items');
        Schema::dropIfExists('obligation_requests');
        Schema::dropIfExists('budget_allocations');
        Schema::dropIfExists('budget_categories');
        Schema::dropIfExists('budget_years');
    }
};
