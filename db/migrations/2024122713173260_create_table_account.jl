module CreateTableAccount

import SearchLight: query
import SearchLight.Migrations: create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
  create_table(:account) do
    [
      pk("account_id")
      column("account_name", :string, "UNIQUE", not_null=true)
      column("account_password", :string, not_null=true)
      column("created_at", :datetime, not_null=true)
      column("updated_at", :datetime, not_null=true)
    ]
  end

  query("""
    create function set_update_time() returns trigger AS '
  	BEGIN
      new.updated_at := NOW();
      return new;
  	END;
    ' language 'plpgsql';

    create trigger trg_account_upd BEFORE UPDATE ON account FOR EACH ROW
  	execute procedure set_update_time();
  """
  )
end

function down()
  drop_table(:account)
end

end
