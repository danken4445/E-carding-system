<?php

namespace App\Models;

use App\Models\Payroll;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class PayrollPeriod extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'period_code',
        'period_type',
        'start_date',
        'end_date',
        'payment_date',
        'status',
        'remarks',
    ];

    public function payrolls(): HasMany
    {
        return $this->hasMany(Payroll::class);
    }
}
