<?php

return [
    'rate_limits' => [
        'authentication_per_minute' => (int) env('API_AUTH_RATE_LIMIT', 5),
        'authentication_ip_per_minute' => (int) env('API_AUTH_IP_RATE_LIMIT', 30),
        'ai_per_minute' => (int) env('API_AI_RATE_LIMIT', 10),
        'payment_per_minute' => (int) env('API_PAYMENT_RATE_LIMIT', 10),
        'verification_per_minute' => (int) env('API_VERIFICATION_RATE_LIMIT', 20),
    ],
];
