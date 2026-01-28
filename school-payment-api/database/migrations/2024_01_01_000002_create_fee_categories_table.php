<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('fee_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
            $table->enum('type', ['akademik', 'non_akademik', 'insidental', 'administratif'])->default('akademik');
            $table->enum('frequency', ['once', 'monthly', 'semester', 'yearly'])->default('monthly');
            $table->decimal('base_amount', 15, 2)->default(0);
            $table->boolean('is_active')->default(true);
            $table->boolean('allow_installment')->default(false);
            $table->integer('max_installments')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('fee_categories');
    }
};
