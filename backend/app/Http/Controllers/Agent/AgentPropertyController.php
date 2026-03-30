<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use App\Models\Property;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class AgentPropertyController extends Controller
{
    /**
     * Get all properties for the authenticated agent
     */
    public function index(Request $request)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $query = Property::where('agent_id', $agent->agent_id);

            // Filter by status if provided
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filter by listing type if provided
            if ($request->has('listing_type')) {
                $query->where('listing_type', $request->listing_type);
            }

            // Paginate results
            $perPage = $request->get('per_page', 20);
            $properties = $query->orderBy('created_at', 'desc')
                ->paginate($perPage);

            return response()->json([
                'success' => true,
                'properties' => $properties
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to fetch properties: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading your properties. Please try again later.'
            ], 500);
        }
    }

    /**
     * Get a single property by ID
     */
    public function show($propertyId)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $property = Property::where('property_id', $propertyId)
                ->where('agent_id', $agent->agent_id)
                ->first();

            if (!$property) {
                return response()->json([
                    'success' => false,
                    'message' => 'Property not found or you do not have permission to view it'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'property' => $property
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to fetch property: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading the property details. Please try again later.'
            ], 500);
        }
    }

    /**
     * Add a new property
     */
    public function store(Request $request)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Validation rules
            $validator = Validator::make($request->all(), [
                'title' => 'required|string|max:255',
                'type' => 'required|string|max:50',
                'location' => 'required|string|max:255',
                'listing_type' => 'required|in:For Sale,For Rent,Sold,Rented',
                'price' => 'required|numeric|min:0',
                'beds' => 'required|integer|min:0',
                'baths' => 'required|integer|min:0',
                'sqft' => 'required|string',
                'description' => 'nullable|string',
                'address' => 'nullable|string',
                'latitude' => 'nullable|numeric|between:-90,90',
                'longitude' => 'nullable|numeric|between:-180,180',
                'images.*' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:5120', // max 5MB per image
                'amenities' => 'nullable|json',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $lockKey = 'property_upload_' . $agent->agent_id;
            $lock = Cache::lock($lockKey, 30);

            if (!$lock->get()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Your previous property is still uploading. Please wait a moment.'
                ], 429);
            }

            try {
                // Generate unique property ID
                $propertyId = $this->generatePropertyId();

                // Create property
                $property = new Property();
                $property->property_id = $propertyId;
                $property->agent_id = $agent->agent_id;
                $property->title = $request->title;
                $property->type = $request->type;
                $property->location = $request->location;
                $property->listing_type = $request->listing_type;
                $property->price = $request->price;
                $property->beds = $request->beds;
                $property->baths = $request->baths;
                $property->sqft = $request->sqft;
                $property->description = $request->description;
                $property->address = $request->address;
                $property->latitude = $request->latitude;
                $property->longitude = $request->longitude;
                $property->status = 'Active'; // Default status
                $property->is_featured = 0; // Default to not featured
                $property->is_verified = 0; // Default to not verified
                $property->inspection_fee = 0; // Default to 0 since agents cannot set this
                $property->amenities = $request->amenities;

                // Check subscription status and upload limits
                $subscription = \Illuminate\Support\Facades\DB::table('paid_subscribers')
                    ->join('agent_plans', 'paid_subscribers.plan_id', '=', 'agent_plans.plan_id')
                    ->where('paid_subscribers.agent_id', $agent->agent_id)
                    ->where('paid_subscribers.status', 'Active')
                    ->where('paid_subscribers.end_date', '>', now())
                    ->select(
                        'paid_subscribers.subscription_id',
                        'paid_subscribers.upload_count',
                        'agent_plans.property_limit',
                        'agent_plans.name as plan_name'
                    )
                    ->first();

                // No active subscription found
                if (!$subscription) {
                    return response()->json([
                        'success' => false,
                        'message' => 'You need an active subscription to upload properties. Please subscribe to a plan.',
                        'requires_subscription' => true,
                    ], 403);
                }

                // Check if upload limit reached
                if ($subscription->upload_count >= $subscription->property_limit) {
                    return response()->json([
                        'success' => false,
                        'message' => "You have reached your {$subscription->plan_name} plan limit of {$subscription->property_limit} properties. Please upgrade your plan to list more.",
                        'limit_reached' => true,
                        'current_count' => $subscription->upload_count,
                        'limit' => $subscription->property_limit,
                    ], 403);
                }

                // Handle image uploads
                if ($request->hasFile('images')) {
                    $imagePaths = [];
                    $images = $request->file('images');

                    // Max 5 images per property
                    $images = array_slice($images, 0, 5);

                    foreach ($images as $image) {
                        $imageName = $this->processAndStoreImage($image);
                        if ($imageName) {
                            $imagePaths[] = $imageName;
                        }
                    }
                    $property->images = $imagePaths;
                }

                $property->save();

                // Increment upload_count after successful save
                \Illuminate\Support\Facades\DB::table('paid_subscribers')
                    ->where('subscription_id', $subscription->subscription_id)
                    ->increment('upload_count');

                return response()->json([
                    'success' => true,
                    'message' => 'Property added successfully',
                    'property' => $property
                ], 201);

            } finally {
                $lock->release();
            }

        } catch (\Exception $e) {
            Log::error('Failed to add property: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while adding the property. Please try again later.'
            ], 500);
        }
    }

    /**
     * Update an existing property
     */
    public function update(Request $request, $propertyId)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Find the property
            $property = Property::where('property_id', $propertyId)
                ->where('agent_id', $agent->agent_id)
                ->first();

            if (!$property) {
                return response()->json([
                    'success' => false,
                    'message' => 'Property not found or you do not have permission to update it'
                ], 404);
            }

            // Validation rules (all fields optional for update)
            $validator = Validator::make($request->all(), [
                'title' => 'nullable|string|max:255',
                'type' => 'nullable|string|max:50',
                'location' => 'nullable|string|max:255',
                'listing_type' => 'nullable|in:For Sale,For Rent,Sold,Rented',
                'price' => 'nullable|numeric|min:0',
                'beds' => 'nullable|integer|min:0',
                'baths' => 'nullable|integer|min:0',
                'sqft' => 'nullable|string',
                'description' => 'nullable|string',
                'address' => 'nullable|string',
                'latitude' => 'nullable|numeric|between:-90,90',
                'longitude' => 'nullable|numeric|between:-180,180',
                'status' => 'nullable|in:Active,Inactive',
                'images.*' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:5120',
                'delete_images' => 'nullable|json',
                'amenities' => 'nullable|json',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Update fields if provided
            if ($request->has('title'))
                $property->title = $request->title;
            if ($request->has('type'))
                $property->type = $request->type;
            if ($request->has('location'))
                $property->location = $request->location;
            if ($request->has('listing_type'))
                $property->listing_type = $request->listing_type;
            if ($request->has('price'))
                $property->price = $request->price;
            if ($request->has('beds'))
                $property->beds = $request->beds;
            if ($request->has('baths'))
                $property->baths = $request->baths;
            if ($request->has('sqft'))
                $property->sqft = $request->sqft;
            if ($request->has('description'))
                $property->description = $request->description;
            if ($request->has('address'))
                $property->address = $request->address;
            if ($request->has('latitude'))
                $property->latitude = $request->latitude;
            if ($request->has('longitude'))
                $property->longitude = $request->longitude;
            if ($request->has('amenities'))
                $property->amenities = $request->amenities;
            if ($request->has('status'))
                $property->status = $request->status;

            // Handle image updates
            $existingImages = json_decode($property->getAttributes()['images'] ?? '[]', true) ?? [];

            // Delete specified images
            if ($request->has('delete_images')) {
                $imagesToDelete = json_decode($request->delete_images, true);
                foreach ($imagesToDelete as $imageToDelete) {
                    if (in_array($imageToDelete, $existingImages)) {
                        // Delete from storage
                        Storage::disk('public')->delete('property_images/' . $imageToDelete);
                        // Remove from array
                        $existingImages = array_diff($existingImages, [$imageToDelete]);
                    }
                }
            }

            // Add new images
            if ($request->hasFile('images')) {
                $currentCount = count($existingImages);
                // Hardcoded 5 image limit per property, independent of plan for now based on context
                $remainingSlots = 5 - $currentCount;

                if ($remainingSlots > 0) {
                    $images = $request->file('images');

                    // Only allow enough images to reach the limit of 5
                    $images = array_slice($images, 0, $remainingSlots);

                    foreach ($images as $image) {
                        $imageName = $this->processAndStoreImage($image);
                        if ($imageName) {
                            $existingImages[] = $imageName;
                        }
                    }
                }
            }

            $property->images = array_values($existingImages);
            $property->save();

            return response()->json([
                'success' => true,
                'message' => 'Property updated successfully',
                'property' => $property
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to update property: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating the property. Please try again later.'
            ], 500);
        }
    }

    /**
     * Generate a unique property ID
     */
    private function generatePropertyId()
    {
        do {
            $id = random_int(100000, 999999);
        } while (Property::where('property_id', $id)->exists());

        return $id;
    }

    /**
     * Process, resize, and store an image.
     */
    /**
     * Process, resize, and store an image.
     */
    private function processAndStoreImage($image)
    {
        // 0. Check if upload is valid
        if (!$image->isValid()) {
            return null;
        }

        // 1. Try Resizing if GD is available
        if (extension_loaded('gd')) {
            try {
                // Increase memory limit for image processing
                @ini_set('memory_limit', '512M');

                $path = $image->getRealPath();
                $content = file_get_contents($path);

                if ($content === false) {
                    throw new \Exception("Failed to read file content");
                }

                $originalImage = @imagecreatefromstring($content);
                if (!$originalImage) {
                    throw new \Exception("Failed to parse image data");
                }

                // Get original dimensions
                $width = imagesx($originalImage);
                $height = imagesy($originalImage);

                // Calculate new dimensions (max 1024x1024)
                $maxWidth = 1024;
                $maxHeight = 1024;

                // Only resize if larger than max
                if ($width > $maxWidth || $height > $maxHeight) {
                    $ratio = min($maxWidth / $width, $maxHeight / $height);
                    $newWidth = (int) ($width * $ratio);
                    $newHeight = (int) ($height * $ratio);
                } else {
                    $newWidth = $width;
                    $newHeight = $height;
                }

                // Create new image resource
                $newImage = imagecreatetruecolor($newWidth, $newHeight);

                // Preserve transparency for PNG/GIF if possible, or use white background
                // For simplicity and to ensure JPG output, we default to white background
                $white = imagecolorallocate($newImage, 255, 255, 255);
                imagefill($newImage, 0, 0, $white);

                // Resize
                imagecopyresampled($newImage, $originalImage, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);

                // Output as JPEG to buffer
                ob_start();
                imagejpeg($newImage, null, 85); // 85% quality
                $imageContent = ob_get_clean();

                // Clean up
                imagedestroy($originalImage);
                imagedestroy($newImage);

                // Store processed image
                $imageName = time() . '_' . uniqid() . '.jpg';
                Storage::disk('public')->put('property_images/' . $imageName, $imageContent);

                return $imageName;

            } catch (\Exception $e) {
                // Determine if we should log this error (optional)
                // Proceed to fallback
            }
        }

        // 2. Fallback: Store original file directly
        try {
            $imageName = time() . '_' . uniqid() . '.' . $image->getClientOriginalExtension();
            // storeAs returns the path, but we just want the filename if we store it in property_images
            // helper $image->storeAs('folder', 'name', 'disk')
            $image->storeAs('property_images', $imageName, 'public');
            return $imageName;
        } catch (\Exception $e) {
            return null;
        }
    }

    /**
     * Delete a property
     */
    public function destroy($propertyId)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $property = Property::where('property_id', $propertyId)
                ->where('agent_id', $agent->agent_id)
                ->first();

            if (!$property) {
                return response()->json([
                    'success' => false,
                    'message' => 'Property not found or you do not have permission to delete it'
                ], 404);
            }

            // Delete images associated with the property
            $images = json_decode($property->getAttributes()['images'] ?? '[]', true);
            if (is_array($images)) {
                foreach ($images as $image) {
                    Storage::disk('public')->delete('property_images/' . $image);
                }
            }

            $property->delete();

            return response()->json([
                'success' => true,
                'message' => 'Property deleted successfully'
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to delete property: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while deleting the property. Please try again later.'
            ], 500);
        }
    }
}
