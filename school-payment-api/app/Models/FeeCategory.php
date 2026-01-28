<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeeCategory extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'type',
        'frequency',
        'base_amount',
        'is_active',
        'allow_installment',
        'max_installments',
    ];

    protected $casts = [
        'base_amount' => 'decimal:2',
        'is_active' => 'boolean',
        'allow_installment' => 'boolean',
    ];

    /**
     * Get type display name
     */
    public function getTypeDisplayNameAttribute(): string
    {
        return match ($this->type) {
            'akademik' => 'Akademik',
            'non_akademik' => 'Non-Akademik',
            'insidental' => 'Insidental',
            'administratif' => 'Administratif',
            default => ucfirst($this->type),
        };
    }

    /**
     * Get frequency display name
     */
    public function getFrequencyDisplayNameAttribute(): string
    {
        return match ($this->frequency) {
            'once' => 'Sekali Bayar',
            'monthly' => 'Bulanan',
            'semester' => 'Per Semester',
            'yearly' => 'Tahunan',
            default => ucfirst($this->frequency),
        };
    }

    /**
     * Get fee rates for this category
     */
    public function feeRates()
    {
        return $this->hasMany(FeeRate::class, 'category_id');
    }

    /**
     * Get invoices for this category
     */
    public function invoices()
    {
        return $this->hasMany(Invoice::class, 'category_id');
    }

    /**
     * Scope: active categories only
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}
