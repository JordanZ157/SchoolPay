<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'invoice_id',
        'gross_amount',
        'payment_type',
        'status',
        'transaction_time',
        'settlement_time',
        'reference_number',
        'raw_payload',
    ];

    protected $casts = [
        'gross_amount' => 'decimal:2',
        'transaction_time' => 'datetime',
        'settlement_time' => 'datetime',
        'raw_payload' => 'array',
    ];

    /**
     * Get status display name
     */
    public function getStatusDisplayNameAttribute(): string
    {
        return match ($this->status) {
            'pending' => 'Menunggu',
            'settlement' => 'Berhasil',
            'capture' => 'Captured',
            'deny' => 'Ditolak',
            'cancel' => 'Dibatalkan',
            'expire' => 'Kadaluarsa',
            'refund' => 'Refund',
            default => ucfirst($this->status),
        };
    }

    /**
     * Get payment type display name
     */
    public function getPaymentTypeDisplayNameAttribute(): string
    {
        return match ($this->payment_type) {
            'bank_transfer' => 'Transfer Bank',
            'gopay' => 'GoPay',
            'shopeepay' => 'ShopeePay',
            'credit_card' => 'Kartu Kredit',
            'qris' => 'QRIS',
            default => $this->payment_type ?? 'Unknown',
        };
    }

    /**
     * Check if transaction is successful
     */
    public function getIsSuccessfulAttribute(): bool
    {
        return in_array($this->status, ['settlement', 'capture']);
    }

    /**
     * Get the invoice
     */
    public function invoice()
    {
        return $this->belongsTo(Invoice::class);
    }

    /**
     * Generate unique order ID for Midtrans
     */
    public static function generateOrderId(int $invoiceId): string
    {
        return sprintf('ORDER-%d-%s-%s', $invoiceId, now()->format('YmdHis'), strtoupper(substr(md5(uniqid()), 0, 6)));
    }
}
