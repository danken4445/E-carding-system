<?php

namespace Database\Seeders;

use Database\Seeders\ChartOfAccountsSeeder;
use Database\Seeders\DepartmentSeeder;
use Database\Seeders\LoanTypeSeeder;
use Database\Seeders\PositionSeeder;
use Database\Seeders\RoleSeeder;
use Database\Seeders\UserSeeder;
// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            RoleSeeder::class,
            DepartmentSeeder::class,
            PositionSeeder::class,
            ChartOfAccountsSeeder::class,
            LoanTypeSeeder::class,
            UserSeeder::class,
        ]);
    }
}
