<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Invoice extends Model
{
    use HasFactory;

    protected $fillable = [
        'invoice_number',
        'student_id',
        'category_id',
        'period',
        'total_amount',
        'paid_amount',
        'status',
        'due_date',
        'notes',
        'created_by',
    ];

    protected $casts = [
        'total_amount' => 'decimal:2',
        'paid_amount' => 'decimal:2',
        'due_date' => 'date',
    ];

    /**
     * Get remaining amount
     */
    public function getRemainingAmountAttribute(): float
    {
        return (float) $this->total_amount - (float) $this->paid_amount;
    }

    /**
     * Check if invoice is overdue
     */
    public function getIsOverdueAttribute(): bool
    {
        return $this->status === 'unpaid' && $this->due_date->isPast();
    }

    /**
     * Get status display name
     */
    public function getStatusDisplayNameAttribute(): string
    {
        return match ($this->status) {
            'unpaid' => 'Belum Dibayar',
            'paid' => 'Lunas',
            'partial' => 'Sebagian',
            'expired' => 'Kadaluarsa',
            'cancelled' => 'Dibatalkan',
            default => ucfirst($this->status),
        };
    }

    /**
     * Get the student
     */
    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    /**
     * Get the category
     */
    public function category()
    {
        return $this->belongsTo(FeeCategory::class, 'category_id');
    }

    /**
     * Get invoice items
     */
    public function items()
    {
        return $this->hasMany(InvoiceItem::class);
    }

    /**
     * Get transactions for this invoice
     */
    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }

    /**
     * Get receipt for this invoice
     */
    public function receipt()
    {
        return $this->hasOne(Receipt::class);
    }

    /**
     * Get creator user
     */
    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * Scope: unpaid only
     */
    public function scopeUnpaid($query)
    {
        return $query->where('status', 'unpaid');
    }

    /**
     * Scope: overdue only
     */
    public function scopeOverdue($query)
    {
        return $query->where('status', 'unpaid')->where('due_date', '<', now());
    }

    /**
     * Generate unique invoice number
     */
    public static function generateInvoiceNumber(): string
    {
        $prefix = 'INV';
        $date = now()->format('Ymd');
        $lastInvoice = self::whereDate('created_at', today())->orderBy('id', 'desc')->first();
        $sequence = $lastInvoice ? (int) substr($lastInvoice->invoice_number, -4) + 1 : 1;

        return sprintf('%s-%s-%04d', $prefix, $date, $sequence);
    }
}
