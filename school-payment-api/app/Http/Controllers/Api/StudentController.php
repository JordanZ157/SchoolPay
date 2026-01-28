<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Student;
use App\Models\User;
use App\Models\AuditLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class StudentController extends Controller
{
    /**
     * Get list of students
     */
    public function index(Request $request): JsonResponse
    {
        $query = Student::query();

        // Filter by class
        if ($request->has('class_name')) {
            $query->where('class_name', $request->class_name);
        }

        // Filter by status
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        // Search by name or NIS
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('nis', 'like', "%{$search}%");
            });
        }

        $students = $query->orderBy('name')->paginate(20);

        return response()->json([
            'success' => true,
            'data' => collect($students->items())->map(fn($s) => $this->formatStudent($s)),
            'meta' => [
                'current_page' => $students->currentPage(),
                'last_page' => $students->lastPage(),
                'per_page' => $students->perPage(),
                'total' => $students->total(),
            ],
        ]);
    }

    /**
     * Get single student
     */
    public function show(int $id): JsonResponse
    {
        $student = Student::with('invoices.category')->find($id);

        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Siswa tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $this->formatStudent($student, true),
        ]);
    }

    /**
     * Create new student
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'nis' => 'required|string|max:50|unique:students,nis',
            'name' => 'required|string|max:255',
            'class_name' => 'required|string|max:50',
            'major' => 'sometimes|string|max:100',
            'parent_id' => 'sometimes|nullable|exists:users,id',
            'parent_name' => 'sometimes|string|max:255',
            'parent_phone' => 'sometimes|string|max:20',
            'parent_email' => 'sometimes|email|max:255',
            'status' => 'sometimes|in:active,inactive,graduated',
            'create_account' => 'sometimes|boolean',
        ]);

        $student = Student::create([
            'nis' => $request->nis,
            'name' => $request->name,
            'class_name' => $request->class_name,
            'major' => $request->major,
            'parent_id' => $request->parent_id,
            'parent_name' => $request->parent_name,
            'parent_phone' => $request->parent_phone,
            'parent_email' => $request->parent_email,
            'status' => $request->status ?? 'active',
            'enrolled_at' => now(),
        ]);

        AuditLog::log('create', 'Student', $student->id, null, $student->toArray());

        // Create user account if requested (default: true)
        $credentials = null;
        if ($request->boolean('create_account', true)) {
            $email = $request->parent_email ?? $request->nis . '@siswa.sekolah.id';
            $password = Str::random(10);

            // Check if email already exists
            $existingUser = User::where('email', $email)->first();
            if (!$existingUser) {
                $user = User::create([
                    'name' => $student->name,
                    'email' => $email,
                    'password' => Hash::make('123456'),
                    'role' => 'siswa',
                    'student_id' => $student->id,
                    'must_change_password' => true,
                ]);

                $credentials = [
                    'userId' => (string) $user->id,
                    'email' => $email,
                    'password' => '123456',
                ];

                // Send email notification if parent_email is provided
                if ($request->parent_email) {
                    try {
                        Mail::raw(
                            "Akun siswa telah dibuat untuk {$student->name}.\n\n" .
                            "Email: {$email}\n" .
                            "Password: 123456\n\n" .
                            "Silakan login di aplikasi SchoolPay untuk melihat tagihan dan melakukan pembayaran.\n\n" .
                            "Anda WAJIB mengganti password Anda setelah login pertama.",
                            function ($message) use ($request, $student) {
                                $message->to($request->parent_email)
                                    ->subject("Kredensial Akun Siswa - {$student->name}");
                            }
                        );
                    } catch (\Exception $e) {
                        // Email sending failed, but account is still created
                    }
                }
            }
        }

        $responseData = $this->formatStudent($student);
        if ($credentials) {
            $responseData['credentials'] = $credentials;
        }

        return response()->json([
            'success' => true,
            'message' => $credentials
                ? 'Siswa dan akun login berhasil ditambahkan'
                : 'Siswa berhasil ditambahkan',
            'data' => $responseData,
        ], 201);
    }

    /**
     * Update student
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $student = Student::find($id);

        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Siswa tidak ditemukan',
            ], 404);
        }

        $request->validate([
            'nis' => 'sometimes|string|max:50|unique:students,nis,' . $id,
            'name' => 'sometimes|string|max:255',
            'class_name' => 'sometimes|string|max:50',
            'major' => 'sometimes|string|max:100',
            'parent_id' => 'sometimes|nullable|exists:users,id',
            'parent_name' => 'sometimes|string|max:255',
            'parent_phone' => 'sometimes|string|max:20',
            'parent_email' => 'sometimes|email|max:255',
            'status' => 'sometimes|in:active,inactive,graduated',
        ]);

        $before = $student->toArray();
        $student->update($request->only([
            'nis',
            'name',
            'class_name',
            'major',
            'parent_id',
            'parent_name',
            'parent_phone',
            'parent_email',
            'status'
        ]));

        AuditLog::log('update', 'Student', $student->id, $before, $student->toArray());

        return response()->json([
            'success' => true,
            'message' => 'Data siswa berhasil diperbarui',
            'data' => $this->formatStudent($student),
        ]);
    }

    /**
     * Delete student
     */
    public function destroy(int $id): JsonResponse
    {
        $student = Student::find($id);

        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Siswa tidak ditemukan',
            ], 404);
        }

        // Check if student has invoices
        if ($student->invoices()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat menghapus siswa yang memiliki tagihan',
            ], 400);
        }

        $before = $student->toArray();
        $student->delete();

        AuditLog::log('delete', 'Student', $id, $before, null);

        return response()->json([
            'success' => true,
            'message' => 'Siswa berhasil dihapus',
        ]);
    }

    /**
     * Format student for API response
     */
    private function formatStudent(Student $student, bool $includeInvoices = false): array
    {
        $data = [
            'id' => (string) $student->id,
            'nis' => $student->nis,
            'name' => $student->name,
            'className' => $student->class_name,
            'major' => $student->major,
            'parentId' => $student->parent_id ? (string) $student->parent_id : null,
            'parentName' => $student->parent_name,
            'parentPhone' => $student->parent_phone,
            'parentEmail' => $student->parent_email,
            'status' => $student->status,
            'avatarUrl' => $student->avatar_url,
            'enrolledAt' => $student->enrolled_at?->toIso8601String(),
        ];

        if ($includeInvoices && $student->invoices) {
            $data['invoiceSummary'] = [
                'total' => $student->invoices->count(),
                'unpaid' => $student->invoices->where('status', 'unpaid')->count(),
                'totalUnpaidAmount' => (float) $student->invoices
                    ->where('status', 'unpaid')
                    ->sum(fn($inv) => $inv->remaining_amount),
            ];
        }

        return $data;
    }
}
