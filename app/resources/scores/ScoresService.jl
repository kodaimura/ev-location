module ScoresService

include("Scores.jl")

import JSON
import SearchLight
import .Scores: Score

export guest_post

function guest_post(guest_code::AbstractString, address::String, facilities_data::String, facilities_data_2::String)::Tuple{Float64, Bool}
    try
        tmax = 30 * 60
        score = calc_score(facilities_data_2, tmax)
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
        return 0, false
    end
end

function calc_score(facilities_data_2::String, tmax::Int64)::Float64
    facilities = JSON.parse(facilities_data_2)
    total = 0
    maximum = 0
    for f in facilities
        p = Int64(f["frequency"])
        t = Int64(f["time"])
        total += max(0, ((tmax - t) / tmax) * 100 * p)
        maximum += 100 * p
    end
    return round((total / maximum) * 100, digits=1)
end

end