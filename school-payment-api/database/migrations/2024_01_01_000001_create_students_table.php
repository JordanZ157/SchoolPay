<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('students', function (Blueprint $table) {
            $table->id();
            $table->string('nis')->unique();
            $table->string('name');
            $table->string('class_name');
            $table->string('major')->nullable(); // Jurusan (for SMK/SMA)
            $table->unsignedBigInteger('parent_id')->nullable();
            $table->string('parent_name')->nullable();
            $table->string('parent_phone')->nullable();
            $table->string('parent_email')->nullable();
            $table->enum('status', ['active', 'inactive', 'graduated'])->default('active');
            $table->string('avatar_url')->nullable();
            $table->timestamp('enrolled_at')->nullable();
            $table->timestamps();

            $table->foreign('parent_id')->references('id')->on('users')->onDelete('set null');
        });

        // Add foreign key to users table
        Schema::table('users', function (Blueprint $table) {
            $table->foreign('student_id')->references('id')->on('students')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['student_id']);
        });
        Schema::dropIfExists('students');
    }
};
