module CreateTableScores

import SearchLight.Migrations: create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
  create_table(:scores) do
    [
      pk()
      column("account_id", :integer)
      column("address", :string, not_null=true)
      column("score", :float, not_null=true)
      column("facilities_data", :string, not_null=true)
      column("tmax", :integer, not_null=true)
      column("created_at", :timestamp, not_null=true)
      column("updated_at", :timestamp, not_null=true)
    ]
  end
end

function down()
  drop_table(:scores)
end

end
