<?php

namespace App\Services\Workflow;

use App\Models\Loan;
use App\Models\LoanPayment;
use App\Models\Payroll;
use Illuminate\Support\Facades\DB;

class PayrollDeductionService
{
    public function process(Payroll $payroll): array
    {
        return DB::transaction(function () use ($payroll) {
            $payroll->loadMissing('employee');

            if ($payroll->employee->employment_status !== 'regular') {
                return $this->finalizePayroll($payroll, 0.0, 0);
            }

            $totalDeducted = 0.0;
            $loanCount = 0;

            $loans = Loan::query()
                ->where('employee_id', $payroll->employee_id)
                ->where('status', 'active')
                ->where('balance', '>', 0)
                ->lockForUpdate()
                ->get();

            foreach ($loans as $loan) {
                $due = (float) min((float) $loan->monthly_amortization, (float) $loan->balance);

                if ($due <= 0) {
                    continue;
                }

                $loan->amount_paid = (float) $loan->amount_paid + $due;
                $loan->balance = (float) $loan->balance - $due;
                $loan->payments_made = (int) $loan->payments_made + 1;
                $loan->remaining_payments = max(0, (int) $loan->term_months - (int) $loan->payments_made);

                if ((float) $loan->balance <= 0.0) {
                    $loan->status = 'fully_paid';
                    $loan->fully_paid_at = now();
                }

                $loan->save();

                LoanPayment::create([
                    'payment_number' => $this->buildPaymentNumber($loan),
                    'loan_id' => $loan->id,
                    'payroll_id' => $payroll->id,
                    'payment_sequence' => (int) $loan->payments_made,
                    'payment_date' => now()->toDateString(),
                    'due_date' => now()->toDateString(),
                    'amount_due' => $due,
                    'amount_paid' => $due,
                    'principal_paid' => $due,
                    'interest_paid' => 0,
                    'penalty' => 0,
                    'balance_after_payment' => $loan->balance,
                    'status' => 'paid',
                    'days_overdue' => 0,
                    'payment_method' => 'payroll_deduction',
                ]);

                $totalDeducted += $due;
                $loanCount++;
            }

            return $this->finalizePayroll($payroll, $totalDeducted, $loanCount);
        });
    }

    private function finalizePayroll(Payroll $payroll, float $loanDeduction, int $loanCount): array
    {
        $nonLoanDeductions = (float) $payroll->sss_contribution
            + (float) $payroll->philhealth_contribution
            + (float) $payroll->pagibig_contribution
            + (float) $payroll->gsis_contribution
            + (float) $payroll->withholding_tax
            + (float) $payroll->other_deductions;

        $payroll->loan_deductions = $loanDeduction;
        $payroll->total_deductions = $nonLoanDeductions + $loanDeduction;
        $payroll->net_pay = (float) $payroll->gross_pay - (float) $payroll->total_deductions;
        $payroll->save();

        return [
            'payroll_id' => $payroll->id,
            'loan_deductions' => $loanDeduction,
            'net_pay' => (float) $payroll->net_pay,
            'loans_processed' => $loanCount,
        ];
    }

    private function buildPaymentNumber(Loan $loan): string
    {
        return sprintf('LP-%s-%06d', now()->format('YmdHis'), $loan->id);
    }
}
