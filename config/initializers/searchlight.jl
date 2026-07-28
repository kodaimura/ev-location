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

if ENV["GENIE_ENV"] != "test"
  SearchLight.Configuration.load(context = @__MODULE__)
  SearchLight.connect()
end
