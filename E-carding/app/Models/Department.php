<?php

namespace App\Models;

use App\Models\Employee;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Department extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'code',
        'name',
        'description',
        'parent_department_id',
        'head_employee_id',
        'is_active',
    ];

    public function parentDepartment(): BelongsTo
    {
        return $this->belongsTo(Department::class, 'parent_department_id');
    }

    public function childDepartments(): HasMany
    {
        return $this->hasMany(Department::class, 'parent_department_id');
    }

    public function headEmployee(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'head_employee_id');
    }

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class);
    }
}
