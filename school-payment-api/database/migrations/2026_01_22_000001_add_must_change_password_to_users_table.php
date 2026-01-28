<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Add must_change_password column
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('must_change_password')->default(true)->after('avatar_url');
        });

        // Update all existing users: set must_change_password = true and reset password to 123456
        DB::table('users')->update([
            'must_change_password' => true,
            'password' => Hash::make('123456'),
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('must_change_password');
        });
    }
};
