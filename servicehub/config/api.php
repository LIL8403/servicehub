<?php

return [
    'auth_rate_limit' => (int) env('API_AUTH_RATE_LIMIT', 5),
    'auth_ip_rate_limit' => (int) env('API_AUTH_IP_RATE_LIMIT', 30),
    'ai_rate_limit' => (int) env('API_AI_RATE_LIMIT', 10),
    'payment_rate_limit' => (int) env('API_PAYMENT_RATE_LIMIT', 10),
    'verification_rate_limit' => (int) env('API_VERIFICATION_RATE_LIMIT', 20),
];
