<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Change access_token from VARCHAR(500) to TEXT to accommodate JWT tokens
        DB::statement('ALTER TABLE qoreid_tokens MODIFY access_token TEXT NOT NULL');
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // Revert back to VARCHAR(500)
        DB::statement('ALTER TABLE qoreid_tokens MODIFY access_token VARCHAR(500) NOT NULL');
    }
};
