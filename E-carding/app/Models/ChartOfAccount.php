<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class ChartOfAccount extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'account_code',
        'account_name',
        'description',
        'account_type',
        'account_category',
        'parent_account_id',
        'is_active',
        'is_system_account',
        'level',
    ];

    public function parentAccount(): BelongsTo
    {
        return $this->belongsTo(ChartOfAccount::class, 'parent_account_id');
    }

    public function childAccounts(): HasMany
    {
        return $this->hasMany(ChartOfAccount::class, 'parent_account_id');
    }
}
