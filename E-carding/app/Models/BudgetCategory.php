<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class BudgetCategory extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'code',
        'name',
        'description',
        'parent_category_id',
        'is_active',
    ];

    public function parentCategory(): BelongsTo
    {
        return $this->belongsTo(BudgetCategory::class, 'parent_category_id');
    }

    public function childCategories(): HasMany
    {
        return $this->hasMany(BudgetCategory::class, 'parent_category_id');
    }
}
