<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Receipt extends Model
{
    use HasFactory;

    protected $fillable = [
        'invoice_id',
        'receipt_number',
        'issued_at',
        'pdf_url',
        'metadata',
    ];

    protected $casts = [
        'issued_at' => 'datetime',
        'metadata' => 'array',
    ];

    /**
     * Get the invoice
     */
    public function invoice()
    {
        return $this->belongsTo(Invoice::class);
    }

    /**
     * Generate unique receipt number
     */
    public static function generateReceiptNumber(): string
    {
        $prefix = 'RCP';
        $date = now()->format('Ymd');
        $lastReceipt = self::whereDate('created_at', today())->orderBy('id', 'desc')->first();
        $sequence = $lastReceipt ? (int) substr($lastReceipt->receipt_number, -4) + 1 : 1;

        return sprintf('%s-%s-%04d', $prefix, $date, $sequence);
    }
}
