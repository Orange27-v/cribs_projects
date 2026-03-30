<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Inspection;
use App\Models\User;
use Illuminate\Support\Facades\Log;

class AgentClientController extends Controller
{
    /**
     * Get list of clients who have completed inspections with the agent.
     */
    public function getClients(Request $request)
    {
        try {
            $agent = $request->user();

            // Ensure we use the 6-digit agent_id
            $agentId = $agent->agent_id;

            // Get user_ids of users who have inspections with this agent.
            // We use distinct to avoid duplicates if a client has multiple inspections.
            $clientUserIds = Inspection::where('agent_id', $agentId)
                ->distinct()
                ->pluck('user_id');

            if ($clientUserIds->isEmpty()) {
                return response()->json([
                    'status' => 'success',
                    'data' => []
                ]);
            }

            // Fetch user details from the User model (cribs_users table)
            // matching the 6-digit user_id
            $clients = User::whereIn('user_id', $clientUserIds)
                ->select([
                    'id',
                    'user_id',
                    'first_name',
                    'last_name',
                    'email',
                    'phone',
                    'profile_picture_url',
                    'created_at',
                    'area',
                ])
                ->get()
                ->map(function ($client) use ($agentId) {
                    // Get the most recent inspection status for this client with this agent
                    $latestInspection = Inspection::where('agent_id', $agentId)
                        ->where('user_id', $client->user_id)
                        ->orderBy('created_at', 'desc')
                        ->first();

                    $client->inspection_status = $latestInspection ? $latestInspection->status : null;
                    $client->inspection_date = $latestInspection ? $latestInspection->inspection_date : null;

                    return $client;
                });

            return response()->json([
                'status' => 'success',
                'data' => $clients
            ]);

        } catch (\Exception $e) {
            Log::error("Error fetching agent clients: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while loading your clients. Please try again later.'
            ], 500);
        }
    }
}
