<?php

namespace App\Models;

use App\Models\Loan;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class LoanType extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'code',
        'name',
        'description',
        'min_amount',
        'max_amount',
        'interest_rate',
        'min_term_months',
        'max_term_months',
        'require_guarantor',
        'is_active',
    ];

    public function loans(): HasMany
    {
        return $this->hasMany(Loan::class);
    }
}
