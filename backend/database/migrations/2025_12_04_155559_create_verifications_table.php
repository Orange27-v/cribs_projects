<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('verifications', function (Blueprint $table) {
            $table->id();
            $table->string('receiver_id');
            $table->string('receiver_type');
            $table->string('type');
            $table->string('value');
            $table->string('status')->default('pending');
            $table->uuid('verification_id')->unique();
            $table->json('response_payload')->nullable();
            $table->timestamps();

            $table->index('receiver_id');
            $table->index('verification_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('verifications');
    }
};
