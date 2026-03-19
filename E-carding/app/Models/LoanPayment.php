<?php

namespace App\Models;

use App\Models\Loan;
use App\Models\Payroll;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class LoanPayment extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'payment_number',
        'loan_id',
        'payroll_id',
        'payment_sequence',
        'payment_date',
        'due_date',
        'amount_due',
        'amount_paid',
        'principal_paid',
        'interest_paid',
        'penalty',
        'balance_after_payment',
        'status',
        'days_overdue',
        'payment_method',
        'reference_number',
        'remarks',
    ];

    public function loan(): BelongsTo
    {
        return $this->belongsTo(Loan::class);
    }

    public function payroll(): BelongsTo
    {
        return $this->belongsTo(Payroll::class);
    }
}
