<?php

namespace App\Services;

class MidtransService
{
    protected string $serverKey;
    protected string $clientKey;
    protected bool $isProduction;
    protected string $merchantId;

    public function __construct()
    {
        $this->serverKey = config('services.midtrans.server_key', '');
        $this->clientKey = config('services.midtrans.client_key', '');
        $this->isProduction = config('services.midtrans.is_production', false);
        $this->merchantId = config('services.midtrans.merchant_id', '');
    }

    /**
     * Get Snap API URL
     */
    protected function getSnapUrl(): string
    {
        return $this->isProduction
            ? 'https://app.midtrans.com/snap/v1/transactions'
            : 'https://app.sandbox.midtrans.com/snap/v1/transactions';
    }

    /**
     * Create Snap token for payment
     */
    public function createSnapToken(array $params): array
    {
        $orderId = $params['order_id'];
        $grossAmount = (int) $params['gross_amount'];
        $customerName = $params['customer_name'];
        $customerEmail = $params['customer_email'] ?? '';
        $itemDetails = $params['item_details'] ?? [];

        // Calculate sum of item details
        $itemSum = 0;
        if (!empty($itemDetails)) {
            foreach ($itemDetails as $item) {
                $itemSum += (int) $item['price'] * (int) $item['quantity'];
            }
        }

        // Frontend URL for callbacks (Flutter web app)
        $frontendUrl = config('app.frontend_url', 'http://localhost:5000');

        $payload = [
            'transaction_details' => [
                'order_id' => $orderId,
                'gross_amount' => $grossAmount,
            ],
            'customer_details' => [
                'first_name' => $customerName,
                'email' => $customerEmail,
            ],
            'callbacks' => [
                'finish' => $frontendUrl . '/#/payment-result?order_id=' . $orderId,
            ],
        ];

        // Only include item_details if sum matches gross_amount
        // Otherwise, create a single item with the total amount
        if (!empty($itemDetails) && $itemSum === $grossAmount) {
            $payload['item_details'] = $itemDetails;
        } else {
            // Create a single item with the full amount to avoid mismatch
            $payload['item_details'] = [
                [
                    'id' => 'payment-' . $orderId,
                    'name' => 'Pembayaran Tagihan',
                    'price' => $grossAmount,
                    'quantity' => 1,
                ]
            ];
        }

        // Make API request
        $response = $this->makeRequest($this->getSnapUrl(), $payload);

        if (isset($response['error_messages'])) {
            throw new \Exception(implode(', ', $response['error_messages']));
        }

        return [
            'token' => $response['token'] ?? '',
            'redirect_url' => $response['redirect_url'] ?? '',
        ];
    }

    /**
     * Verify callback signature
     */
    public function verifySignature(array $payload): bool
    {
        $orderId = $payload['order_id'] ?? '';
        $statusCode = $payload['status_code'] ?? '';
        $grossAmount = $payload['gross_amount'] ?? '';
        $signatureKey = $payload['signature_key'] ?? '';

        $expectedSignature = hash('sha512', $orderId . $statusCode . $grossAmount . $this->serverKey);

        return $signatureKey === $expectedSignature;
    }

    /**
     * Make HTTP request to Midtrans
     */
    protected function makeRequest(string $url, array $payload): array
    {
        $authHeader = base64_encode($this->serverKey . ':');

        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_URL => $url,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => json_encode($payload),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => [
                'Accept: application/json',
                'Content-Type: application/json',
                'Authorization: Basic ' . $authHeader,
            ],
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($response === false) {
            throw new \Exception('Failed to connect to Midtrans');
        }

        return json_decode($response, true) ?? [];
    }

    /**
     * Get transaction status from Midtrans
     */
    public function getStatus(string $orderId): array
    {
        $url = $this->isProduction
            ? "https://api.midtrans.com/v2/{$orderId}/status"
            : "https://api.sandbox.midtrans.com/v2/{$orderId}/status";

        $authHeader = base64_encode($this->serverKey . ':');

        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_URL => $url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => [
                'Accept: application/json',
                'Authorization: Basic ' . $authHeader,
            ],
        ]);

        $response = curl_exec($ch);
        curl_close($ch);

        return json_decode($response, true) ?? [];
    }
}
