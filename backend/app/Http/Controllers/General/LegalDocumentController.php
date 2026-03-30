<?php

namespace App\Http\Controllers\General;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\LegalDocument; // Import the LegalDocument model
use Illuminate\Support\Facades\Log;

class LegalDocumentController extends Controller
{
    public function show($type)
    {
        try {
            // Sanitize the input to be safe for database queries
            $documentType = str_replace('-', '_', $type);

            $document = LegalDocument::where('document_type', $documentType)
                ->where('is_active', true)
                ->first();

            if (!$document) {
                return response()->json(['message' => 'Legal document not found.'], 404);
            }

            return response()->json([
                'status' => 'success',
                'data' => [
                    'content' => $document->content,
                    'version' => $document->version,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Legal document fetch error: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while loading legal document. Please try again later.'
            ], 500);
        }
    }
}
