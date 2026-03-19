<?php

namespace App\Models;

use App\Models\Employee;
use App\Models\LoanPayment;
use App\Models\PayrollPeriod;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Payroll extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'payrolls';

    protected $fillable = [
        'payroll_number',
        'employee_id',
        'payroll_period_id',
        'base_pay',
        'overtime_pay',
        'night_differential',
        'hazard_pay',
        'allowances',
        'bonuses',
        'other_earnings',
        'gross_pay',
        'sss_contribution',
        'philhealth_contribution',
        'pagibig_contribution',
        'gsis_contribution',
        'withholding_tax',
        'loan_deductions',
        'other_deductions',
        'total_deductions',
        'net_pay',
        'days_worked',
        'hours_worked',
        'overtime_hours',
        'status',
        'approved_at',
        'approved_by',
        'paid_at',
        'remarks',
    ];

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    public function period(): BelongsTo
    {
        return $this->belongsTo(PayrollPeriod::class, 'payroll_period_id');
    }

    public function approver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function loanPayments(): HasMany
    {
        return $this->hasMany(LoanPayment::class);
    }
}
