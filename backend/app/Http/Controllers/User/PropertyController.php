<?php

namespace App\Http\Controllers\User;

use Illuminate\Http\Request;
use App\Models\Property;
use App\Models\Agent;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use App\Http\Controllers\Controller;

class PropertyController extends Controller
{
    /**
     * List all properties with pagination
     * Optional query parameter: ?per_page=20
     */
    public function index(Request $request)
    {
        try {
            $perPage = (int) $request->query('per_page', 20);

            // Optimized: Use select to load only needed columns if available
            $properties = Property::with(['agent.information'])
                ->orderBy('created_at', 'desc')
                ->paginate($perPage);

            return response()->json([
                'status' => 'success',
                'message' => 'Properties loaded successfully',
                'data' => $properties->items(),
                'pagination' => [
                    'total' => $properties->total(),
                    'per_page' => $properties->perPage(),
                    'current_page' => $properties->currentPage(),
                    'last_page' => $properties->lastPage(),
                ]
            ], 200);
        } catch (\Exception $e) {
            Log::error('Failed to load properties: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while loading properties. Please try again later.'
            ], 500);
        }
    }

    /**
     * Display the specified property.
     */
    public function show($propertyId)
    {
        try {
            $property = Property::with(['agent.information'])
                ->where('id', $propertyId)
                ->firstOrFail();

            return response()->json([
                'status' => 'success',
                'message' => 'Property loaded successfully',
                'data' => $property
            ], 200);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Property not found'
            ], 404);
        } catch (\Exception $e) {
            Log::error('Failed to load property: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while loading property details. Please try again later.'
            ], 500);
        }
    }

    /**
     * Get properties by a specific agent ID with pagination
     */
    public function getPropertiesByAgent(Request $request, $agentId)
    {
        try {
            $perPage = (int) $request->query('per_page', 20);

            // OPTIMIZATION: Add eager loading with column selection
            $properties = Property::where('agent_id', $agentId)
                ->where('status', 'Active')
                ->orderByDesc('created_at')
                ->with(['agent.information'])
                ->paginate($perPage);

            return response()->json([
                'status' => 'success',
                'message' => 'Properties loaded successfully for agent',
                'data' => $properties->items(),
                'pagination' => [
                    'total' => $properties->total(),
                    'per_page' => $properties->perPage(),
                    'current_page' => $properties->currentPage(),
                    'last_page' => $properties->lastPage(),
                ]
            ], 200);
        } catch (\Exception $e) {
            Log::error('Failed to fetch properties for agent: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while fetching properties for this agent. Please try again later.'
            ], 500);
        }
    }

    /**
     * Get new properties by a specific agent ID
     * FIX: Added pagination support for consistency
     */
    public function getNewPropertiesByAgent(Request $request, $agentId)
    {
        try {
            // ADDED: Pagination support
            $limit = (int) $request->query('limit', 10);

            // OPTIMIZATION: Add eager loading with column selection
            $properties = Property::where('agent_id', $agentId)
                ->where('status', 'Active')
                ->orderByDesc('created_at')
                ->with(['agent.information'])
                ->limit($limit)
                ->get();

            return response()->json([
                'status' => 'success',
                'message' => 'New properties fetched successfully',
                'data' => $properties
            ], 200);
        } catch (\Exception $e) {
            Log::error('Failed to fetch new properties: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while fetching newest properties. Please try again later.'
            ], 500);
        }
    }
}
