<?php

namespace Database\Seeders;

use App\Models\ChartOfAccount;
use Illuminate\Database\Seeder;

class ChartOfAccountsSeeder extends Seeder
{
	public function run(): void
	{
		$rows = [
			['account_code' => '1010', 'account_name' => 'Cash - National Treasury', 'account_type' => 'asset'],
			['account_code' => '2010', 'account_name' => 'Due to Employees', 'account_type' => 'liability'],
			['account_code' => '5010', 'account_name' => 'Salaries and Wages - Regular', 'account_type' => 'expense'],
			['account_code' => '5020', 'account_name' => 'Salaries and Wages - Casual', 'account_type' => 'expense'],
			['account_code' => '5030', 'account_name' => 'Personnel Benefits Contributions', 'account_type' => 'expense'],
		];

		foreach ($rows as $row) {
			ChartOfAccount::updateOrCreate(
				['account_code' => $row['account_code']],
				[
					'account_name' => $row['account_name'],
					'account_type' => $row['account_type'],
					'account_category' => 'operating',
					'is_active' => true,
					'is_system_account' => true,
					'level' => 1,
				]
			);
		}
	}
}

