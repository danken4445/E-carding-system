<?php

namespace Tests\Feature\Workflow;

use App\Models\ApprovalLevel;
use App\Models\ApprovalRequest;
use App\Models\ApprovalWorkflow;
use App\Models\Department;
use App\Models\Employee;
use App\Models\Position;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class ApprovalRoutingFlowTest extends TestCase
{
    use RefreshDatabase;

    public function test_approval_routing_progresses_per_level_and_completes(): void
    {
        $department = Department::create([
            'code' => 'ACC2',
            'name' => 'Accounting 2',
            'is_active' => true,
        ]);

        $position = Position::create([
            'code' => 'PAY2',
            'title' => 'Payroll Officer',
            'base_salary' => 38000,
            'is_active' => true,
        ]);

        $requestor = User::factory()->create();
        $approver1 = User::factory()->create();
        $approver2 = User::factory()->create();

        Role::firstOrCreate(['name' => 'ACCOUNTING', 'guard_name' => 'web']);
        Role::firstOrCreate(['name' => 'BUDGET', 'guard_name' => 'web']);

        $approver1->assignRole('ACCOUNTING');
        $approver2->assignRole('BUDGET');

        $employee = Employee::create([
            'employee_number' => 'EMP-AR-001',
            'first_name' => 'Approval',
            'last_name' => 'Target',
            'department_id' => $department->id,
            'position_id' => $position->id,
            'employment_status' => 'regular',
            'hire_date' => now()->subYears(1)->toDateString(),
            'base_salary' => 30000,
            'current_salary' => 30000,
            'is_active' => true,
        ]);

        $workflow = ApprovalWorkflow::create([
            'workflow_code' => 'WF-ORS-001',
            'workflow_name' => 'ORS Approval Chain',
            'model_type' => 'obligation_request',
            'required_approvals' => 2,
            'require_sequential' => true,
            'allow_rejection' => true,
            'is_active' => true,
        ]);

        ApprovalLevel::create([
            'workflow_id' => $workflow->id,
            'level_order' => 1,
            'level_name' => 'Accounting Review',
            'approver_type' => 'role',
            'approver_identifier' => 'ACCOUNTING',
            'required_approvers' => 1,
        ]);

        ApprovalLevel::create([
            'workflow_id' => $workflow->id,
            'level_order' => 2,
            'level_name' => 'Budget Review',
            'approver_type' => 'role',
            'approver_identifier' => 'BUDGET',
            'required_approvers' => 1,
        ]);

        $approvalRequest = ApprovalRequest::create([
            'request_number' => 'APR-001',
            'workflow_id' => $workflow->id,
            'requested_by' => $requestor->id,
            'department_id' => $department->id,
            'approvable_type' => Employee::class,
            'approvable_id' => $employee->id,
            'current_level' => 1,
            'total_levels' => 2,
            'approvals_received' => 0,
            'approvals_required' => 2,
            'status' => 'pending',
            'submitted_at' => now(),
            'amount' => 50000,
            'priority' => 'normal',
        ]);

        $response1 = $this->actingAs($approver1)
            ->postJson(route('workflows.approvals.approve', $approvalRequest));

        $response1->assertOk()
            ->assertJsonPath('data.status', 'in_progress')
            ->assertJsonPath('data.current_level', 2);

        $approvalRequest->refresh();
        $this->assertEquals('in_progress', $approvalRequest->status);
        $this->assertEquals(1, (int) $approvalRequest->approvals_received);

        $response2 = $this->actingAs($approver2)
            ->postJson(route('workflows.approvals.approve', $approvalRequest));

        $response2->assertOk()
            ->assertJsonPath('data.status', 'approved');

        $approvalRequest->refresh();
        $this->assertEquals('approved', $approvalRequest->status);
        $this->assertNotNull($approvalRequest->completed_at);

        $this->assertDatabaseCount('approval_actions', 2);
    }

    public function test_user_without_required_role_cannot_approve_current_level(): void
    {
        $department = Department::create([
            'code' => 'ACC3',
            'name' => 'Accounting 3',
            'is_active' => true,
        ]);

        $requestor = User::factory()->create();
        $unauthorized = User::factory()->create();

        Role::firstOrCreate(['name' => 'ACCOUNTING', 'guard_name' => 'web']);

        $workflow = ApprovalWorkflow::create([
            'workflow_code' => 'WF-SEC-001',
            'workflow_name' => 'Secure Route',
            'model_type' => 'payroll',
            'required_approvals' => 1,
            'is_active' => true,
        ]);

        ApprovalLevel::create([
            'workflow_id' => $workflow->id,
            'level_order' => 1,
            'level_name' => 'Accounting Review',
            'approver_type' => 'role',
            'approver_identifier' => 'ACCOUNTING',
            'required_approvers' => 1,
        ]);

        $approvalRequest = ApprovalRequest::create([
            'request_number' => 'APR-002',
            'workflow_id' => $workflow->id,
            'requested_by' => $requestor->id,
            'department_id' => $department->id,
            'approvable_type' => User::class,
            'approvable_id' => $requestor->id,
            'current_level' => 1,
            'total_levels' => 1,
            'approvals_received' => 0,
            'approvals_required' => 1,
            'status' => 'pending',
            'submitted_at' => now(),
            'amount' => 15000,
            'priority' => 'normal',
        ]);

        $this->actingAs($unauthorized)
            ->postJson(route('workflows.approvals.approve', $approvalRequest))
            ->assertForbidden();
    }
}
