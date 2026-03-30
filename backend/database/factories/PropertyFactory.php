<?php

namespace Database\Factories;

use App\Models\Property;
use App\Models\Agent;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class PropertyFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var string
     */
    protected $model = Property::class;

    /**
     * Define the model's default state.
     *
     * @return array
     */
    public function definition()
    {
        return [
            'property_id' => $this->faker->unique()->randomNumber(4),
            'agent_id' => \App\Models\Agent::factory(), // Automatically create an agent
            'title' => $this->faker->sentence(4),
            'type' => $this->faker->randomElement(['Apartment', 'House', 'Condo', 'Villa', 'Terrace', 'Bungalow']),
            'location' => $this->faker->city,
            'listing_type' => $this->faker->randomElement(['For Sale', 'For Rent']),
            'price' => $this->faker->numberBetween(1000000, 500000000),
            'beds' => $this->faker->numberBetween(1, 5),
            'baths' => $this->faker->numberBetween(1, 5),
            'sqft' => $this->faker->numberBetween(500, 5000),
            'description' => $this->faker->paragraph,
            'address' => $this->faker->address,
            'inspection_fee' => $this->faker->numberBetween(1000, 50000),
            'status' => 'Active',
            'images' => json_encode(['property_images/property_image_1.jpg', 'property_images/property_image_2.jpg']),
            'is_featured' => $this->faker->boolean,
            'is_verified' => $this->faker->boolean,
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}
