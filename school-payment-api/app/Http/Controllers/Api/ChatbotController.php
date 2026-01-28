<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatbotSession;
use App\Models\ChatbotLog;
use App\Services\ChatbotService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatbotController extends Controller
{
    protected ChatbotService $chatbotService;

    public function __construct(ChatbotService $chatbotService)
    {
        $this->chatbotService = $chatbotService;
    }

    /**
     * Handle chatbot message
     */
    public function message(Request $request): JsonResponse
    {
        $request->validate([
            'message' => 'required|string|max:1000',
        ]);

        $user = $request->user();
        $message = $request->message;

        // Get or create session
        $session = ChatbotSession::firstOrCreate(
            ['user_id' => $user->id],
            ['last_active_at' => now()]
        );

        // Process message with chatbot service
        $response = $this->chatbotService->processMessage($user, $message, $session);

        // Log the conversation
        ChatbotLog::create([
            'user_id' => $user->id,
            'message' => $message,
            'intent' => $response['intent'],
            'response' => $response['reply'],
        ]);

        // Update session
        $session->updateContext($response['intent'], $response['context'] ?? []);

        return response()->json([
            'success' => true,
            'data' => [
                'reply' => $response['reply'],
                'quickActions' => $response['quick_actions'] ?? [],
                'intent' => $response['intent'],
            ],
        ]);
    }

    /**
     * Get chat history
     */
    public function history(Request $request): JsonResponse
    {
        $logs = ChatbotLog::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->limit(50)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $logs->map(fn($log) => [
                'id' => (string) $log->id,
                'message' => $log->message,
                'response' => $log->response,
                'intent' => $log->intent,
                'createdAt' => $log->created_at->toIso8601String(),
            ])->reverse()->values(),
        ]);
    }
}
