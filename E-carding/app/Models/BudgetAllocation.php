<?php

namespace App\Models;

use App\Models\BudgetCategory;
use App\Models\BudgetYear;
use App\Models\Department;
use App\Models\ObligationRequest;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class BudgetAllocation extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'allocation_code',
        'budget_year_id',
        'department_id',
        'budget_category_id',
        'allocated_amount',
        'obligated_amount',
        'disbursed_amount',
        'available_balance',
        'status',
        'remarks',
    ];

    public function budgetYear(): BelongsTo
    {
        return $this->belongsTo(BudgetYear::class);
    }

    public function department(): BelongsTo
    {
        return $this->belongsTo(Department::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(BudgetCategory::class, 'budget_category_id');
    }

    public function obligationRequests(): HasMany
    {
        return $this->hasMany(ObligationRequest::class);
    }
}
