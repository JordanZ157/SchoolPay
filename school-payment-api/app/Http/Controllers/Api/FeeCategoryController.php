<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FeeCategory;
use App\Models\AuditLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FeeCategoryController extends Controller
{
    /**
     * Get list of fee categories
     */
    public function index(Request $request): JsonResponse
    {
        $query = FeeCategory::query();

        // Filter by type
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        // Filter by active status
        if ($request->has('is_active')) {
            $query->where('is_active', $request->boolean('is_active'));
        }

        $categories = $query->orderBy('name')->get();

        return response()->json([
            'success' => true,
            'data' => $categories->map(fn($c) => $this->formatCategory($c)),
        ]);
    }

    /**
     * Get single category
     */
    public function show(int $id): JsonResponse
    {
        $category = FeeCategory::find($id);

        if (!$category) {
            return response()->json([
                'success' => false,
                'message' => 'Kategori tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $this->formatCategory($category),
        ]);
    }

    /**
     * Create new category
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'type' => 'required|in:akademik,non_akademik,insidental,administratif',
            'frequency' => 'required|in:once,monthly,semester,yearly',
            'base_amount' => 'required|numeric|min:0',
            'is_active' => 'sometimes|boolean',
            'allow_installment' => 'sometimes|boolean',
            'max_installments' => 'nullable|integer|min:1',
        ]);

        $category = FeeCategory::create([
            'name' => $request->name,
            'description' => $request->description,
            'type' => $request->type,
            'frequency' => $request->frequency,
            'base_amount' => $request->base_amount,
            'is_active' => $request->is_active ?? true,
            'allow_installment' => $request->allow_installment ?? false,
            'max_installments' => $request->max_installments,
        ]);

        AuditLog::log('create', 'FeeCategory', $category->id, null, $category->toArray());

        return response()->json([
            'success' => true,
            'message' => 'Kategori berhasil dibuat',
            'data' => $this->formatCategory($category),
        ], 201);
    }

    /**
     * Update category
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $category = FeeCategory::find($id);

        if (!$category) {
            return response()->json([
                'success' => false,
                'message' => 'Kategori tidak ditemukan',
            ], 404);
        }

        $request->validate([
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'type' => 'sometimes|in:akademik,non_akademik,insidental,administratif',
            'frequency' => 'sometimes|in:once,monthly,semester,yearly',
            'base_amount' => 'sometimes|numeric|min:0',
            'is_active' => 'sometimes|boolean',
            'allow_installment' => 'sometimes|boolean',
            'max_installments' => 'nullable|integer|min:1',
        ]);

        $before = $category->toArray();
        $category->update($request->only([
            'name',
            'description',
            'type',
            'frequency',
            'base_amount',
            'is_active',
            'allow_installment',
            'max_installments'
        ]));

        AuditLog::log('update', 'FeeCategory', $category->id, $before, $category->toArray());

        return response()->json([
            'success' => true,
            'message' => 'Kategori berhasil diperbarui',
            'data' => $this->formatCategory($category),
        ]);
    }

    /**
     * Delete category
     */
    public function destroy(int $id): JsonResponse
    {
        $category = FeeCategory::find($id);

        if (!$category) {
            return response()->json([
                'success' => false,
                'message' => 'Kategori tidak ditemukan',
            ], 404);
        }

        // Check if category has invoices
        if ($category->invoices()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat menghapus kategori yang memiliki tagihan',
            ], 400);
        }

        $before = $category->toArray();
        $category->delete();

        AuditLog::log('delete', 'FeeCategory', $id, $before, null);

        return response()->json([
            'success' => true,
            'message' => 'Kategori berhasil dihapus',
        ]);
    }

    /**
     * Format category for API response
     */
    private function formatCategory(FeeCategory $category): array
    {
        return [
            'id' => (string) $category->id,
            'name' => $category->name,
            'description' => $category->description,
            'type' => $category->type,
            'typeDisplayName' => $category->type_display_name,
            'frequency' => $category->frequency,
            'frequencyDisplayName' => $category->frequency_display_name,
            'baseAmount' => (float) $category->base_amount,
            'isActive' => $category->is_active,
            'allowInstallment' => $category->allow_installment,
            'maxInstallments' => $category->max_installments,
        ];
    }
}
