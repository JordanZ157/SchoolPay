<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Student;
use App\Models\AuditLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    /**
     * Get list of users (admin only)
     */
    public function index(Request $request): JsonResponse
    {
        $query = User::with('student');

        // Filter by role
        if ($request->has('role')) {
            $query->where('role', $request->role);
        }

        // Search by name or email
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $users = $query->orderBy('created_at', 'desc')->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $users->items() ? collect($users->items())->map(fn($user) => $this->formatUser($user)) : [],
            'meta' => [
                'current_page' => $users->currentPage(),
                'last_page' => $users->lastPage(),
                'per_page' => $users->perPage(),
                'total' => $users->total(),
            ],
        ]);
    }

    /**
     * Get single user
     */
    public function show(int $id): JsonResponse
    {
        $user = User::with('student')->find($id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $this->formatUser($user),
        ]);
    }

    /**
     * Create new user (admin only)
     * Default password: 123456
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'role' => ['required', Rule::in(['admin', 'bendahara', 'wali_kelas', 'siswa'])],
            'student_id' => 'nullable|exists:students,id',
            // For siswa role with student info
            'nis' => 'required_if:role,siswa|string|max:50',
            'class_name' => 'required_if:role,siswa|string|max:50',
            'major' => 'nullable|string|max:100',
            'parent_name' => 'nullable|string|max:255',
            'parent_phone' => 'nullable|string|max:20',
            'parent_email' => 'nullable|email|max:255',
        ]);

        // For siswa role, create student first
        $studentId = $request->student_id;
        if ($request->role === 'siswa' && !$studentId) {
            $student = Student::create([
                'nis' => $request->nis,
                'name' => $request->name,
                'class_name' => $request->class_name,
                'major' => $request->major,
                'parent_name' => $request->parent_name,
                'parent_phone' => $request->parent_phone,
                'parent_email' => $request->parent_email,
                'status' => 'active',
                'enrolled_at' => now(),
            ]);
            $studentId = $student->id;
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make('123456'),
            'role' => $request->role,
            'student_id' => $studentId,
            'class_id' => $request->role === 'wali_kelas' ? $request->class_id : null,
            'must_change_password' => true,
            'is_active' => true,
        ]);

        // If creating siswa account and student_id is provided
        if ($request->student_id && $request->role === 'siswa') {
            // Student is already linked via student_id
        }

        // Log audit
        AuditLog::log('create', 'User', $user->id, null, $user->toArray());

        return response()->json([
            'success' => true,
            'message' => 'User berhasil dibuat dengan password default: 123456',
            'data' => $this->formatUser($user),
        ], 201);
    }

    /**
     * Update user
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $user = User::find($id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => ['sometimes', 'email', Rule::unique('users')->ignore($id)],
            'role' => ['sometimes', Rule::in(['admin', 'bendahara', 'wali_kelas', 'siswa'])],
            'student_id' => 'nullable|exists:students,id',
            'is_active' => 'sometimes|boolean',
            // Student fields if role is siswa
            'class_name' => 'nullable|string|max:50',
            'major' => 'nullable|string|max:100',
            'parent_name' => 'nullable|string|max:255',
            'parent_phone' => 'nullable|string|max:20',
            'parent_email' => 'nullable|email|max:255',
        ]);

        $oldData = $user->toArray();

        // Update user fields
        $updateData = $request->only(['name', 'email', 'role', 'student_id', 'is_active']);

        // Handle class_id for wali_kelas
        if ($request->has('class_id') || $user->role === 'wali_kelas') {
            $updateData['class_id'] = $request->class_id;
        }

        $user->update($updateData);

        // If siswa with student, update student info too
        if ($user->role === 'siswa' && $user->student_id) {
            $student = Student::find($user->student_id);
            if ($student) {
                $student->update($request->only([
                    'class_name',
                    'major',
                    'parent_name',
                    'parent_phone',
                    'parent_email'
                ]));
                // Also update student name to match user name
                if ($request->has('name')) {
                    $student->update(['name' => $request->name]);
                }
            }
        }

        // Log audit
        AuditLog::log('update', 'User', $user->id, $oldData, $user->toArray());

        return response()->json([
            'success' => true,
            'message' => 'User berhasil diupdate',
            'data' => $this->formatUser($user->fresh()->load('student')),
        ]);
    }

    /**
     * Delete user
     */
    public function destroy(int $id): JsonResponse
    {
        $user = User::find($id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        // Prevent deleting self
        if ($user->id === auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat menghapus akun sendiri',
            ], 403);
        }

        $oldData = $user->toArray();
        $user->delete();

        // Log audit
        AuditLog::log('delete', 'User', $id, $oldData, null);

        return response()->json([
            'success' => true,
            'message' => 'User berhasil dihapus',
        ]);
    }

    /**
     * Reset user password to default (123456)
     */
    public function resetPassword(int $id): JsonResponse
    {
        $user = User::find($id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        $user->update([
            'password' => Hash::make('123456'),
            'must_change_password' => true,
        ]);

        // Log audit
        AuditLog::log('reset_password', 'User', $user->id, null, null);

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil direset ke: 123456',
        ]);
    }

    /**
     * Toggle user active status
     */
    public function toggleActive(int $id): JsonResponse
    {
        $user = User::find($id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        // Prevent deactivating self
        if ($user->id === auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat menonaktifkan akun sendiri',
            ], 403);
        }

        $user->update(['is_active' => !$user->is_active]);

        // Log audit
        AuditLog::log('toggle_active', 'User', $user->id, null, ['is_active' => $user->is_active]);

        return response()->json([
            'success' => true,
            'message' => $user->is_active ? 'Akun berhasil diaktifkan' : 'Akun berhasil dinonaktifkan',
            'data' => $this->formatUser($user->fresh()->load('student')),
        ]);
    }

    /**
     * Format user for API response
     */
    private function formatUser(User $user): array
    {
        $data = [
            'id' => (string) $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'roleDisplayName' => $user->role_display_name,
            'studentId' => $user->student_id ? (string) $user->student_id : null,
            'classId' => $user->class_id,
            'avatarUrl' => $user->avatar_url,
            'mustChangePassword' => (bool) $user->must_change_password,
            'isActive' => (bool) $user->is_active,
            'createdAt' => $user->created_at->toIso8601String(),
        ];

        // Include student info for siswa role
        if ($user->student) {
            $data['student'] = [
                'id' => (string) $user->student->id,
                'nis' => $user->student->nis,
                'name' => $user->student->name,
                'className' => $user->student->class_name,
                'major' => $user->student->major,
                'parentName' => $user->student->parent_name,
                'parentPhone' => $user->student->parent_phone,
                'parentEmail' => $user->student->parent_email,
                'status' => $user->student->status,
            ];
        }

        return $data;
    }
}

