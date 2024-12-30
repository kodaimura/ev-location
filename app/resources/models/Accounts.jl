module Accounts

import Dates: DateTime, now
import SearchLight: AbstractModel, DbId
import Base: @kwdef

export Account

@kwdef mutable struct Account <: AbstractModel
  account_id::Union{DbId, Nothing} = nothing
  account_name::String = ""
  account_password::String = ""
  created_at::Union{DateTime, Nothing} = nothing
  updated_at::Union{DateTime, Nothing} = nothing
end

end
