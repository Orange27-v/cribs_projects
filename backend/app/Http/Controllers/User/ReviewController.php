<?php

namespace App\Http\Controllers\User;

use App\Models\Agent;
use App\Models\AgentReview;
use App\Models\AgentReport;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use App\Http\Controllers\Controller;

class ReviewController extends Controller
{
    public function storeReview(Request $request, $agentId)
    {
        $validator = Validator::make($request->all(), [
            'rating' => 'nullable|integer|min:1|max:5',
            'review_text' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        try {
            $user = Auth::user();
            $agent = Agent::where('id', $agentId)->orWhere('agent_id', $agentId)->first();

            if (!$agent) {
                return response()->json(['message' => 'Agent not found.'], 404);
            }

            $review = DB::transaction(function () use ($request, $user, $agent) {
                $review = AgentReview::create([
                    'user_id' => $user->user_id,
                    'agent_id' => $agent->agent_id,
                    'rating' => $request->rating,
                    'review_text' => $request->review_text,
                ]);

                // Update total_reviews count in agent_information table
                DB::table('agent_information')
                    ->where('agent_id', $agent->agent_id)
                    ->increment('total_reviews');

                // Calculate and update average_rating only if a rating was provided
                if ($request->rating !== null) {
                    $averageRating = AgentReview::where('agent_id', $agent->agent_id)
                        ->whereNotNull('rating')
                        ->avg('rating');

                    DB::table('agent_information')
                        ->where('agent_id', $agent->agent_id)
                        ->update(['average_rating' => round($averageRating, 1)]);
                }

                return $review;
            });

            return response()->json($review, 201);
        } catch (\Exception $e) {
            Log::error('Failed to store review: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while submitting your review. Please try again later.'
            ], 500);
        }
    }

    public function storeReport(Request $request, $agentId)
    {
        $validator = Validator::make($request->all(), [
            'issue' => 'required|string|max:255',
            'details' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        try {
            $user = Auth::user();
            $agent = Agent::where('id', $agentId)->orWhere('agent_id', $agentId)->first();

            if (!$agent) {
                return response()->json(['message' => 'Agent not found.'], 404);
            }

            $report = AgentReport::create([
                'user_id' => $user->user_id,
                'agent_id' => $agent->agent_id,
                'issue' => $request->issue,
                'details' => $request->details,
                'status' => 'pending',
            ]);

            return response()->json($report, 201);
        } catch (\Exception $e) {
            Log::error('Failed to store report: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while submitting your report. Please try again later.'
            ], 500);
        }
    }

    public function getAgentReviews($agentId)
    {
        try {
            $agent = Agent::where('id', $agentId)->orWhere('agent_id', $agentId)->first();

            if (!$agent) {
                return response()->json(['message' => 'Agent not found.'], 404);
            }
            $reviews = AgentReview::where('agent_id', $agent->agent_id)
                ->with('user') // Eager load user to get user's name and photo
                ->latest()
                ->get();

            if ($reviews->isEmpty()) {
                return response()->json([], 200); // Changed 404 to 200 as empty reviews is not an error
            }

            return response()->json($reviews);
        } catch (\Exception $e) {
            Log::error('Failed to get agent reviews: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while loading reviews. Please try again later.'
            ], 500);
        }
    }
}
