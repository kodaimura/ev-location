module CreateTableAccounts

import SearchLight.Migrations: create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
  create_table(:accounts) do
    [
      pk()
      column("account_name", :string, "UNIQUE", not_null=true)
      column("account_password", :string, not_null=true)
      column("created_at", :timestamp, not_null=true)
      column("updated_at", :timestamp, not_null=true)
    ]
  end
end

function down()
  drop_table(:accounts)
end

end
