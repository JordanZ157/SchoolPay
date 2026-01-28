<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InvoiceItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'invoice_id',
        'description',
        'amount',
        'quantity',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
    ];

    /**
     * Get total for this item
     */
    public function getTotalAttribute(): float
    {
        return (float) $this->amount * $this->quantity;
    }

    /**
     * Get the invoice
     */
    public function invoice()
    {
        return $this->belongsTo(Invoice::class);
    }
}
