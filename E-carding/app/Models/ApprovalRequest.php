<?php

namespace App\Models;

use App\Models\ApprovalAction;
use App\Models\ApprovalWorkflow;
use App\Models\Department;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class ApprovalRequest extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'request_number',
        'workflow_id',
        'requested_by',
        'department_id',
        'approvable_type',
        'approvable_id',
        'current_level',
        'total_levels',
        'approvals_received',
        'approvals_required',
        'status',
        'submitted_at',
        'completed_at',
        'expires_at',
        'request_summary',
        'request_data',
        'amount',
        'priority',
        'remarks',
    ];

    protected function casts(): array
    {
        return [
            'request_data' => 'array',
            'submitted_at' => 'datetime',
            'completed_at' => 'datetime',
            'expires_at' => 'datetime',
        ];
    }

    public function workflow(): BelongsTo
    {
        return $this->belongsTo(ApprovalWorkflow::class, 'workflow_id');
    }

    public function requester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requested_by');
    }

    public function department(): BelongsTo
    {
        return $this->belongsTo(Department::class);
    }

    public function approvable(): MorphTo
    {
        return $this->morphTo();
    }

    public function actions(): HasMany
    {
        return $this->hasMany(ApprovalAction::class);
    }
}
