<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'date_of_birth')) {
                $table->date('date_of_birth')->nullable()->after('phone');
            }
            if (!Schema::hasColumn('users', 'is_senior_citizen')) {
                $table->boolean('is_senior_citizen')->default(false)->after('date_of_birth');
            }
            if (!Schema::hasColumn('users', 'is_student')) {
                $table->boolean('is_student')->default(false)->after('is_senior_citizen');
            }
            if (!Schema::hasColumn('users', 'student_id')) {
                $table->string('student_id')->nullable()->after('is_student');
            }
            if (!Schema::hasColumn('users', 'corporate_account_id')) {
                $table->string('corporate_account_id')->nullable()->after('student_id');
            }
            if (!Schema::hasColumn('users', 'employee_id')) {
                $table->string('employee_id')->nullable()->after('corporate_account_id');
            }
            if (!Schema::hasColumn('users', 'user_category')) {
                $table->string('user_category')->default('regular')->after('employee_id');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['date_of_birth', 'is_senior_citizen', 'is_student', 'student_id', 'corporate_account_id', 'employee_id', 'user_category']);
        });
    }
};
