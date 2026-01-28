<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'student_id',
        'class_id',
        'avatar_url',
        'must_change_password',
        'is_active',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'must_change_password' => 'boolean',
        'is_active' => 'boolean',
    ];

    /**
     * Get role display name
     */
    public function getRoleDisplayNameAttribute(): string
    {
        return match ($this->role) {
            'admin' => 'Admin',
            'bendahara' => 'Bendahara',
            'wali_kelas' => 'Wali Kelas',
            'siswa' => 'Siswa',
            default => ucfirst($this->role),
        };
    }

    /**
     * Check if user is admin (admin or bendahara or wali_kelas)
     */
    public function isAdmin(): bool
    {
        return in_array($this->role, ['admin', 'bendahara', 'wali_kelas']);
    }

    /**
     * Get the student associated with the user
     */
    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    /**
     * Get chatbot sessions
     */
    public function chatbotSessions()
    {
        return $this->hasMany(ChatbotSession::class);
    }

    /**
     * Get chatbot logs
     */
    public function chatbotLogs()
    {
        return $this->hasMany(ChatbotLog::class);
    }

    /**
     * Get audit logs created by this user
     */
    public function auditLogs()
    {
        return $this->hasMany(AuditLog::class);
    }
}
