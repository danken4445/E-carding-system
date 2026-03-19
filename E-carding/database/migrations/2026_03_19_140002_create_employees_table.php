<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('employees', function (Blueprint $table) {
            $table->id();
            $table->string('employee_number', 50)->unique();
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('set null');

            // Personal Information
            $table->string('first_name');
            $table->string('middle_name')->nullable();
            $table->string('last_name');
            $table->string('suffix', 10)->nullable();
            $table->date('birth_date')->nullable();
            $table->enum('gender', ['male', 'female', 'other'])->nullable();
            $table->enum('civil_status', ['single', 'married', 'widowed', 'separated', 'divorced'])->nullable();

            // Contact Information
            $table->string('email')->unique()->nullable();
            $table->string('phone', 20)->nullable();
            $table->text('address')->nullable();

            // Employment Information
            $table->foreignId('department_id')->constrained()->onDelete('restrict');
            $table->foreignId('position_id')->constrained()->onDelete('restrict');
            $table->enum('employment_status', ['regular', 'probationary', 'contractual', 'casual', 'job_order'])->default('regular');
            $table->enum('employment_type', ['permanent', 'temporary', 'part_time', 'job_order'])->default('permanent');
            $table->date('hire_date');
            $table->date('regularization_date')->nullable();
            $table->date('separation_date')->nullable();
            $table->string('separation_reason')->nullable();

            // Compensation
            $table->decimal('base_salary', 15, 2);
            $table->decimal('step_increment', 15, 2)->default(0);
            $table->decimal('current_salary', 15, 2);
            $table->string('salary_grade', 20)->nullable();

            // Government IDs
            $table->string('sss_number', 20)->nullable();
            $table->string('philhealth_number', 20)->nullable();
            $table->string('pagibig_number', 20)->nullable();
            $table->string('tin_number', 20)->nullable();
            $table->string('gsis_number', 20)->nullable();

            // Status
            $table->boolean('is_active')->default(true);
            $table->text('remarks')->nullable();

            $table->timestamps();
            $table->softDeletes();

            // Indexes
            $table->index(['department_id', 'is_active']);
            $table->index(['position_id', 'employment_status']);
            $table->index('hire_date');
            $table->fullText(['first_name', 'last_name', 'employee_number']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('employees');
    }
};
