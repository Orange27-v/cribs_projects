<?php

namespace Database\Factories;

use App\Models\Transaction;
use App\Models\User;
use App\Models\Agent;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class TransactionFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var string
     */
    protected $model = Transaction::class;

    /**
     * Define the model's default state.
     *
     * @return array
     */
    public function definition()
    {
        return [
            'payer_id' => User::factory(),
            'payee_id' => Agent::factory(),
            'amount' => $this->faker->randomFloat(2, 1000, 100000),
            'currency' => 'NGN',
            'payment_reference' => 'TRX-' . Str::random(10),
            'gateway' => 'paystack',
            'channel' => $this->faker->randomElement(['card', 'bank_transfer', 'ussd']),
            'status' => $this->faker->randomElement(['success', 'failed', 'pending']),
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}
