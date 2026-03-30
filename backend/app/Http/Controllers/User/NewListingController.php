<?php

namespace App\Http\Controllers\User;

use Illuminate\Http\Request;
use App\Models\Property;
use App\Models\Agent;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use App\Http\Controllers\BaseController;

class NewListingController extends BaseController
{
    /**
     * Get new properties from agents near a specific location
     */
    public function __invoke(Request $request)
    {
        try {
            $validator = Validator::make($request->query(), [
                'latitude' => 'required|numeric',
                'longitude' => 'required|numeric',
                'radius' => 'nullable|numeric',
                'agent_limit' => 'nullable|integer',
                'property_limit' => 'nullable|integer',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid parameters',
                    'errors' => $validator->errors()
                ], 400);
            }

            // Fetch new properties nearby directly using the helper
            $properties = $this->_getNearby($request, Property::class, false);

            if ($properties->isEmpty()) {
                return response()->json([
                    'status' => 'success',
                    'message' => 'No new listings found near you within the requested radius',
                    'data' => []
                ], 200);
            }

            // Filter by date (last 3 months) and ensure limit is respected
            $propertyLimit = (int) $request->query('property_limit', 20);
            $properties = $properties->where('created_at', '>=', now()->subMonths(3))
                ->take($propertyLimit)
                ->values();


            return response()->json([
                'status' => 'success',
                'message' => $properties->isEmpty() ? 'No new listings found from nearby agents' : 'New listings loaded successfully',
                'data' => $properties
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to load new listings: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while loading new listings. Please try again later.'
            ], 500);
        }
    }
}
