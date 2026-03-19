<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payroll_periods', function (Blueprint $table) {
            $table->id();
            $table->string('period_code', 50)->unique();
            $table->enum('period_type', ['monthly', 'semi_monthly', 'bi_weekly', 'weekly'])->default('semi_monthly');
            $table->date('start_date');
            $table->date('end_date');
            $table->date('payment_date');
            $table->enum('status', ['draft', 'processing', 'approved', 'paid', 'cancelled'])->default('draft');
            $table->text('remarks')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['status', 'payment_date']);
            $table->index(['start_date', 'end_date']);
        });

        Schema::create('payrolls', function (Blueprint $table) {
            $table->id();
            $table->string('payroll_number', 50)->unique();
            $table->foreignId('employee_id')->constrained()->onDelete('restrict');
            $table->foreignId('payroll_period_id')->constrained()->onDelete('restrict');

            // Earnings
            $table->decimal('base_pay', 15, 2)->default(0);
            $table->decimal('overtime_pay', 15, 2)->default(0);
            $table->decimal('night_differential', 15, 2)->default(0);
            $table->decimal('hazard_pay', 15, 2)->default(0);
            $table->decimal('allowances', 15, 2)->default(0);
            $table->decimal('bonuses', 15, 2)->default(0);
            $table->decimal('other_earnings', 15, 2)->default(0);
            $table->decimal('gross_pay', 15, 2)->default(0);

            // Deductions
            $table->decimal('sss_contribution', 15, 2)->default(0);
            $table->decimal('philhealth_contribution', 15, 2)->default(0);
            $table->decimal('pagibig_contribution', 15, 2)->default(0);
            $table->decimal('gsis_contribution', 15, 2)->default(0);
            $table->decimal('withholding_tax', 15, 2)->default(0);
            $table->decimal('loan_deductions', 15, 2)->default(0);
            $table->decimal('other_deductions', 15, 2)->default(0);
            $table->decimal('total_deductions', 15, 2)->default(0);

            // Net Pay
            $table->decimal('net_pay', 15, 2)->default(0);

            // Work Details
            $table->decimal('days_worked', 8, 2)->default(0);
            $table->decimal('hours_worked', 8, 2)->default(0);
            $table->decimal('overtime_hours', 8, 2)->default(0);

            $table->enum('status', ['draft', 'approved', 'paid', 'cancelled'])->default('draft');
            $table->timestamp('approved_at')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamp('paid_at')->nullable();
            $table->text('remarks')->nullable();

            $table->timestamps();
            $table->softDeletes();

            $table->index(['employee_id', 'payroll_period_id']);
            $table->index(['status', 'paid_at']);
        });

        Schema::create('payroll_deductions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payroll_id')->constrained()->onDelete('cascade');
            $table->string('deduction_type', 100);
            $table->string('deduction_code', 50);
            $table->text('description')->nullable();
            $table->decimal('amount', 15, 2);
            $table->text('remarks')->nullable();
            $table->timestamps();

            $table->index(['payroll_id', 'deduction_type']);
        });

        Schema::create('payroll_benefits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payroll_id')->constrained()->onDelete('cascade');
            $table->string('benefit_type', 100);
            $table->string('benefit_code', 50);
            $table->text('description')->nullable();
            $table->decimal('amount', 15, 2);
            $table->boolean('is_taxable')->default(false);
            $table->text('remarks')->nullable();
            $table->timestamps();

            $table->index(['payroll_id', 'benefit_type']);
        });

        Schema::create('deduction_types', function (Blueprint $table) {
            $table->id();
            $table->string('code', 50)->unique();
            $table->string('name');
            $table->text('description')->nullable();
            $table->enum('frequency', ['one_time', 'recurring', 'per_payroll'])->default('recurring');
            $table->decimal('default_amount', 15, 2)->nullable();
            $table->decimal('max_amount', 15, 2)->nullable();
            $table->boolean('is_mandatory')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('benefit_types', function (Blueprint $table) {
            $table->id();
            $table->string('code', 50)->unique();
            $table->string('name');
            $table->text('description')->nullable();
            $table->enum('frequency', ['one_time', 'recurring', 'per_payroll'])->default('recurring');
            $table->decimal('default_amount', 15, 2)->nullable();
            $table->boolean('is_taxable')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payroll_benefits');
        Schema::dropIfExists('payroll_deductions');
        Schema::dropIfExists('payrolls');
        Schema::dropIfExists('payroll_periods');
        Schema::dropIfExists('benefit_types');
        Schema::dropIfExists('deduction_types');
    }
};
