<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use App\Models\Agent; // Assuming CribsAgent is the model for cribs_agents table
use App\Models\Property;
use App\Models\Transaction;
use App\Models\Inspection;
use Mockery;

class BookingFinalizationTest extends TestCase
{
    use RefreshDatabase; // Resets the database for each test

    protected function setUp(): void
    {
        parent::setUp();

        // Mock the PaystackController to control its behavior during tests
        $this->mock(
            \App\Http\Controllers\User\PaystackController::class,
            function ($mock) {
                $mock->shouldReceive('verifyTransaction')
                    ->andReturn([
                        'status' => true,
                        'message' => 'Verification successful',
                        'data' => [
                            'amount' => 500000, // 5000.00 NGN
                            'currency' => 'NGN',
                            'reference' => 'cribs_arena_test_ref',
                            'channel' => 'card',
                            'status' => 'success',
                            'customer' => [
                                'email' => 'test@example.com',
                            ],
                        ],
                    ]);
            }
        );
    }

    public function test_booking_finalization_creates_records_on_success()
    {
        // Create a test user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => bcrypt('password'),
        ]);

        // Create a test agent (using CribsAgent model)
        $agent = Agent::factory()->create([
            'agent_id' => 900001, // Use the agent_id as per the database schema
        ]);

        // Create a test property
        $property = Property::factory()->create([
            'agent_id' => $agent->id, // Link to the primary ID of the agent
        ]);

        // Simulate authentication
        $this->actingAs($user);

        $response = $this->postJson('/api/user/bookings/finalize', [
            'agent_id' => $agent->agent_id, // Send the agent_id that the frontend would send
            'property_id' => $property->id,
            'paystack_reference' => 'cribs_arena_test_ref',
            'inspection_date' => '2025-12-01',
            'inspection_time' => '10:00',
            'amount' => 5000.00,
            'payment_method' => 'card',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'message' => 'Booking finalized successfully.',
            ]);

        // Assert that a transaction record was created
        $this->assertDatabaseHas('transactions', [
            'payer_id' => $user->id,
            'payee_id' => $agent->id, // Should be the primary ID of the agent
            'amount' => 5000.00,
            'currency' => 'NGN',
            'payment_reference' => 'cribs_arena_test_ref',
            'gateway' => 'paystack',
            'channel' => 'card',
            'status' => 'success',
        ]);

        // Assert that an inspection record was created
        $this->assertDatabaseHas('inspections', [
            'user_id' => $user->id,
            'agent_id' => $agent->id, // Should be the primary ID of the agent
            'property_id' => $property->id,
            'inspection_date' => '2025-12-01',
            'inspection_time' => '10:00:00',
            'status' => 'scheduled',
            'amount' => 5000.00,
            'payment_status' => 'paid',
            'payment_method' => 'card',
        ]);
    }
}
