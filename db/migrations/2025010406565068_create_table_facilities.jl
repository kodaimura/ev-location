module CreateTableFacilities

import SearchLight.Migrations: create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
  create_table(:facilities) do
    [
      pk()
      column("account_id", :integer, default=0, not_null=true)
      column("guest_code", :string, default="''", not_null=true)
      column("facilities_data", :string, default="'[]'", not_null=true)
      column("created_at", :timestamp, not_null=true)
      column("updated_at", :timestamp, not_null=true)
      column("deleted_at", :timestamp)
    ]
  end
end

function down()
  drop_table(:facilities)
end

end
