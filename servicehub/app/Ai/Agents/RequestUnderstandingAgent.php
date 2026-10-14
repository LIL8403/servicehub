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
#[Timeout(60)]
class RequestUnderstandingAgent implements Agent, HasStructuredOutput
{
    use Promptable;

    public function instructions(): string
    {
        return <<<'TXT'
Summarize the supplied service request and provide a clearer, more actionable rewrite of the customer's description.

The rewritten_description MUST:
- Be written in the first person ("I have...", "My...", "Please..."), as if the customer wrote it themselves.
- Preserve the customer's intent, facts, and scope exactly. Do NOT invent details, causes, diagnoses, or prices.
- Be concise and direct: 1–3 sentences. Artisans should know what is needed and where.
- Never address the customer in third person ("The customer reports..."). This is the customer's own voice.

Also identify:
- the likely problem type,
- the urgency level,
- useful context already provided,
- useful information still missing.

This output is advisory only and must not change the service or request state.
TXT;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'problem_type'          => $schema->string()->required(),
            'urgency'               => $schema->string()->enum(['low', 'normal', 'high', 'emergency'])->required(),
            'rewritten_description' => $schema->string()->required(),
            'useful_context'        => $schema->array()->items($schema->string())->required(),
            'missing_information'   => $schema->array()->items($schema->string())->required(),
            'confidence_score'      => $schema->integer()->min(0)->max(100)->required(),
        ];
    }
}
