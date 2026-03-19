<?php

namespace App\Models;

use App\Models\Employee;
use App\Models\LoanPayment;
use App\Models\LoanType;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Loan extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'loan_number',
        'employee_id',
        'loan_type_id',
        'principal_amount',
        'interest_rate',
        'term_months',
        'monthly_amortization',
        'loan_date',
        'first_payment_date',
        'maturity_date',
        'guarantor_1_id',
        'guarantor_2_id',
        'total_amount',
        'amount_paid',
        'balance',
        'payments_made',
        'remaining_payments',
        'status',
        'approved_at',
        'approved_by',
        'fully_paid_at',
        'purpose',
        'remarks',
    ];

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    public function loanType(): BelongsTo
    {
        return $this->belongsTo(LoanType::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(LoanPayment::class);
    }
}
