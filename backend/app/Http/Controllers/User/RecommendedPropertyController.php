<?php

namespace App\Http\Controllers\User;

use Illuminate\Http\Request;
use App\Models\Property;
use App\Models\Agent;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use App\Http\Controllers\BaseController;


class RecommendedPropertyController extends BaseController
{
    /**
     * Get recommended properties based on user location
     * 
     * Returns properties sorted by distance from user's location
     */
    public function __invoke(Request $request)
    {
        try {
            $validator = Validator::make($request->query(), [
                'latitude' => 'required|numeric',
                'longitude' => 'required|numeric',
                'radius' => 'nullable|numeric|min:1|max:200',
                'limit' => 'nullable|integer|min:1|max:100',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid parameters',
                    'errors' => $validator->errors()
                ], 400);
            }

            $latitude = (float) $request->query('latitude');
            $longitude = (float) $request->query('longitude');
            $radius = (float) $request->query('radius', 50); // Default 50km
            $limit = (int) $request->query('limit', 20); // Default 20 properties

            // Earth's radius in kilometers
            $earthRadius = 6371;
            $tableName = 'properties';

            // Haversine formula for distance calculation using PROPERTY location
            $haversine = "($earthRadius * acos(cos(radians(?)) * cos(radians($tableName.latitude)) * cos(radians($tableName.longitude) - radians(?)) + sin(radians(?)) * sin(radians($tableName.latitude))))";

            // Fetch properties directly from properties table
            $properties = Property::selectRaw("$tableName.*, {$haversine} AS distance_km", [$latitude, $longitude, $latitude])
                ->where('status', 'Active')
                ->having('distance_km', '<=', $radius)
                ->with([
                    'agent:id,agent_id,first_name,last_name,email,phone,latitude,longitude',
                    'agent.information'
                ])
                ->orderBy('distance_km', 'asc')
                ->limit($limit)
                ->get();

            return response()->json([
                'status' => 'success',
                'message' => $properties->count() > 0
                    ? $properties->count() . ' properties found within ' . $radius . 'km'
                    : 'No properties found within ' . $radius . 'km',
                'data' => $properties,
                'meta' => [
                    'radius_km' => $radius,
                    'center' => [
                        'latitude' => $latitude,
                        'longitude' => $longitude,
                    ],
                    'count' => $properties->count(),
                ]
            ], 200);


        } catch (\Exception $e) {
            Log::error('Failed to load recommended properties: ' . $e->getMessage(), [
                'exception' => $e,
                'trace' => $e->getTraceAsString(),
                'latitude' => $latitude ?? 'N/A',
                'longitude' => $longitude ?? 'N/A',
            ]);
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while loading recommended properties. Please try again later.'
            ], 500);
        }
    }
}
