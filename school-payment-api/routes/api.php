<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\InvoiceController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\MidtransController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\StudentController;
use App\Http\Controllers\Api\FeeCategoryController;
use App\Http\Controllers\Api\ChatbotController;
use App\Http\Controllers\Api\UserController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Public routes
Route::post('/login', [AuthController::class, 'login']);

// Midtrans webhook (no auth required)
Route::post('/midtrans/callback', [MidtransController::class, 'handleCallback']);

// Payment status check (no auth required - uses order_id for validation)
Route::get('/payment/status/{order_id}', [PaymentController::class, 'getStatus']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/change-password', [AuthController::class, 'changePassword']);

    // Invoices
    Route::get('/invoices', [InvoiceController::class, 'index']);
    Route::get('/invoices/{id}', [InvoiceController::class, 'show']);

    // Transactions (payment history)
    Route::get('/transactions', [PaymentController::class, 'getTransactions']);

    // Payment
    Route::post('/pay/{invoice_id}', [PaymentController::class, 'createSnapToken']);

    // Chatbot
    Route::post('/chatbot/message', [ChatbotController::class, 'message']);
    Route::get('/chatbot/history', [ChatbotController::class, 'history']);

    // Admin only routes
    Route::middleware('role:admin,bendahara,wali_kelas')->group(function () {
        // Invoice management
        Route::post('/invoices', [InvoiceController::class, 'store']);
        Route::post('/invoices/generate', [InvoiceController::class, 'generate']);

        // Students
        Route::get('/students', [StudentController::class, 'index']);
        Route::get('/students/{id}', [StudentController::class, 'show']);
        Route::post('/students', [StudentController::class, 'store']);
        Route::put('/students/{id}', [StudentController::class, 'update']);
        Route::delete('/students/{id}', [StudentController::class, 'destroy']);

        // Fee Categories
        Route::get('/fee-categories', [FeeCategoryController::class, 'index']);
        Route::get('/fee-categories/{id}', [FeeCategoryController::class, 'show']);
        Route::post('/fee-categories', [FeeCategoryController::class, 'store']);
        Route::put('/fee-categories/{id}', [FeeCategoryController::class, 'update']);
        Route::delete('/fee-categories/{id}', [FeeCategoryController::class, 'destroy']);

        // Users (admin only)
        Route::get('/users', [UserController::class, 'index']);
        Route::get('/users/{id}', [UserController::class, 'show']);
        Route::post('/users', [UserController::class, 'store']);
        Route::put('/users/{id}', [UserController::class, 'update']);
        Route::delete('/users/{id}', [UserController::class, 'destroy']);
        Route::post('/users/{id}/reset-password', [UserController::class, 'resetPassword']);
        Route::post('/users/{id}/toggle-active', [UserController::class, 'toggleActive']);

        // Reports
        Route::get('/reports/daily', [ReportController::class, 'daily']);
        Route::get('/reports/category', [ReportController::class, 'byCategory']);
        Route::get('/reports/student/{student_id}', [ReportController::class, 'byStudent']);
        Route::get('/reports/arrears', [ReportController::class, 'arrears']);
        Route::get('/reports/export', [ReportController::class, 'export']);
    });
});

