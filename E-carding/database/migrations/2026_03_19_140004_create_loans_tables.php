<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('loan_types', function (Blueprint $table) {
            $table->id();
            $table->string('code', 50)->unique();
            $table->string('name');
            $table->text('description')->nullable();
            $table->decimal('min_amount', 15, 2)->default(0);
            $table->decimal('max_amount', 15, 2)->nullable();
            $table->decimal('interest_rate', 5, 2)->default(0);
            $table->integer('min_term_months')->default(1);
            $table->integer('max_term_months')->default(60);
            $table->boolean('require_guarantor')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('loans', function (Blueprint $table) {
            $table->id();
            $table->string('loan_number', 50)->unique();
            $table->foreignId('employee_id')->constrained()->onDelete('restrict');
            $table->foreignId('loan_type_id')->constrained()->onDelete('restrict');

            // Loan Details
            $table->decimal('principal_amount', 15, 2);
            $table->decimal('interest_rate', 5, 2)->default(0);
            $table->integer('term_months');
            $table->decimal('monthly_amortization', 15, 2);
            $table->date('loan_date');
            $table->date('first_payment_date');
            $table->date('maturity_date');

            // Guarantors
            $table->foreignId('guarantor_1_id')->nullable()->constrained('employees')->onDelete('set null');
            $table->foreignId('guarantor_2_id')->nullable()->constrained('employees')->onDelete('set null');

            // Balances
            $table->decimal('total_amount', 15, 2); // Principal + Interest
            $table->decimal('amount_paid', 15, 2)->default(0);
            $table->decimal('balance', 15, 2);
            $table->integer('payments_made')->default(0);
            $table->integer('remaining_payments');

            // Status
            $table->enum('status', ['pending', 'approved', 'active', 'fully_paid', 'defaulted', 'cancelled'])->default('pending');
            $table->timestamp('approved_at')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamp('fully_paid_at')->nullable();

            $table->text('purpose')->nullable();
            $table->text('remarks')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['employee_id', 'status']);
            $table->index(['loan_type_id', 'status']);
            $table->index(['loan_date', 'status']);
        });

        Schema::create('loan_payments', function (Blueprint $table) {
            $table->id();
            $table->string('payment_number', 50)->unique();
            $table->foreignId('loan_id')->constrained()->onDelete('restrict');
            $table->foreignId('payroll_id')->nullable()->constrained('payrolls')->onDelete('set null');

            // Payment Details
            $table->integer('payment_sequence'); // 1st, 2nd, 3rd payment
            $table->date('payment_date');
            $table->date('due_date');
            $table->decimal('amount_due', 15, 2);
            $table->decimal('amount_paid', 15, 2);
            $table->decimal('principal_paid', 15, 2);
            $table->decimal('interest_paid', 15, 2);
            $table->decimal('penalty', 15, 2)->default(0);
            $table->decimal('balance_after_payment', 15, 2);

            // Status
            $table->enum('status', ['scheduled', 'paid', 'partial', 'overdue', 'waived'])->default('scheduled');
            $table->integer('days_overdue')->default(0);
            $table->enum('payment_method', ['payroll_deduction', 'cash', 'check', 'bank_transfer', 'other'])->default('payroll_deduction');
            $table->string('reference_number', 100)->nullable();

            $table->text('remarks')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['loan_id', 'payment_sequence']);
            $table->index(['status', 'due_date']);
            $table->index('payment_date');
        });

        Schema::create('loan_restructures', function (Blueprint $table) {
            $table->id();
            $table->foreignId('loan_id')->constrained()->onDelete('restrict');
            $table->foreignId('requested_by')->constrained('users')->onDelete('restrict');
            $table->foreignId('approved_by')->nullable()->constrained('users')->onDelete('set null');

            // Old Terms
            $table->decimal('old_principal_amount', 15, 2);
            $table->decimal('old_interest_rate', 5, 2);
            $table->integer('old_term_months');
            $table->decimal('old_monthly_amortization', 15, 2);
            $table->decimal('old_balance', 15, 2);

            // New Terms
            $table->decimal('new_principal_amount', 15, 2);
            $table->decimal('new_interest_rate', 5, 2);
            $table->integer('new_term_months');
            $table->decimal('new_monthly_amortization', 15, 2);
            $table->date('new_first_payment_date');
            $table->date('new_maturity_date');

            $table->text('reason')->nullable();
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->timestamp('approved_at')->nullable();
            $table->text('remarks')->nullable();
            $table->timestamps();

            $table->index(['loan_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('loan_restructures');
        Schema::dropIfExists('loan_payments');
        Schema::dropIfExists('loans');
        Schema::dropIfExists('loan_types');
    }
};
