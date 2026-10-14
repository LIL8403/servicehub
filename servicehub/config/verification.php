<?php

/**
 * Verification document types and rules.
 *
 * This is a phase-1 static configuration. It will migrate to a
 * PlatformSetting document when the admin portal ships, without
 * changing the shape of the API responses that consume it.
 */
return [

    /*
    |--------------------------------------------------------------------------
    | Identity document types
    |--------------------------------------------------------------------------
    |
    | The artisan must select one of these when submitting their ID.
    | Each has a label, whether the back image is required, and whether
    | the document has an expiry date.
    |
    */
    'identity_document_types' => [
        [
            'key' => 'cni',
            'label' => 'National Identity Card (CNI)',
            'requires_back' => true,
            'has_expiry' => true,
        ],
        [
            'key' => 'passport',
            'label' => 'Passport',
            'requires_back' => false,
            'has_expiry' => true,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Supporting document types
    |--------------------------------------------------------------------------
    |
    | These are all optional. The artisan may attach any number of them,
    | up to the limit below.
    |
    */
    'supporting_document_types' => [
        [
            'key' => 'professional_certificate',
            'label' => 'Professional certificate',
            'description' => 'A certificate issued by a trade body or training institution.',
        ],
        [
            'key' => 'training_certificate',
            'label' => 'Training certificate',
            'description' => 'Evidence of formal training relevant to your trade.',
        ],
        [
            'key' => 'trade_qualification',
            'label' => 'Trade qualification',
            'description' => 'A recognised qualification for your profession.',
        ],
        [
            'key' => 'business_registration',
            'label' => 'Business registration',
            'description' => 'Only if you operate as a registered business.',
        ],
        [
            'key' => 'other_authorization',
            'label' => 'Other authorisation',
            'description' => 'Any other document that supports your application.',
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Limits and constraints
    |--------------------------------------------------------------------------
    */
    'max_supporting_documents' => 8,

    'max_file_size_kb' => 5120, // 5 MB

    'allowed_mime_types' => [
        'image/jpeg',
        'image/png',
        'image/webp',
        'application/pdf',
    ],
];