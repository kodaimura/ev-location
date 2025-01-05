module Scores

import Dates: DateTime, now
import SearchLight: AbstractModel, DbId
import Base: @kwdef

export Score

@kwdef mutable struct Score <: AbstractModel
  id::DbId = DbId()
  account_id::Int32 = 0
  guest_code::String = ""
  address::String = ""
  score::Float64 = 0.0
  facilities_data::String = "[]"
  facilities_data_2::String = "[]"
  tmax::Int32 = 30 * 60
  created_at::DateTime = now()
  updated_at::DateTime = now()
  deleted_at::Union{DateTime, Nothing} = nothing
end

end
