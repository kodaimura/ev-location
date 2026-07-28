using SearchLight
using Genie
using JSON3
using StructTypes

function StructTypes.StructType(::Type{T}) where {T<:SearchLight.AbstractModel}
  StructTypes.Struct()
end

function StructTypes.StructType(::Type{SearchLight.DbId})
  StructTypes.Struct()
end

function override_db_config_from_env!()
  settings = SearchLight.config.db_config_settings
  overrides = Dict(
    "database" => "DB_NAME",
    "host" => "DB_HOST",
    "username" => "DB_USER",
    "password" => "DB_PASSWORD",
    "port" => "DB_PORT"
  )

  for (config_key, env_key) in overrides
    value = get(ENV, env_key, "")
    isempty(value) && continue
    settings[config_key] = config_key == "port" ? parse(Int, value) : value
  end
end

if ENV["GENIE_ENV"] != "test"
  SearchLight.Configuration.load(context = @__MODULE__)
  override_db_config_from_env!()
  SearchLight.connect()
end
