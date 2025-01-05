module ScoresService

include("Scores.jl")

import SearchLight
import .Scores: Score

export guest_post

function guest_post(guest_code::String, address::String, facilities_data::String, facilities_data_2::String)::Tuple{Float64, Bool}
    try
        tmax = 30
        score = calc_score(facilities_data, tmax)
        new_score = Score(
            guest_code=guest_code, 
            address=address, score=score, 
            facilities_data=facilities_data, 
            facilities_data_2=facilities_data_2, 
            tmax=tmax
        )
        SearchLight.save!(new_score)
        return score, true
    catch e
        println(e)
        return 0, false
    end
end

function calc_score(facilities_data::String, tmax::Int64)::Float64
    return 90.0
end

end