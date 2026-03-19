<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('positions', function (Blueprint $table) {
            $table->id();
            $table->string('code', 50)->unique();
            $table->string('title');
            $table->text('description')->nullable();
            $table->integer('grade_level')->nullable();
            $table->decimal('base_salary', 15, 2)->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['code', 'grade_level']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('positions');
    }
};
