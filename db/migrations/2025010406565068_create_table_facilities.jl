module CreateTableFacilities

import SearchLight.Migrations: create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
  create_table(:facilities) do
    [
      pk()
      column("account_id", :integer)
      column("guest_code", :string)
      column("facilities_data", :string)
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
