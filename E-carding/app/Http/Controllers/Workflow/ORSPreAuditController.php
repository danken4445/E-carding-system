<?php

namespace App\Http\Controllers\Workflow;

use App\Http\Controllers\Controller;
use App\Models\ObligationRequest;
use App\Services\Workflow\ORSPreAuditService;
use Illuminate\Http\JsonResponse;

class ORSPreAuditController extends Controller
{
    public function store(ObligationRequest $obligationRequest, ORSPreAuditService $service): JsonResponse
    {
        $ors = $service->preAudit($obligationRequest);

        return response()->json([
            'message' => 'ORS pre-audit passed.',
            'data' => [
                'ors_id' => $ors->id,
                'status' => $ors->status,
            ],
        ]);
    }
}
