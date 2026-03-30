<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Agent;
use App\Models\SavedAgent;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class PublicAgentController extends Controller
{
    /**
     * Find nearby agents using Haversine formula
     */
    public function findNearby(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'lat' => 'required|numeric',
            'lon' => 'required|numeric',
            'radius' => 'required|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => 'error', 'message' => 'Validation failed', 'errors' => $validator->errors()], 422);
        }

        $lat = (float) $request->lat;
        $lon = (float) $request->lon;
        $radius = (float) $request->radius;

        $cacheKey = "nearby_agents_{$lat}_{$lon}_{$radius}";
        $lockKey = "lock_{$cacheKey}";

        // Fast path: try to get from cache first
        $agents = Cache::get($cacheKey);

        if (!$agents) {
            // Atomic lock to prevent cache stampede (multiple requests hitting DB simultaneously)
            $lock = Cache::lock($lockKey, 10);

            try {
                // Determine if we acquired the lock, block for up to 5 seconds
                if ($lock->block(5)) {
                    // Check again just in case another process populated it while we waited
                    $agents = Cache::get($cacheKey);

                    if (!$agents) {
                        $agents = Agent::select('*')
                            ->selectRaw('( 6371 * acos( LEAST(1.0, GREATEST(-1.0, cos( radians(?) ) * cos( radians( CAST(latitude AS DECIMAL(10,8)) ) ) * cos( radians( CAST(longitude AS DECIMAL(10,8)) ) - radians(?) ) + sin( radians(?) ) * sin( radians( CAST(latitude AS DECIMAL(10,8)) ) ) ) ) ) ) AS distance', [$lat, $lon, $lat])
                            ->having('distance', '<', $radius)
                            ->orderBy('distance')
                            ->with('information')
                            ->limit(50)
                            ->get();

                        Cache::put($cacheKey, $agents, now()->addMinutes(3));
                    }
                } else {
                    return response()->json(['status' => 'error', 'message' => 'System is busy matching agents. Please try again gently.'], 429);
                }
            } finally {
                $lock?->release();
            }
        }

        return response()->json(['status' => 'success', 'message' => 'Nearby agents found', 'data' => ['count' => count($agents), 'agents' => $agents]]);
    }

    /**
     * Display the specified agent.
     */
    public function show($agentId)
    {
        // Always query by agent_id since that's the primary key in cribs_agents table
        $agent = Agent::where('agent_id', $agentId)
            ->with(['information', 'reviews'])
            ->first();

        if (!$agent) {
            return response()->json(['status' => 'error', 'message' => 'Agent not found'], 404);
        }

        return response()->json(['status' => 'success', 'message' => 'Agent retrieved successfully', 'data' => $agent]);
    }

    /**
     * Get all agents
     */
    public function index()
    {
        $agents = Cache::remember('all_agents', now()->addMinutes(10), function () {
            return Agent::with('information')->get();
        });

        return response()->json(['status' => 'success', 'message' => 'All agents retrieved', 'data' => ['count' => count($agents), 'agents' => $agents]]);
    }

    /**
     * Get saved agents for authenticated user (flattened fields)
     */
    public function getSavedAgents(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return response()->json(['status' => 'error', 'message' => 'Unauthenticated'], 401);
            }

            $savedAgentIds = DB::table('saved_agents')->where('user_id', $user->id)->pluck('agent_id');

            $agents = Agent::whereIn('agent_id', $savedAgentIds)
                ->with(['information', 'reviews'])
                ->get();

            return response()->json(['status' => 'success', 'message' => 'Saved agents retrieved successfully', 'data' => ['count' => $agents->count(), 'agents' => $agents]]);
        } catch (\Exception $e) {
            Log::error('Failed to load saved agents: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while loading your saved agents. Please try again later.'
            ], 500);
        }
    }

    /**
     * Save an agent for authenticated user
     */
    public function saveAgent(Request $request, $agentId)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 'error', 'message' => 'Unauthenticated'], 401);
        }

        $agent = Agent::where('agent_id', $agentId)->firstOrFail();

        $exists = SavedAgent::firstOrCreate([
            'user_id' => $user->id,
            'agent_id' => $agent->agent_id,
        ]);

        if (!$exists->wasRecentlyCreated) {
            return response()->json(['status' => 'error', 'message' => 'Agent already saved.'], 409);
        }

        return response()->json(['status' => 'success', 'message' => 'Agent saved successfully.']);
    }

    /**
     * Unsave an agent for authenticated user
     */
    public function unsaveAgent(Request $request, $agentId)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 'error', 'message' => 'Unauthenticated'], 401);
        }

        $agent = Agent::where('agent_id', $agentId)->firstOrFail();

        $deleted = SavedAgent::where('user_id', $user->id)
            ->where('agent_id', $agent->agent_id)
            ->delete();

        if (!$deleted) {
            return response()->json(['status' => 'error', 'message' => 'Agent not found in saved list.'], 404);
        }

        return response()->json(['status' => 'success', 'message' => 'Agent unsaved successfully.']);
    }

    public function recommended(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'radius' => 'nullable|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Validation failed', 'errors' => $validator->errors()], 422);
        }

        $lat = (float) $request->input('latitude');
        $lon = (float) $request->input('longitude');
        $radius = (float) $request->input('radius', 5.0); // km
        $limit = (int) $request->input('limit', 50);

        try {
            $agents = Agent::with(['information', 'reviews']) // Eager load information and reviews
                ->selectRaw('cribs_agents.*, ( 6371 * acos( LEAST(1.0, GREATEST(-1.0, cos( radians(?) ) * cos( radians( CAST(latitude AS DECIMAL(10,8)) ) ) * cos( radians( CAST(longitude AS DECIMAL(10,8)) ) - radians(?) ) + sin( radians(?) ) * sin( radians( CAST(latitude AS DECIMAL(10,8)) ) ) ) ) ) ) AS distance', [$lat, $lon, $lat])
                ->whereNotNull('latitude')
                ->whereNotNull('longitude')
                ->whereRaw('( 6371 * acos( LEAST(1.0, GREATEST(-1.0, cos( radians(?) ) * cos( radians( CAST(latitude AS DECIMAL(10,8)) ) ) * cos( radians( CAST(longitude AS DECIMAL(10,8)) ) - radians(?) ) + sin( radians(?) ) * sin( radians( CAST(latitude AS DECIMAL(10,8)) ) ) ) ) ) ) <= ?', [$lat, $lon, $lat, $lat, $lon, $lat, $radius])
                ->orderBy('distance')
                ->limit($limit)
                ->get();

            return response()->json(['data' => ['agents' => $agents]]);
        } catch (\Exception $e) {
            Log::error('Failed to load recommended agents: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while loading recommended agents. Please try again later.'
            ], 500);
        }
    }
}
