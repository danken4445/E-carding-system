<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chart_of_accounts', function (Blueprint $table) {
            $table->id();
            $table->string('account_code', 50)->unique();
            $table->string('account_name');
            $table->text('description')->nullable();
            $table->enum('account_type', ['asset', 'liability', 'equity', 'revenue', 'expense'])->index();
            $table->enum('account_category', ['current', 'non_current', 'operating', 'non_operating', 'capital'])->nullable();
            $table->foreignId('parent_account_id')->nullable()->constrained('chart_of_accounts')->onDelete('set null');
            $table->boolean('is_active')->default(true);
            $table->boolean('is_system_account')->default(false);
            $table->integer('level')->default(1);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['account_type', 'is_active']);
            $table->index(['account_code', 'is_active']);
        });

        Schema::create('ledger_entries', function (Blueprint $table) {
            $table->id();
            $table->string('entry_number', 50)->unique();
            $table->date('entry_date');
            $table->date('posting_date');
            $table->enum('entry_type', ['standard', 'adjusting', 'closing', 'reversing', 'correcting'])->default('standard');

            // Reference to source documents
            $table->string('source_type', 100)->nullable(); // payroll, ors, loan, etc.
            $table->unsignedBigInteger('source_id')->nullable();
            $table->string('source_reference', 100)->nullable();

            $table->text('description');
            $table->decimal('total_debit', 15, 2)->default(0);
            $table->decimal('total_credit', 15, 2)->default(0);

            $table->enum('status', ['draft', 'posted', 'approved', 'reversed', 'cancelled'])->default('draft');
            $table->timestamp('posted_at')->nullable();
            $table->foreignId('posted_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamp('approved_at')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->onDelete('set null');

            $table->foreignId('reversed_entry_id')->nullable()->constrained('ledger_entries')->onDelete('set null');
            $table->timestamp('reversed_at')->nullable();

            $table->text('remarks')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['entry_date', 'status']);
            $table->index(['posting_date', 'status']);
            $table->index(['source_type', 'source_id']);
            $table->index(['entry_type', 'status']);
        });

        Schema::create('ledger_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ledger_entry_id')->constrained()->onDelete('cascade');
            $table->foreignId('account_id')->constrained('chart_of_accounts')->onDelete('restrict');
            $table->foreignId('department_id')->nullable()->constrained()->onDelete('set null');

            $table->integer('line_number');
            $table->text('description')->nullable();
            $table->decimal('debit_amount', 15, 2)->default(0);
            $table->decimal('credit_amount', 15, 2)->default(0);
            $table->decimal('balance', 15, 2)->default(0);

            // Additional dimensions for analysis
            $table->string('cost_center', 50)->nullable();
            $table->string('project_code', 50)->nullable();
            $table->string('program_code', 50)->nullable();

            $table->timestamps();

            $table->index(['ledger_entry_id', 'line_number']);
            $table->index(['account_id', 'created_at']);
            $table->index('department_id');
        });

        Schema::create('account_balances', function (Blueprint $table) {
            $table->id();
            $table->foreignId('account_id')->constrained('chart_of_accounts')->onDelete('cascade');
            $table->foreignId('budget_year_id')->constrained()->onDelete('cascade');
            $table->integer('period_month'); // 1-12

            $table->decimal('opening_balance', 15, 2)->default(0);
            $table->decimal('debit_total', 15, 2)->default(0);
            $table->decimal('credit_total', 15, 2)->default(0);
            $table->decimal('closing_balance', 15, 2)->default(0);

            $table->timestamp('last_updated_at')->nullable();
            $table->timestamps();

            $table->unique(['account_id', 'budget_year_id', 'period_month']);
            $table->index(['budget_year_id', 'period_month']);
        });

        Schema::create('bank_accounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('account_id')->constrained('chart_of_accounts')->onDelete('restrict');
            $table->string('bank_name');
            $table->string('account_number', 50)->unique();
            $table->string('account_name');
            $table->enum('account_type', ['checking', 'savings', 'payroll', 'trust'])->default('checking');
            $table->string('branch')->nullable();
            $table->string('swift_code')->nullable();
            $table->decimal('current_balance', 15, 2)->default(0);
            $table->boolean('is_active')->default(true);
            $table->text('remarks')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['is_active', 'account_type']);
        });

        Schema::create('bank_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('bank_account_id')->constrained()->onDelete('restrict');
            $table->foreignId('ledger_entry_id')->nullable()->constrained()->onDelete('set null');

            $table->date('transaction_date');
            $table->string('transaction_number', 50);
            $table->enum('transaction_type', ['deposit', 'withdrawal', 'transfer', 'fee', 'interest', 'adjustment'])->index();
            $table->text('description');

            $table->decimal('debit_amount', 15, 2)->default(0);
            $table->decimal('credit_amount', 15, 2)->default(0);
            $table->decimal('balance_after', 15, 2);

            $table->string('check_number', 50)->nullable();
            $table->string('reference_number', 100)->nullable();

            $table->enum('status', ['pending', 'cleared', 'cancelled', 'reconciled'])->default('pending');
            $table->timestamp('reconciled_at')->nullable();
            $table->foreignId('reconciled_by')->nullable()->constrained('users')->onDelete('set null');

            $table->text('remarks')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['bank_account_id', 'transaction_date']);
            $table->index(['transaction_type', 'status']);
            $table->index('transaction_date');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bank_transactions');
        Schema::dropIfExists('bank_accounts');
        Schema::dropIfExists('account_balances');
        Schema::dropIfExists('ledger_lines');
        Schema::dropIfExists('ledger_entries');
        Schema::dropIfExists('chart_of_accounts');
    }
};
