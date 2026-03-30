<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AgentFollowersController extends Controller
{
    /**
     * Get users who have saved this agent (followers)
     */
    public function index(Request $request)
    {
        $agent = $request->user();

        try {
            $followers = DB::table('saved_agents')
                ->join('cribs_users', 'saved_agents.user_id', '=', 'cribs_users.id')
                ->where('saved_agents.agent_id', $agent->agent_id)
                ->select(
                    'saved_agents.id as follower_id',
                    'saved_agents.created_at',
                    'cribs_users.id as user_pk',
                    'cribs_users.user_id as user_public_id',
                    'cribs_users.first_name',
                    'cribs_users.last_name',
                    'cribs_users.email',
                    'cribs_users.phone',
                    'cribs_users.profile_picture_url'
                )
                ->orderBy('saved_agents.created_at', 'desc')
                ->get();

            $formattedFollowers = $followers->map(function ($follower) {
                return [
                    'id' => $follower->follower_id,
                    'user_id' => $follower->user_public_id,
                    'created_at' => $follower->created_at,
                    'user' => [
                        'id' => $follower->user_pk,
                        'user_id' => $follower->user_public_id,
                        'first_name' => $follower->first_name,
                        'last_name' => $follower->last_name,
                        'email' => $follower->email,
                        'phone' => $follower->phone,
                        'profile_picture_url' => $follower->profile_picture_url,
                    ]
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $formattedFollowers
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch followers: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading your followers. Please try again later.'
            ], 500);
        }
    }
}
