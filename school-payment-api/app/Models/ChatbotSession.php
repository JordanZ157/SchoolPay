<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ChatbotSession extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'last_intent',
        'context_json',
        'last_active_at',
    ];

    protected $casts = [
        'context_json' => 'array',
        'last_active_at' => 'datetime',
    ];

    /**
     * Get the user
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Update session context
     */
    public function updateContext(string $intent, array $context = []): self
    {
        $this->update([
            'last_intent' => $intent,
            'context_json' => $context,
            'last_active_at' => now(),
        ]);

        return $this;
    }
}
