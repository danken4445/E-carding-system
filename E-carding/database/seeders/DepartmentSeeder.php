<?php

namespace Database\Seeders;

use App\Models\Department;
use Illuminate\Database\Seeder;

class DepartmentSeeder extends Seeder
{
	public function run(): void
	{
		$rows = [
			['code' => 'HR', 'name' => 'Human Resources'],
			['code' => 'ACC', 'name' => 'Accounting'],
			['code' => 'BUD', 'name' => 'Budget Office'],
			['code' => 'TRE', 'name' => 'Treasury'],
			['code' => 'ADMIN', 'name' => 'Administration'],
		];

		foreach ($rows as $row) {
			Department::updateOrCreate(
				['code' => $row['code']],
				[
					'name' => $row['name'],
					'description' => $row['name'].' Department',
					'is_active' => true,
				]
			);
		}
	}
}

