<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\User>
 */
class UserFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var string
     */
    protected $model = User::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition()
    {
        return [
            'user_id' => $this->faker->unique()->randomNumber(6), // Will be overwritten by model's creating event
            'first_name' => $this->faker->firstName,
            'last_name' => $this->faker->lastName,
            'email' => $this->faker->unique()->safeEmail(),
            'phone' => $this->faker->unique()->phoneNumber,
            'email_verified_at' => now(),
            'password' => '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
            'profile_picture_url' => $this->faker->imageUrl(),
            'nin_verification' => $this->faker->numberBetween(0, 1),
            'bvn_verification' => $this->faker->numberBetween(0, 1),
            'area' => $this->faker->city,
            'latitude' => $this->faker->latitude,
            'longitude' => $this->faker->longitude,
            'login_status' => $this->faker->boolean,
            'last_login' => $this->faker->dateTimeThisMonth(),
            'last_logout' => $this->faker->dateTimeThisMonth(),
            'remember_token' => Str::random(10),
            'agreed_to_terms_version' => '1.0',
            'notif_push_notifications' => $this->faker->boolean,
            'notif_new_messages' => $this->faker->boolean,
            'notif_new_listings' => $this->faker->boolean,
            'notif_price_changes' => $this->faker->boolean,
            'notif_app_updates' => $this->faker->boolean,
        ];
    }

    /**
     * Indicate that the model's email address should be unverified.
     *
     * @return static
     */
    public function unverified()
    {
        return $this->state(fn(array $attributes) => [
            'email_verified_at' => null,
        ]);
    }
}
