module CreateTableFacilities

import SearchLight.Migrations: create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
  create_table(:facilities) do
    [
      pk()
      column("account_id", :integer)
      column("facilities_data", :string)
      column("created_at", :timestamp, not_null=true)
      column("updated_at", :timestamp, not_null=true)
    ]
  end
end

function down()
  drop_table(:facilities)
end

end
