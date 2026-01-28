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
        Schema::create('fee_rates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')->constrained('fee_categories')->onDelete('cascade');
            $table->string('class_level')->nullable(); // Jenjang/kelas
            $table->string('academic_year'); // Tahun ajaran
            $table->decimal('amount', 15, 2);
            $table->text('installment_rules')->nullable(); // JSON for installment rules
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('fee_rates');
    }
};
