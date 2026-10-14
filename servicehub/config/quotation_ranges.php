<?php

/**
 * Per-service reference ranges for the AI quotation analyzer.
 *
 * The `demo` track exists because CamPay's demo gateway caps
 * transactions at 25 XAF. Real-world ranges would flag every demo
 * quotation as absurdly low. The two tracks carry the same structure;
 * only the numbers differ.
 *
 * Which track is used is decided at runtime by
 * `AiOrchestrationService::analyzeQuotationForCustomer()`, based on
 * `config('services.campay.mode')`.
 *
 * Ranges are intentionally wide. The analyzer only flags when a
 * quotation is more than 2× the upper bound or less than half the
 * lower bound for its service. Anything within [min, max] is treated
 * as normal.
 *
 * Replace these numbers with real platform data once you have ≥20
 * completed jobs per service.
 */
return [

    /*
    |--------------------------------------------------------------------------
    | Environment cap
    |--------------------------------------------------------------------------
    |
    | The maximum transaction amount accepted by the active CamPay
    | gateway. Recorded here so the analyzer can mention it if it ever
    | needs to explain a suspiciously low number.
    |
    */
    'caps' => [
        'demo' => 25,
        'production' => 5000000, // 5M XAF — a sane upper bound
    ],

    /*
    |--------------------------------------------------------------------------
    | Demo-mode ranges
    |--------------------------------------------------------------------------
    |
    | Used when CAMPAY_MODE=DEV. Amounts are tiny because the demo
    | gateway caps at 25 XAF.
    |
    */
    'demo' => [
        'plumbing-leak-repair' => ['labour_min' => 1, 'labour_max' => 20, 'materials_min' => 0, 'materials_max' => 20],
        'plumbing-pipe-installation' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],
        'plumbing-drain-unclogging' => ['labour_min' => 1, 'labour_max' => 15, 'materials_min' => 0, 'materials_max' => 10],
        'plumbing-water-heater-repair' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],

        'electrical-socket-switch-repair' => ['labour_min' => 1, 'labour_max' => 10, 'materials_min' => 0, 'materials_max' => 10],
        'electrical-circuit-breaker-repair' => ['labour_min' => 1, 'labour_max' => 15, 'materials_min' => 0, 'materials_max' => 15],
        'electrical-light-installation' => ['labour_min' => 1, 'labour_max' => 15, 'materials_min' => 0, 'materials_max' => 10],
        'electrical-wiring-inspection' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 5],

        'carpentry-door-repair-installation' => ['labour_min' => 1, 'labour_max' => 20, 'materials_min' => 0, 'materials_max' => 20],
        'carpentry-furniture-assembly' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],
        'carpentry-shelving-storage' => ['labour_min' => 1, 'labour_max' => 20, 'materials_min' => 0, 'materials_max' => 20],
        'carpentry-window-frame-repair' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],

        'painting-interior-wall-painting' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],
        'painting-exterior-painting' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],
        'painting-touch-up-patching' => ['labour_min' => 1, 'labour_max' => 10, 'materials_min' => 0, 'materials_max' => 10],
        'painting-wallpaper-installation' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],

        'masonry-tile-installation' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],
        'masonry-wall-construction' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],
        'masonry-concrete-work' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],
        'masonry-plastering-rendering' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],

        'mechanics-generator-repair' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],
        'mechanics-ac-installation-service' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],
        'mechanics-water-pump-repair' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],
        'mechanics-vehicle-diagnostics' => ['labour_min' => 1, 'labour_max' => 25, 'materials_min' => 0, 'materials_max' => 25],
    ],

    /*
    |--------------------------------------------------------------------------
    | Production-mode ranges
    |--------------------------------------------------------------------------
    |
    | Realistic Cameroonian market ranges. Wide enough not to flag
    | legitimate quotes; narrow enough to catch outliers.
    |
    | Numbers are illustrative pending real platform data. Adjust when
    | the platform has ≥20 completed jobs per service.
    |
    */
    'production' => [
        'plumbing-leak-repair' => ['labour_min' => 15000, 'labour_max' => 60000, 'materials_min' => 5000, 'materials_max' => 60000],
        'plumbing-pipe-installation' => ['labour_min' => 25000, 'labour_max' => 120000, 'materials_min' => 20000, 'materials_max' => 150000],
        'plumbing-drain-unclogging' => ['labour_min' => 10000, 'labour_max' => 40000, 'materials_min' => 0, 'materials_max' => 15000],
        'plumbing-water-heater-repair' => ['labour_min' => 20000, 'labour_max' => 80000, 'materials_min' => 15000, 'materials_max' => 200000],

        'electrical-socket-switch-repair' => ['labour_min' => 8000, 'labour_max' => 35000, 'materials_min' => 2000, 'materials_max' => 25000],
        'electrical-circuit-breaker-repair' => ['labour_min' => 15000, 'labour_max' => 60000, 'materials_min' => 5000, 'materials_max' => 40000],
        'electrical-light-installation' => ['labour_min' => 10000, 'labour_max' => 50000, 'materials_min' => 3000, 'materials_max' => 30000],
        'electrical-wiring-inspection' => ['labour_min' => 30000, 'labour_max' => 150000, 'materials_min' => 0, 'materials_max' => 20000],

        'carpentry-door-repair-installation' => ['labour_min' => 15000, 'labour_max' => 70000, 'materials_min' => 10000, 'materials_max' => 80000],
        'carpentry-furniture-assembly' => ['labour_min' => 20000, 'labour_max' => 90000, 'materials_min' => 15000, 'materials_max' => 120000],
        'carpentry-shelving-storage' => ['labour_min' => 15000, 'labour_max' => 65000, 'materials_min' => 12000, 'materials_max' => 90000],
        'carpentry-window-frame-repair' => ['labour_min' => 20000, 'labour_max' => 85000, 'materials_min' => 15000, 'materials_max' => 100000],

        'painting-interior-wall-painting' => ['labour_min' => 20000, 'labour_max' => 100000, 'materials_min' => 25000, 'materials_max' => 200000],
        'painting-exterior-painting' => ['labour_min' => 30000, 'labour_max' => 150000, 'materials_min' => 40000, 'materials_max' => 300000],
        'painting-touch-up-patching' => ['labour_min' => 8000, 'labour_max' => 35000, 'materials_min' => 5000, 'materials_max' => 30000],
        'painting-wallpaper-installation' => ['labour_min' => 25000, 'labour_max' => 120000, 'materials_min' => 30000, 'materials_max' => 250000],

        'masonry-tile-installation' => ['labour_min' => 30000, 'labour_max' => 150000, 'materials_min' => 40000, 'materials_max' => 400000],
        'masonry-wall-construction' => ['labour_min' => 50000, 'labour_max' => 300000, 'materials_min' => 80000, 'materials_max' => 800000],
        'masonry-concrete-work' => ['labour_min' => 60000, 'labour_max' => 400000, 'materials_min' => 100000, 'materials_max' => 1000000],
        'masonry-plastering-rendering' => ['labour_min' => 25000, 'labour_max' => 120000, 'materials_min' => 20000, 'materials_max' => 150000],

        'mechanics-generator-repair' => ['labour_min' => 25000, 'labour_max' => 120000, 'materials_min' => 20000, 'materials_max' => 250000],
        'mechanics-ac-installation-service' => ['labour_min' => 20000, 'labour_max' => 100000, 'materials_min' => 15000, 'materials_max' => 200000],
        'mechanics-water-pump-repair' => ['labour_min' => 20000, 'labour_max' => 90000, 'materials_min' => 15000, 'materials_max' => 180000],
        'mechanics-vehicle-diagnostics' => ['labour_min' => 15000, 'labour_max' => 80000, 'materials_min' => 5000, 'materials_max' => 50000],
    ],
];