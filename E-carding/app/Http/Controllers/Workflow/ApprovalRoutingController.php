<?php

namespace App\Http\Controllers\Workflow;

use App\Http\Controllers\Controller;
use App\Models\ApprovalRequest;
use App\Services\Workflow\ApprovalRoutingService;
use Illuminate\Http\JsonResponse;

class ApprovalRoutingController extends Controller
{
    public function approve(ApprovalRequest $approvalRequest, ApprovalRoutingService $service): JsonResponse
    {
        $updated = $service->approve($approvalRequest, request()->user());

        return response()->json([
            'message' => 'Approval recorded.',
            'data' => [
                'approval_request_id' => $updated->id,
                'status' => $updated->status,
                'current_level' => $updated->current_level,
            ],
        ]);
    }
}
