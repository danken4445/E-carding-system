<?php

use App\Http\Controllers\Workflow\ApprovalRoutingController;
use App\Http\Controllers\Workflow\ORSPreAuditController;
use App\Http\Controllers\Workflow\PayrollProcessingController;
use App\Http\Controllers\ProfileController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/dashboard', function () {
    return view('dashboard');
})->middleware(['auth', 'verified'])->name('dashboard');

Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');

    Route::post('/workflows/payroll/{payroll}/process', [PayrollProcessingController::class, 'store'])
        ->name('workflows.payroll.process');
    Route::post('/workflows/ors/{obligationRequest}/pre-audit', [ORSPreAuditController::class, 'store'])
        ->name('workflows.ors.pre-audit');
    Route::post('/workflows/approvals/{approvalRequest}/approve', [ApprovalRoutingController::class, 'approve'])
        ->name('workflows.approvals.approve');
});

require __DIR__.'/auth.php';
