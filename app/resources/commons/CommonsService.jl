module CommonsService

include("../core/Errors.jl")
include("../facilities/Facilities.jl")
include("../scores/Scores.jl")

using Reexport
using SearchLight

import .Facilities: Facility
import .Scores: Score
@reexport using .Errors

function handover(guest_code::AbstractString, account_id::Int32)
    try
        where_clause = string(SQLWhereExpression("guest_code = ?", guest_code))
        where_clause = replace(where_clause, r"^AND\s+" => "")
        SearchLight.query("UPDATE scores SET account_id = $account_id where $where_clause")

        if isnothing(SearchLight.findone(Facility, account_id=account_id))
            SearchLight.query("UPDATE facilities SET account_id = $account_id where $where_clause")
        end
    catch e
        handle_exception(e)
    end
end

end