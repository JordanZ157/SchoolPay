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
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->string('order_id')->unique(); // Midtrans order ID
            $table->foreignId('invoice_id')->constrained('invoices')->onDelete('cascade');
            $table->decimal('gross_amount', 15, 2);
            $table->string('payment_type')->nullable(); // bank_transfer, gopay, credit_card, qris, etc.
            $table->enum('status', ['pending', 'settlement', 'capture', 'deny', 'cancel', 'expire', 'refund'])->default('pending');
            $table->timestamp('transaction_time')->nullable();
            $table->timestamp('settlement_time')->nullable();
            $table->string('reference_number')->nullable();
            $table->text('raw_payload')->nullable(); // JSON payload from Midtrans
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
