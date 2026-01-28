<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    use HasFactory;

    protected $fillable = [
        'nis',
        'name',
        'class_name',
        'major',
        'parent_name',
        'parent_phone',
        'parent_email',
        'status',
        'avatar_url',
        'enrolled_at',
    ];

    protected $casts = [
        'enrolled_at' => 'datetime',
    ];

    /**
     * Get display class name
     */
    public function getDisplayClassAttribute(): string
    {
        return $this->major ? "{$this->class_name} - {$this->major}" : $this->class_name;
    }

    /**
     * Get user account associated with this student
     */
    public function user()
    {
        return $this->hasOne(User::class, 'student_id');
    }

    /**
     * Get all invoices for this student
     */
    public function invoices()
    {
        return $this->hasMany(Invoice::class);
    }

    /**
     * Get unpaid invoices
     */
    public function unpaidInvoices()
    {
        return $this->hasMany(Invoice::class)->where('status', 'unpaid');
    }

    /**
     * Get overdue invoices
     */
    public function overdueInvoices()
    {
        return $this->hasMany(Invoice::class)
            ->where('status', 'unpaid')
            ->where('due_date', '<', now());
    }
}
