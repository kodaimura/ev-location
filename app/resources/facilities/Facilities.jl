module Facilities

import Dates: DateTime, now
import SearchLight: AbstractModel, DbId
import Base: @kwdef

export Facility

@kwdef mutable struct Facility <: AbstractModel
  id::DbId = DbId()
  account_id::Int32= 0
  guest_code::String = ""
  facilities_data::String = "[]"
  created_at::DateTime = now()
  updated_at::DateTime = now()
  deleted_at::Any = nothing
end

end
