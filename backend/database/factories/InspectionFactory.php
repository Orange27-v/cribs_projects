<?php

namespace Database\Factories;

use App\Models\Inspection;
use App\Models\User;
use App\Models\Agent;
use App\Models\Property;
use App\Models\Transaction;
use Illuminate\Database\Eloquent\Factories\Factory;

class InspectionFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var string
     */
    protected $model = Inspection::class;

    /**
     * Define the model's default state.
     *
     * @return array
     */
    public function definition()
    {
        return [
            'user_id' => User::factory(),
            'agent_id' => Agent::factory(),
            'property_id' => Property::factory(),
            'transaction_id' => Transaction::factory(),
            'inspection_date' => $this->faker->date(),
            'inspection_time' => $this->faker->time(),
            'status' => $this->faker->randomElement(['scheduled', 'rescheduled', 'confirmed', 'completed', 'cancelled', 'no_show']),
            'reason_cancellation' => $this->faker->optional()->sentence(),
            'amount' => $this->faker->randomFloat(2, 1000, 50000),
            'payment_status' => $this->faker->randomElement(['pending', 'paid', 'refunded']),
            'payment_method' => $this->faker->randomElement(['card', 'bank_transfer']),
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}
