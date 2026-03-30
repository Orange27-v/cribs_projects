<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // This migration is for documentation purposes only
        // The qoreid_tokens table already exists in the database

        if (!Schema::hasTable('qoreid_tokens')) {
            Schema::create('qoreid_tokens', function (Blueprint $table) {
                $table->id();
                $table->string('access_token', 500);
                $table->timestamp('expires_at');
                $table->timestamp('last_used_at')->nullable();
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('qoreid_tokens');
    }
};
