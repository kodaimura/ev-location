module Facilities

import Dates: DateTime, now
import SearchLight: AbstractModel, DbId
import Base: @kwdef

export Facility

@kwdef mutable struct Facility <: AbstractModel
  id::DbId = DbId()
  account_id::Union{Int32, Nothing} = nothing
  guest_code::Union{String, Nothing} = nothing
  facilities_data::Union{String, Nothing} = nothing
  created_at::DateTime = now()
  updated_at::DateTime = now()
  deleted_at::Union{DateTime, Nothing} = nothing
end

end
