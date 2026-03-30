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
        Schema::table('cribs_users', function (Blueprint $table) {
            if (!Schema::hasColumn('cribs_users', 'nin_verification')) {
                $table->tinyInteger('nin_verification')->default(0)->after('email_verification_expires_at');
            }
            if (!Schema::hasColumn('cribs_users', 'bvn_verification')) {
                $table->tinyInteger('bvn_verification')->default(0)->after('nin_verification');
            }
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('cribs_users', function (Blueprint $table) {
            $table->dropColumn(['nin_verification', 'bvn_verification']);
        });
    }
};
