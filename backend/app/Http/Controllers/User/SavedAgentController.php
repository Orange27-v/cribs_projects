<?php

namespace App\Http\Controllers\User;

use App\Models\Agent;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SavedAgentController extends Controller
{
    /**
     * Get all saved agents for the authenticated user.
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $perPage = (int) $request->query('per_page', 20);

            // Manually query the saved agent IDs from the pivot table
            $savedAgentIds = DB::table('saved_agents')
                ->where('user_id', $user->id)
                ->pluck('agent_id');

            // Fetch the full agent models based on the retrieved IDs
            $agents = Agent::whereIn('agent_id', $savedAgentIds)
                ->with('information')
                ->paginate($perPage);

            return response()->json([
                'status' => 'success',
                'message' => 'Saved agents loaded successfully',
                'data' => $agents->items(),
                'pagination' => [
                    'total' => $agents->total(),
                    'per_page' => $agents->perPage(),
                    'current_page' => $agents->currentPage(),
                    'last_page' => $agents->lastPage(),
                ]
            ], 200);
        } catch (\Exception $e) {
            Log::error('Failed to fetch saved agents: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while fetching your saved agents. Please try again later.'
            ], 500);
        }
    }

    /**
     * Save an agent for the authenticated user.
     */
    public function store(Request $request, $agentId)
    {
        try {
            $agent = Agent::where('agent_id', $agentId)->firstOrFail();
            $user = $request->user();

            // Use syncWithoutDetaching to avoid duplicate entries
            $user->savedAgents()->syncWithoutDetaching([$agent->agent_id]);

            return response()->json([
                'status' => 'success',
                'message' => 'Agent saved successfully'
            ], 200);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json(['status' => 'error', 'message' => 'Agent not found'], 404);
        } catch (\Exception $e) {
            Log::error('Failed to save agent: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while saving this agent. Please try again later.'
            ], 500);
        }
    }

    /**
     * Unsave an agent for the authenticated user.
     */
    public function destroy(Request $request, $agentId)
    {
        try {
            $agent = Agent::where('agent_id', $agentId)->firstOrFail();
            $user = $request->user();
            $user->savedAgents()->detach($agent->agent_id);

            return response()->json([
                'status' => 'success',
                'message' => 'Agent unsaved successfully'
            ], 200);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json(['status' => 'error', 'message' => 'Agent not found'], 404);
        } catch (\Exception $e) {
            Log::error('Failed to unsave agent: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while unsaving this agent. Please try again later.'
            ], 500);
        }
    }

    /**
     * Check if an agent is saved by the authenticated user.
     */
    public function isSaved(Request $request, $agentId)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return response()->json(['status' => 'error', 'message' => 'Unauthenticated'], 401);
            }

            // Check if the agent exists first to prevent checking for non-existent agents
            $agentExists = Agent::where('agent_id', $agentId)->exists();
            if (!$agentExists) {
                return response()->json(['status' => 'error', 'message' => 'Agent not found'], 404);
            }

            // Manually check the pivot table for the saved record
            $isSaved = DB::table('saved_agents')
                ->where('user_id', $user->id)
                ->where('agent_id', $agentId)
                ->exists();

            return response()->json([
                'status' => 'success',
                'data' => ['is_saved' => $isSaved]
            ], 200);
        } catch (\Exception $e) {
            Log::error('Failed to check saved status: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while checking agent saved status. Please try again later.'
            ], 500);
        }
    }
}