<?php

namespace Database\Seeders;

use App\Models\Position;
use Illuminate\Database\Seeder;

class PositionSeeder extends Seeder
{
	public function run(): void
	{
		$rows = [
			['code' => 'ACC_OFF', 'title' => 'Accountant', 'grade_level' => 22, 'base_salary' => 65000],
			['code' => 'BUD_OFF', 'title' => 'Budget Officer', 'grade_level' => 21, 'base_salary' => 60000],
			['code' => 'TRE_OFF', 'title' => 'Treasurer', 'grade_level' => 23, 'base_salary' => 70000],
			['code' => 'HR_OFF', 'title' => 'HR Officer', 'grade_level' => 18, 'base_salary' => 45000],
			['code' => 'PAY_CLK', 'title' => 'Payroll Clerk', 'grade_level' => 12, 'base_salary' => 28000],
		];

		foreach ($rows as $row) {
			Position::updateOrCreate(
				['code' => $row['code']],
				[
					'title' => $row['title'],
					'description' => $row['title'],
					'grade_level' => $row['grade_level'],
					'base_salary' => $row['base_salary'],
					'is_active' => true,
				]
			);
		}
	}
}

