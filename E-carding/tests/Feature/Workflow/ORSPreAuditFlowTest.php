<?php

namespace Tests\Feature\Workflow;

use App\Models\BudgetAllocation;
use App\Models\BudgetCategory;
use App\Models\BudgetYear;
use App\Models\Department;
use App\Models\ObligationRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ORSPreAuditFlowTest extends TestCase
{
    use RefreshDatabase;

    public function test_ors_pre_audit_passes_when_allotment_is_available(): void
    {
        $user = User::factory()->create();
        $department = Department::create([
            'code' => 'BUD',
            'name' => 'Budget Office',
            'is_active' => true,
        ]);

        $year = BudgetYear::create([
            'fiscal_year' => (int) now()->year,
            'start_date' => now()->startOfYear()->toDateString(),
            'end_date' => now()->endOfYear()->toDateString(),
            'status' => 'active',
            'total_budget' => 1000000,
            'available_balance' => 1000000,
        ]);

        $category = BudgetCategory::create([
            'code' => 'PS',
            'name' => 'Personnel Services',
            'is_active' => true,
        ]);

        $allocation = BudgetAllocation::create([
            'allocation_code' => 'ALLOT-001',
            'budget_year_id' => $year->id,
            'department_id' => $department->id,
            'budget_category_id' => $category->id,
            'allocated_amount' => 50000,
            'available_balance' => 50000,
            'status' => 'active',
        ]);

        $ors = ObligationRequest::create([
            'ors_number' => 'ORS-001',
            'budget_allocation_id' => $allocation->id,
            'department_id' => $department->id,
            'requested_by' => $user->id,
            'payee_name' => 'Payroll Batch A',
            'purpose' => 'Payroll obligation',
            'request_date' => now()->toDateString(),
            'amount' => 32000,
            'tax_amount' => 0,
            'net_amount' => 32000,
            'status' => 'draft',
        ]);

        $response = $this->actingAs($user)
            ->postJson(route('workflows.ors.pre-audit', $ors));

        $response->assertOk()
            ->assertJsonPath('data.status', 'pending');

        $this->assertDatabaseHas('obligation_requests', [
            'id' => $ors->id,
            'status' => 'pending',
        ]);
    }

    public function test_ors_pre_audit_fails_when_allotment_is_insufficient(): void
    {
        $user = User::factory()->create();
        $department = Department::create([
            'code' => 'BUD2',
            'name' => 'Budget Office 2',
            'is_active' => true,
        ]);

        $year = BudgetYear::create([
            'fiscal_year' => (int) now()->year + 1,
            'start_date' => now()->startOfYear()->toDateString(),
            'end_date' => now()->endOfYear()->toDateString(),
            'status' => 'active',
            'total_budget' => 1000000,
            'available_balance' => 1000000,
        ]);

        $category = BudgetCategory::create([
            'code' => 'MOOE',
            'name' => 'Maintenance and Other Operating Expenses',
            'is_active' => true,
        ]);

        $allocation = BudgetAllocation::create([
            'allocation_code' => 'ALLOT-002',
            'budget_year_id' => $year->id,
            'department_id' => $department->id,
            'budget_category_id' => $category->id,
            'allocated_amount' => 10000,
            'available_balance' => 10000,
            'status' => 'active',
        ]);

        $ors = ObligationRequest::create([
            'ors_number' => 'ORS-002',
            'budget_allocation_id' => $allocation->id,
            'department_id' => $department->id,
            'requested_by' => $user->id,
            'payee_name' => 'Payroll Batch B',
            'purpose' => 'Payroll obligation',
            'request_date' => now()->toDateString(),
            'amount' => 12000,
            'tax_amount' => 0,
            'net_amount' => 12000,
            'status' => 'draft',
        ]);

        $response = $this->actingAs($user)
            ->postJson(route('workflows.ors.pre-audit', $ors));

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['allocation']);
    }
}
