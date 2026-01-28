<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Login user and create token
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
            'device_name' => 'sometimes|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Email atau password salah.'],
            ]);
        }

        // Check if account is active
        if (!$user->is_active) {
            throw ValidationException::withMessages([
                'email' => ['Akun Anda dinonaktifkan. Hubungi administrator.'],
            ]);
        }

        $deviceName = $request->device_name ?? 'web-app';
        $token = $user->createToken($deviceName)->plainTextToken;

        // Load student relationship if applicable
        if ($user->student_id) {
            $user->load('student');
        }

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil',
            'data' => [
                'user' => $this->formatUser($user),
                'token' => $token,
                'mustChangePassword' => (bool) $user->must_change_password,
            ],
        ]);
    }

    /**
     * Logout user (revoke token)
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil',
        ]);
    }

    /**
     * Get current authenticated user
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->student_id) {
            $user->load('student');
        }

        return response()->json([
            'success' => true,
            'data' => $this->formatUser($user),
        ]);
    }

    /**
     * Change password (required on first login)
     */
    public function changePassword(Request $request): JsonResponse
    {
        $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:6|confirmed',
        ]);

        $user = $request->user();

        if (!Hash::check($request->current_password, $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => ['Password saat ini salah.'],
            ]);
        }

        $user->update([
            'password' => Hash::make($request->new_password),
            'must_change_password' => false,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil diubah',
        ]);
    }

    /**
     * Format user data for API response
     */
    private function formatUser(User $user): array
    {
        return [
            'id' => (string) $user->id,
            'email' => $user->email,
            'name' => $user->name,
            'role' => $user->role,
            'roleDisplayName' => $user->role_display_name,
            'studentId' => $user->student_id ? (string) $user->student_id : null,
            'classId' => $user->class_id,
            'avatarUrl' => $user->avatar_url,
            'mustChangePassword' => (bool) $user->must_change_password,
            'createdAt' => $user->created_at->toIso8601String(),
            'student' => $user->student ? [
                'id' => (string) $user->student->id,
                'nis' => $user->student->nis,
                'name' => $user->student->name,
                'className' => $user->student->class_name,
                'major' => $user->student->major,
            ] : null,
        ];
    }
}

