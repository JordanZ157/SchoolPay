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
        // Add class_id column to users table for wali_kelas
        Schema::table('users', function (Blueprint $table) {
            $table->string('class_id')->nullable()->after('student_id');
        });

        // Delete old wali kelas user
        DB::table('users')->where('role', 'wali_kelas')->delete();

        // Create wali kelas for each grade level
        $waliKelasData = [
            ['name' => 'Wali Kelas X', 'email' => 'walikelas.x@school.com', 'class_id' => 'X'],
            ['name' => 'Wali Kelas XI', 'email' => 'walikelas.xi@school.com', 'class_id' => 'XI'],
            ['name' => 'Wali Kelas XII', 'email' => 'walikelas.xii@school.com', 'class_id' => 'XII'],
        ];

        foreach ($waliKelasData as $data) {
            DB::table('users')->insert([
                'name' => $data['name'],
                'email' => $data['email'],
                'password' => Hash::make('123456'),
                'role' => 'wali_kelas',
                'class_id' => $data['class_id'],
                'must_change_password' => true,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Delete wali kelas users created
        DB::table('users')->where('role', 'wali_kelas')->delete();

        // Remove class_id column
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('class_id');
        });
    }
};
