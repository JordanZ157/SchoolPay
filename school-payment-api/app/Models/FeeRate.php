<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeeRate extends Model
{
    use HasFactory;

    protected $fillable = [
        'category_id',
        'class_level',
        'academic_year',
        'amount',
        'installment_rules',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'installment_rules' => 'array',
    ];

    /**
     * Get the category for this rate
     */
    public function category()
    {
        return $this->belongsTo(FeeCategory::class, 'category_id');
    }
}
