<?php

namespace App\Http\Controllers\User;

use App\Models\Property;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Log;
class SavedPropertyController extends Controller
{
    /**
     * Get all saved properties for the authenticated user.
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $perPage = (int) $request->query('per_page', 20);

            $properties = $user->savedProperties()
                ->where('properties.status', 'Active')
                ->with([
                    'agent:id,agent_id,first_name,last_name,email,phone'
                ])
                ->orderByDesc('properties.created_at')
                ->paginate($perPage);

            Log::info('Saved properties fetched: ' . json_encode($properties->items()));

            return response()->json([
                'status' => 'success',
                'message' => 'Saved properties loaded successfully',
                'data' => $properties->items(),
                'pagination' => [
                    'total' => $properties->total(),
                    'per_page' => $properties->perPage(),
                    'current_page' => $properties->currentPage(),
                    'last_page' => $properties->lastPage(),
                ]
            ], 200);
        } catch (\Exception $e) {
            Log::error('Failed to fetch saved properties: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while fetching your saved properties. Please try again later.'
            ], 500);
        }
    }

    /**
     * Save a property for the authenticated user.
     */
    public function store(Request $request, $propertyId)
    {
        try {
            $property = Property::where('property_id', $propertyId)->firstOrFail();
            $user = $request->user();
            // Use syncWithoutDetaching to avoid duplicate entries
            $user->savedProperties()->syncWithoutDetaching([$property->property_id => ['agent_id' => $property->agent_id]]);

            return response()->json([
                'status' => 'success',
                'message' => 'Property saved successfully'
            ], 200);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json(['status' => 'error', 'message' => 'Property not found'], 404);
        } catch (\Exception $e) {
            Log::error('Failed to save property: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while saving this property. Please try again later.'
            ], 500);
        }
    }

    /**
     * Unsave a property for the authenticated user.
     */
    public function destroy(Request $request, $propertyId)
    {
        try {
            $property = Property::where('property_id', $propertyId)->firstOrFail();
            $user = $request->user();
            $user->savedProperties()->detach($property->property_id);

            return response()->json([
                'status' => 'success',
                'message' => 'Property unsaved successfully'
            ], 200);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json(['status' => 'error', 'message' => 'Property not found'], 404);
        } catch (\Exception $e) {
            Log::error('Failed to unsave property: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while unsaving this property. Please try again later.'
            ], 500);
        }
    }

    /**
     * Check if a property is saved by the authenticated user.
     */
    public function isSaved(Request $request, $propertyId)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return response()->json(['status' => 'error', 'message' => 'Unauthenticated'], 401);
            }

            $property = Property::where('property_id', $propertyId)->firstOrFail();
            $isSaved = $user->savedProperties()->where('properties.property_id', $property->property_id)->exists();

            return response()->json([
                'status' => 'success',
                'data' => ['is_saved' => $isSaved]
            ], 200);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json(['status' => 'error', 'message' => 'Property not found'], 404);
        } catch (\Exception $e) {
            Log::error('Failed to check property saved status: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while checking property saved status. Please try again later.'
            ], 500);
        }
    }
}