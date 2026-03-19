<?php

namespace App\Services\Workflow;

use App\Models\ObligationRequest;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ORSPreAuditService
{
    public function preAudit(ObligationRequest $request): ObligationRequest
    {
        return DB::transaction(function () use ($request) {
            $request->loadMissing('budgetAllocation');
            $allocation = $request->budgetAllocation()->lockForUpdate()->firstOrFail();

            if ($allocation->status !== 'active') {
                throw ValidationException::withMessages([
                    'allocation' => 'Budget allocation is not active.',
                ]);
            }

            if ((float) $allocation->available_balance < (float) $request->amount) {
                throw ValidationException::withMessages([
                    'allocation' => 'Insufficient allotment for this ORS request.',
                ]);
            }

            $request->status = 'pending';
            $request->submitted_at = now();
            $request->save();

            return $request;
        });
    }
}
