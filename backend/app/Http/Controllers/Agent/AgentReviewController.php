<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use App\Models\AgentReview;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AgentReviewController extends Controller
{
    /**
     * Get all reviews for the authenticated agent.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getMyReviews(Request $request)
    {
        $agent = $request->user();
        $agentId = $agent->agent_id; // Use agent_id (6-digit ID), not id

        try {
            // Get reviews with user information
            $reviews = DB::table('agent_reviews')
                ->where('agent_reviews.agent_id', $agentId)
                ->join('cribs_users', 'agent_reviews.user_id', '=', 'cribs_users.user_id')
                ->select(
                    'agent_reviews.id',
                    'agent_reviews.rating',
                    'agent_reviews.review_text',
                    'agent_reviews.created_at',
                    'cribs_users.first_name',
                    'cribs_users.last_name',
                    'cribs_users.profile_picture_url'
                )
                ->orderBy('agent_reviews.created_at', 'desc')
                ->get();

            // Get rating breakdown
            $ratingBreakdown = DB::table('agent_reviews')
                ->where('agent_id', $agentId)
                ->whereNotNull('rating')
                ->selectRaw('rating, COUNT(*) as count')
                ->groupBy('rating')
                ->pluck('count', 'rating')
                ->toArray();

            // Get agent info for header (includes profile_picture_url)
            $agentInfo = DB::table('agent_information')
                ->where('agent_id', $agentId)
                ->select('average_rating', 'total_reviews', 'profile_picture_url')
                ->first();

            // Get agent profile
            $agentProfile = DB::table('cribs_agents')
                ->where('agent_id', $agentId)
                ->select('first_name', 'last_name', 'area')
                ->first();

            return response()->json([
                'status' => 'success',
                'data' => [
                    'reviews' => $reviews->map(function ($review) {
                        return [
                            'id' => $review->id,
                            'reviewer_name' => trim($review->first_name . ' ' . $review->last_name),
                            'reviewer_image' => $review->profile_picture_url,
                            'review_text' => $review->review_text,
                            'rating' => $review->rating,
                            'created_at' => $review->created_at,
                        ];
                    }),
                    'rating_breakdown' => [
                        '5' => $ratingBreakdown[5] ?? 0,
                        '4' => $ratingBreakdown[4] ?? 0,
                        '3' => $ratingBreakdown[3] ?? 0,
                        '2' => $ratingBreakdown[2] ?? 0,
                        '1' => $ratingBreakdown[1] ?? 0,
                    ],
                    'average_rating' => $agentInfo ? ($agentInfo->average_rating ?? '0.0') : '0.0',
                    'total_reviews' => $agentInfo ? ($agentInfo->total_reviews ?? 0) : 0,
                    'agent_name' => $agentProfile ? trim(($agentProfile->first_name ?? '') . ' ' . ($agentProfile->last_name ?? '')) : '',
                    'agent_image' => $agentInfo ? $agentInfo->profile_picture_url : null,
                    'agent_location' => $agentProfile ? ($agentProfile->area ?? '') : '',
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch reviews: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while loading your reviews. Please try again later.'
            ], 500);
        }
    }
}
