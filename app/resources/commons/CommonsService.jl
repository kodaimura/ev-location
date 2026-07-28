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
        scores = SearchLight.find(Score, guest_code = guest_code)
        for score in scores
            score.account_id = account_id
            SearchLight.save!(score)
        end

        if isnothing(SearchLight.findone(Facility, account_id=account_id))
            facilities = SearchLight.find(Facility, guest_code = guest_code)
            for facility in facilities
                facility.account_id = account_id
                SearchLight.save!(facility)
            end
        end
    catch e
        handle_exception(e)
    end
end

end
