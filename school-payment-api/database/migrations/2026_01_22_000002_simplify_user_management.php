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
        // 1. Add is_active column to users
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('is_active')->default(true)->after('must_change_password');
        });

        // 2. For SQLite, we need to recreate the students table without parent_id
        // First, create a temporary table with new structure
        Schema::create('students_new', function (Blueprint $table) {
            $table->id();
            $table->string('nis')->unique();
            $table->string('name');
            $table->string('class_name');
            $table->string('major')->nullable();
            $table->string('parent_name')->nullable();
            $table->string('parent_phone')->nullable();
            $table->string('parent_email')->nullable();
            $table->enum('status', ['active', 'inactive', 'graduated'])->default('active');
            $table->string('avatar_url')->nullable();
            $table->timestamp('enrolled_at')->nullable();
            $table->timestamps();
        });

        // Copy data from old table to new (excluding parent_id)
        DB::statement('INSERT INTO students_new (id, nis, name, class_name, major, parent_name, parent_phone, parent_email, status, avatar_url, enrolled_at, created_at, updated_at) SELECT id, nis, name, class_name, major, parent_name, parent_phone, parent_email, status, avatar_url, enrolled_at, created_at, updated_at FROM students');

        // Drop old table and rename new
        Schema::drop('students');
        Schema::rename('students_new', 'students');

        // 3. Delete all users with role orang_tua
        DB::table('users')->where('role', 'orang_tua')->delete();

        // 4. Create user account for each student that doesn't have one
        $students = DB::table('students')->get();
        foreach ($students as $student) {
            // Check if user already exists for this student
            $existingUser = DB::table('users')->where('student_id', $student->id)->first();

            if (!$existingUser) {
                // Create user for this student
                $email = $student->parent_email ?? strtolower(str_replace(' ', '.', $student->name)) . '@siswa.sekolah.id';

                // Make sure email is unique
                $baseEmail = $email;
                $counter = 1;
                while (DB::table('users')->where('email', $email)->exists()) {
                    $parts = explode('@', $baseEmail);
                    $email = $parts[0] . $counter . '@' . $parts[1];
                    $counter++;
                }

                DB::table('users')->insert([
                    'name' => $student->name,
                    'email' => $email,
                    'password' => Hash::make('123456'),
                    'role' => 'siswa',
                    'student_id' => $student->id,
                    'must_change_password' => true,
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Recreate students table with parent_id
        Schema::create('students_new', function (Blueprint $table) {
            $table->id();
            $table->string('nis')->unique();
            $table->string('name');
            $table->string('class_name');
            $table->string('major')->nullable();
            $table->unsignedBigInteger('parent_id')->nullable();
            $table->string('parent_name')->nullable();
            $table->string('parent_phone')->nullable();
            $table->string('parent_email')->nullable();
            $table->enum('status', ['active', 'inactive', 'graduated'])->default('active');
            $table->string('avatar_url')->nullable();
            $table->timestamp('enrolled_at')->nullable();
            $table->timestamps();
        });

        // Copy data
        DB::statement('INSERT INTO students_new (id, nis, name, class_name, major, parent_name, parent_phone, parent_email, status, avatar_url, enrolled_at, created_at, updated_at) SELECT id, nis, name, class_name, major, parent_name, parent_phone, parent_email, status, avatar_url, enrolled_at, created_at, updated_at FROM students');

        Schema::drop('students');
        Schema::rename('students_new', 'students');

        // Remove is_active from users
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('is_active');
        });
    }
};
