module Scores

import Dates: DateTime, now
import SearchLight: AbstractModel, DbId
import Base: @kwdef

export Score

@kwdef mutable struct Score <: AbstractModel
  id::DbId = DbId()
  account_id::Union{Int32, Nothing} = nothing
  address::String = ""
  score::Float64 = 0.0
  facilities_data::String = ""
  tmax::Int32 = 30
  created_at::DateTime = now()
  updated_at::DateTime = now()
end

end
