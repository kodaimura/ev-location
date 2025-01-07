module ScoresService

include("Scores.jl")
using SearchLight
import JSON
import Dates: DateTime, now
import .Scores: Score

export guest_get, guest_post, guest_delete, get, post, delete

function guest_get(guest_code::AbstractString)::Tuple{Vector{Score}, Bool}
    try
        scores = SearchLight.find(Score, guest_code = guest_code, id = id, order=["score DESC"])
        return scores, true
    catch e
        return Score[], false
    end
end

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

function guest_delete(guest_code::AbstractString, id::AbstractString)::Bool
    try
        score = SearchLight.findone(Score, guest_code = guest_code, id = id)
        if score !== nothing
            score.deleted_at = now()
            SearchLight.save!(score)
        end
        return true
    catch e
        return false
    end
end

function get(account_id::Int32)::Tuple{Vector{Score}, Bool}
    try
        scores = SearchLight.find(Score, SQLWhereExpression("account_id = ? AND deleted_at is null", account_id), order=["score DESC"])
        return scores, true
    catch e
        return Score[], false
    end
end

function post(account_id::Int32, address::String, facilities_data::String, facilities_data_2::String)::Tuple{Float64, Bool}
    try
        tmax = 30 * 60
        score = calc_score(facilities_data_2, tmax)
        new_score = Score(
            account_id=account_id, 
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

function delete(account_id::Int32, id::AbstractString)::Bool
    try
        score = SearchLight.findone(Score, account_id = account_id, id = id)
        if score !== nothing
            score.deleted_at = now()
            SearchLight.save!(score)
        end
        return true
    catch e
        return false
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