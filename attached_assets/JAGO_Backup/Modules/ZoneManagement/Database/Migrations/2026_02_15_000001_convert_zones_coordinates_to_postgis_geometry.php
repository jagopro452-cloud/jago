<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class ConvertZonesCoordinatesToPostgisGeometry extends Migration
{
    public function up()
    {
        DB::statement('CREATE EXTENSION IF NOT EXISTS postgis');

        $columnType = DB::selectOne("
            SELECT udt_name FROM information_schema.columns
            WHERE table_name = 'zones' AND column_name = 'coordinates'
        ");

        if ($columnType && $columnType->udt_name === 'polygon') {
            DB::statement('ALTER TABLE zones ALTER COLUMN coordinates TYPE geometry(Polygon, 0) USING coordinates::geometry');
        }
    }

    public function down()
    {
    }
}
