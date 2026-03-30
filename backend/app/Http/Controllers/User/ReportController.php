<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Agent;
use App\Models\AgentReport;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class ReportController extends Controller
{
    public function store(Request $request, $agentId)
    {
        try {
            $request->validate([
                'issue' => 'required|string|max:255',
                'details' => 'nullable|string',
            ]);

            $user = Auth::user();

            // Find the agent by agent_id (the actual primary key in cribs_agents table)
            $agent = Agent::where('agent_id', $agentId)->first();

            if (!$agent) {
                return response()->json(['message' => 'Agent not found'], 404);
            }

            $report = AgentReport::create([
                'user_id' => $user->id,
                'agent_id' => $agent->agent_id, // Use the string agent_id for consistency
                'issue' => $request->issue,
                'details' => $request->details,
            ]);

            return response()->json($report, 201);
        } catch (\Exception $e) {
            Log::error('Failed to submit report: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while submitting your report. Please try again later.'
            ], 500);
        }
    }
}
