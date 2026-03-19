<?php

namespace App\Models;

use App\Models\BudgetAllocation;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class BudgetYear extends Model
{
    use HasFactory;

    protected $fillable = [
        'fiscal_year',
        'start_date',
        'end_date',
        'status',
        'total_budget',
        'allocated_amount',
        'obligated_amount',
        'disbursed_amount',
        'available_balance',
    ];

    public function allocations(): HasMany
    {
        return $this->hasMany(BudgetAllocation::class);
    }
}
