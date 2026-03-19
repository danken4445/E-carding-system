<?php

namespace App\Http\Controllers\Workflow;

use App\Http\Controllers\Controller;
use App\Models\Payroll;
use App\Services\Workflow\PayrollDeductionService;
use Illuminate\Http\JsonResponse;

class PayrollProcessingController extends Controller
{
    public function store(Payroll $payroll, PayrollDeductionService $service): JsonResponse
    {
        $result = $service->process($payroll);

        return response()->json([
            'message' => 'Payroll processed successfully.',
            'data' => $result,
        ]);
    }
}
