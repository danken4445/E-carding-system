<?php

namespace App\Models;

use App\Models\Department;
use App\Models\Loan;
use App\Models\Payroll;
use App\Models\Position;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Employee extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'employee_number',
        'user_id',
        'first_name',
        'middle_name',
        'last_name',
        'suffix',
        'birth_date',
        'gender',
        'civil_status',
        'email',
        'phone',
        'address',
        'department_id',
        'position_id',
        'employment_status',
        'employment_type',
        'hire_date',
        'regularization_date',
        'separation_date',
        'separation_reason',
        'base_salary',
        'step_increment',
        'current_salary',
        'salary_grade',
        'sss_number',
        'philhealth_number',
        'pagibig_number',
        'tin_number',
        'gsis_number',
        'is_active',
        'remarks',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function department(): BelongsTo
    {
        return $this->belongsTo(Department::class);
    }

    public function position(): BelongsTo
    {
        return $this->belongsTo(Position::class);
    }

    public function payrolls(): HasMany
    {
        return $this->hasMany(Payroll::class);
    }

    public function loans(): HasMany
    {
        return $this->hasMany(Loan::class);
    }
}
