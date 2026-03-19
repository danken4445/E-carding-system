<?php

namespace Tests\Feature\Workflow;

use App\Models\Department;
use App\Models\Employee;
use App\Models\Loan;
use App\Models\LoanType;
use App\Models\Payroll;
use App\Models\PayrollPeriod;
use App\Models\Position;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PayrollLoanDeductionFlowTest extends TestCase
{
    use RefreshDatabase;

    public function test_regular_employee_payroll_process_deducts_active_loan(): void
    {
        $user = User::factory()->create();
        [$department, $position] = $this->seedOrgReferences();

        $employee = Employee::create([
            'employee_number' => 'EMP-1001',
            'user_id' => $user->id,
            'first_name' => 'Maria',
            'last_name' => 'Regular',
            'department_id' => $department->id,
            'position_id' => $position->id,
            'employment_status' => 'regular',
            'hire_date' => now()->subYears(3)->toDateString(),
            'base_salary' => 30000,
            'current_salary' => 30000,
            'is_active' => true,
        ]);

        $period = PayrollPeriod::create([
            'period_code' => '2026-03-15',
            'period_type' => 'semi_monthly',
            'start_date' => now()->startOfMonth()->toDateString(),
            'end_date' => now()->startOfMonth()->addDays(14)->toDateString(),
            'payment_date' => now()->addDays(2)->toDateString(),
            'status' => 'draft',
        ]);

        $payroll = Payroll::create([
            'payroll_number' => 'PR-1001',
            'employee_id' => $employee->id,
            'payroll_period_id' => $period->id,
            'gross_pay' => 20000,
            'sss_contribution' => 500,
            'philhealth_contribution' => 400,
            'pagibig_contribution' => 100,
            'withholding_tax' => 1000,
            'other_deductions' => 0,
            'total_deductions' => 2000,
            'net_pay' => 18000,
        ]);

        $loanType = LoanType::create([
            'code' => 'MPL',
            'name' => 'Multi-Purpose Loan',
            'min_amount' => 1000,
            'max_amount' => 500000,
            'interest_rate' => 6,
            'min_term_months' => 6,
            'max_term_months' => 24,
            'is_active' => true,
        ]);

        $loan = Loan::create([
            'loan_number' => 'LN-1001',
            'employee_id' => $employee->id,
            'loan_type_id' => $loanType->id,
            'principal_amount' => 10000,
            'interest_rate' => 6,
            'term_months' => 12,
            'monthly_amortization' => 1500,
            'loan_date' => now()->subMonths(2)->toDateString(),
            'first_payment_date' => now()->subMonth()->toDateString(),
            'maturity_date' => now()->addMonths(10)->toDateString(),
            'total_amount' => 10000,
            'amount_paid' => 0,
            'balance' => 5000,
            'payments_made' => 0,
            'remaining_payments' => 12,
            'status' => 'active',
        ]);

        $response = $this->actingAs($user)
            ->postJson(route('workflows.payroll.process', $payroll));

        $response->assertOk()
            ->assertJsonPath('data.loan_deductions', 1500)
            ->assertJsonPath('data.loans_processed', 1);

        $payroll->refresh();
        $this->assertEquals(1500.0, (float) $payroll->loan_deductions);
        $this->assertEquals(3500.0, (float) $payroll->total_deductions);
        $this->assertEquals(16500.0, (float) $payroll->net_pay);

        $this->assertDatabaseHas('loan_payments', [
            'loan_id' => $loan->id,
            'payroll_id' => $payroll->id,
            'status' => 'paid',
        ]);

        $loan->refresh();
        $this->assertEquals(3500.0, (float) $loan->balance);
        $this->assertEquals(1, (int) $loan->payments_made);
    }

    private function seedOrgReferences(): array
    {
        $department = Department::create([
            'code' => 'ACC',
            'name' => 'Accounting',
            'is_active' => true,
        ]);

        $position = Position::create([
            'code' => 'ACC_OFF',
            'title' => 'Accountant',
            'base_salary' => 40000,
            'is_active' => true,
        ]);

        return [$department, $position];
    }
}
