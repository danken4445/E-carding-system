<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('departments', function (Blueprint $table) {
            $table->id();
            $table->string('code', 50)->unique();
            $table->string('name');
            $table->text('description')->nullable();
            $table->foreignId('parent_department_id')->nullable()->constrained('departments')->onDelete('set null');
            $table->unsignedBigInteger('head_employee_id')->nullable(); // FK added later after employees table
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['code', 'is_active']);
            $table->index('head_employee_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('departments');
    }
};
