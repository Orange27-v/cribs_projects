<?php

use App\Http\Controllers\Admin\AdminController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Admin API Routes
|--------------------------------------------------------------------------
*/

Route::middleware(['auth:sanctum', 'auth.admin'])->group(function () {
    Route::get('/', [AdminController::class, 'index']);
    // Add other admin routes here
});
