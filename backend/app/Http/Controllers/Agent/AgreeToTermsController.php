<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class AgreeToTermsController extends Controller
{
    public function agreeToTerms(Request $request)
    {
        try {
            $request->validate([
                'version' => 'required|string|max:20',
            ]);

            $agent = $request->user();
            $agent->agreed_to_terms_version = $request->version;
            $agent->save();

            return response()->json([
                'success' => true,
                'status' => 'success',
                'message' => 'Agent agreement recorded successfully.',
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to record agent agreement: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while recording your agreement. Please try again later.'
            ], 500);
        }
    }
}
