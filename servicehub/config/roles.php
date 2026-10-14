<?php

return [
    'permissions' => [
        'customer' => [
            'view-services', 'create-service-request', 'view-own-requests', 'manage-own-profile',
        ],
        'artisan' => [
            'manage-own-profile', 'manage-own-services', 'view-service-requests',
            'manage-own-requests', 'view-own-services', 'add-own-service',
            'update-own-service', 'remove-own-service',
        ],
        'admin' => ['*'],
    ],
];
