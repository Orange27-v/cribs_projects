<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AgentStatsController extends Controller
{
    /**
     * Get dashboard statistics for the authenticated agent.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getStats(Request $request)
    {
        $agent = $request->user();
        $agentId = $agent->agent_id;

        try {
            // Get rating and sales from agent_information table
            $agentInfo = DB::table('agent_information')
                ->where('agent_id', $agentId)
                ->select('average_rating', 'total_reviews', 'total_sales')
                ->first();

            $averageRating = $agentInfo->average_rating ?? '0.0';
            $totalReviews = $agentInfo->total_reviews ?? 0;

            // Calculate Closed Deals: Count of completed inspections
            $closedDeals = DB::table('inspections')
                ->where('agent_id', $agentId)
                ->where('status', 'completed')
                ->count();

            // Count clients (unique users who have inspections with this agent)
            $totalClients = DB::table('inspections')
                ->where('agent_id', $agentId)
                ->distinct('user_id')
                ->count('user_id');

            // Count listings from properties table
            $totalListings = DB::table('properties')
                ->where('agent_id', $agentId)
                ->count();

            // Count leads from saved_properties table
            $totalLeads = DB::table('saved_properties')
                ->where('agent_id', $agentId)
                ->count();

            // Count appointments from inspections table
            $totalAppointments = DB::table('inspections')
                ->where('agent_id', $agentId)
                ->count();

            return response()->json([
                'status' => 'success',
                'data' => [
                    'average_rating' => number_format((float) $averageRating, 1),
                    'total_reviews' => (int) $totalReviews,
                    'closed_deals' => (int) $closedDeals,
                    'total_clients' => (int) $totalClients,
                    'total_listings' => (int) $totalListings,
                    'total_leads' => (int) $totalLeads,
                    'total_appointments' => (int) $totalAppointments,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch agent statistics: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while loading your statistics. Please try again later.'
            ], 500);
        }
    }
}
