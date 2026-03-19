<?php

namespace App\Models;

use App\Models\ApprovalLevel;
use App\Models\ApprovalRequest;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ApprovalAction extends Model
{
    use HasFactory;

    protected $fillable = [
        'approval_request_id',
        'approval_level_id',
        'user_id',
        'delegated_by',
        'level_order',
        'action',
        'action_date',
        'comments',
        'action_data',
        'response_time_hours',
        'is_within_sla',
        'signature_hash',
        'ip_address',
        'user_agent',
    ];

    protected function casts(): array
    {
        return [
            'action_date' => 'datetime',
            'action_data' => 'array',
            'is_within_sla' => 'boolean',
        ];
    }

    public function request(): BelongsTo
    {
        return $this->belongsTo(ApprovalRequest::class, 'approval_request_id');
    }

    public function level(): BelongsTo
    {
        return $this->belongsTo(ApprovalLevel::class, 'approval_level_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
