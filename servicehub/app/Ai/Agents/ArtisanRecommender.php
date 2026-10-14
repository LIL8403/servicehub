<?php

namespace App\Ai\Agents;

use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Attributes\Model;
use Laravel\Ai\Attributes\Provider;
use Laravel\Ai\Attributes\Timeout;
use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Contracts\HasStructuredOutput;
use Laravel\Ai\Enums\Lab;
use Laravel\Ai\Promptable;

#[Provider(Lab::Gemini)]
#[Model('gemini-3.5-flash-lite')]
#[Timeout(30)]
class ArtisanRecommender implements Agent, HasStructuredOutput
{
    use Promptable;

    /**
     * Get the instructions that the agent should follow.
     */
    public function instructions(): string
    {
        return 'Rank only the supplied verified artisans for the supplied service request. Recommendations are advisory: never assign an artisan. Use only service fit, stated service areas, availability, and professional experience. Do not infer protected characteristics.';
    }

    /**
     * Get the agent's structured output schema definition.
     */
    public function schema(JsonSchema $schema): array
    {
        return [
            'recommendations' => $schema->array()->items($schema->object(fn (JsonSchema $item) => [
                'artisan_id' => $item->string()->required(),
                'reason' => $item->string()->required(),
                'confidence_score' => $item->integer()->min(0)->max(100)->required(),
            ]))->required(),
        ];
    }
}
