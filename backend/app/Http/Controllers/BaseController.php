<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use App\Models\Agent;
use App\Models\Property;

class BaseController extends Controller
{
    /**
     * Private helper function to get nearby items (properties or agents)
     * @param Request $request - The HTTP request with location parameters
     * @param string $modelClass - The model class (Property::class or Agent::class)
     * @param bool $jsonResponse - Whether to return JSON response or collection
     */
    protected function _getNearby(Request $request, $modelClass, $jsonResponse = true)
    {
        try {
            $validator = Validator::make($request->query(), [
                'latitude' => 'required|numeric',
                'longitude' => 'required|numeric',
                'radius' => 'nullable|numeric',
                'limit' => 'nullable|integer',
            ]);

            if ($validator->fails()) {
                $response = response()->json([
                    'status' => 'error',
                    'message' => 'Invalid parameters',
                    'errors' => $validator->errors()
                ], 400);
                return $jsonResponse ? $response : collect();
            }

            $latitude = (float) $request->query('latitude');
            $longitude = (float) $request->query('longitude');

            $isAgent = $modelClass === Agent::class;
            $tableName = (new $modelClass)->getTable();

            // Reasonable defaults: 20km for agents (city range), 50km for properties (wider search)
            $defaultRadius = $isAgent ? 20 : 50;
            $defaultLimit = $isAgent ? 8 : 20;

            $radius = (float) $request->query('radius', $defaultRadius);
            $limit = (int) $request->query('limit', $defaultLimit);

            // Earth's radius in kilometers
            $earthRadius = 6371;

            // Haversine formula for distance calculation
            $haversine = "($earthRadius * acos(cos(radians(?)) * cos(radians($tableName.latitude)) * cos(radians($tableName.longitude) - radians(?)) + sin(radians(?)) * sin(radians($tableName.latitude))))";

            $query = $modelClass::selectRaw("{$tableName}.*, {$haversine} AS distance", [$latitude, $longitude, $latitude])
                ->having('distance', '<=', $radius)
                ->orderBy('distance', 'asc')
                ->limit($limit);

            // OPTIMIZATION: Add eager loading for properties
            if (!$isAgent) {
                $query->where('status', 'Active')
                    ->with([
                        'agent:id,agent_id,first_name,last_name,email,phone,latitude,longitude',
                        'agent.information'
                    ]);
            }

            $items = $query->get();

            if (!$jsonResponse) {
                return $items;
            }

            $modelName = $isAgent ? 'agents' : 'properties';

            return response()->json([
                'status' => 'success',
                'message' => $items->isEmpty() ? "No nearby {$modelName} found" : "Nearby {$modelName} fetched successfully",
                'data' => $items
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to fetch nearby items: ' . $e->getMessage());
            $response = response()->json([
                'status' => 'error',
                'message' => 'An error occurred while searching for nearby items. Please try again later.'
            ], 500);
            return $jsonResponse ? $response : collect();
        }
    }
}
