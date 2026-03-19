<?php

namespace Database\Seeders;

use App\Models\LoanType;
use Illuminate\Database\Seeder;

class LoanTypeSeeder extends Seeder
{
    public function run(): void
    {
        $rows = [
            [
                'code' => 'GSIS_POL',
                'name' => 'GSIS Policy Loan',
                'description' => 'Government Service Insurance System policy loan',
                'interest_rate' => 8.00,
                'min_term_months' => 6,
                'max_term_months' => 36,
            ],
            [
                'code' => 'MPL',
                'name' => 'Multi-Purpose Loan',
                'description' => 'General employee multi-purpose loan',
                'interest_rate' => 6.00,
                'min_term_months' => 6,
                'max_term_months' => 24,
            ],
            [
                'code' => 'CALAMITY',
                'name' => 'Calamity Loan',
                'description' => 'Emergency calamity loan',
                'interest_rate' => 4.00,
                'min_term_months' => 6,
                'max_term_months' => 24,
            ],
        ];

        foreach ($rows as $row) {
            LoanType::updateOrCreate(
                ['code' => $row['code']],
                [
                    'name' => $row['name'],
                    'description' => $row['description'],
                    'min_amount' => 1000,
                    'max_amount' => 500000,
                    'interest_rate' => $row['interest_rate'],
                    'min_term_months' => $row['min_term_months'],
                    'max_term_months' => $row['max_term_months'],
                    'require_guarantor' => false,
                    'is_active' => true,
                ]
            );
        }
    }
}
