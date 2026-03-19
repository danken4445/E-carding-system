<?php

namespace App\Models;

use App\Models\BudgetAllocation;
use App\Models\Department;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class ObligationRequest extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'ors_number',
        'budget_allocation_id',
        'department_id',
        'requested_by',
        'payee_name',
        'payee_address',
        'payee_tin',
        'purpose',
        'request_date',
        'needed_date',
        'amount',
        'tax_amount',
        'net_amount',
        'attachments',
        'reference_number',
        'status',
        'submitted_at',
        'approved_at',
        'approved_by',
        'obligated_at',
        'obligated_by',
        'remarks',
    ];

    protected function casts(): array
    {
        return [
            'attachments' => 'array',
            'request_date' => 'date',
            'needed_date' => 'date',
            'submitted_at' => 'datetime',
            'approved_at' => 'datetime',
            'obligated_at' => 'datetime',
        ];
    }

    public function budgetAllocation(): BelongsTo
    {
        return $this->belongsTo(BudgetAllocation::class);
    }

    public function department(): BelongsTo
    {
        return $this->belongsTo(Department::class);
    }

    public function requester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requested_by');
    }
}
