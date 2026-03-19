<?php

namespace App\Models;

use App\Models\ApprovalLevel;
use App\Models\ApprovalRequest;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class ApprovalWorkflow extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'workflow_code',
        'workflow_name',
        'description',
        'model_type',
        'required_approvals',
        'require_sequential',
        'allow_rejection',
        'is_active',
        'conditions',
    ];

    protected function casts(): array
    {
        return [
            'conditions' => 'array',
            'require_sequential' => 'boolean',
            'allow_rejection' => 'boolean',
            'is_active' => 'boolean',
        ];
    }

    public function levels(): HasMany
    {
        return $this->hasMany(ApprovalLevel::class, 'workflow_id');
    }

    public function requests(): HasMany
    {
        return $this->hasMany(ApprovalRequest::class, 'workflow_id');
    }
}
