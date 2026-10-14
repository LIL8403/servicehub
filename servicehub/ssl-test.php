<?php

$apiKey = 'AIzaSyCmJOyjkVw6sAgNzepY33Tu39Ruvhz4eYg';
$url = 'https://generativelanguage.googleapis.com/v1beta/models?key=' . $apiKey;

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);

$result = curl_exec($ch);

if (curl_errno($ch)) {
    echo 'ERROR: ' . curl_error($ch) . PHP_EOL;
} else {
    echo 'SUCCESS: ' . substr($result, 0, 300) . PHP_EOL;
}

curl_close($ch);