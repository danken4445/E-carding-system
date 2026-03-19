<?php

namespace App\Models;

use App\Models\Employee;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Position extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'code',
        'title',
        'description',
        'grade_level',
        'base_salary',
        'is_active',
    ];

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class);
    }
}
