<?php

namespace App\Models;

use App\Models\ApprovalWorkflow;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ApprovalLevel extends Model
{
    use HasFactory;

    protected $fillable = [
        'workflow_id',
        'level_order',
        'level_name',
        'description',
        'approver_type',
        'approver_identifier',
        'required_approvers',
        'can_delegate',
        'sla_hours',
        'conditions',
    ];

    protected function casts(): array
    {
        return [
            'conditions' => 'array',
            'can_delegate' => 'boolean',
        ];
    }

    public function workflow(): BelongsTo
    {
        return $this->belongsTo(ApprovalWorkflow::class, 'workflow_id');
    }
}
