<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
	public function run(): void
	{
		$admin = User::updateOrCreate(
			['email' => 'admin@ecarding.local'],
			[
				'name' => 'E-Carding Admin',
				'password' => 'password',
				'email_verified_at' => now(),
			]
		);

		$admin->syncRoles(['ADMIN']);
	}
}

