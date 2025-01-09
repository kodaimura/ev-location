module ScoresService

include("../core/Errors.jl")
include("Scores.jl")

using Reexport
using SearchLight
using Dates
import JSON

import .Scores: Score
@reexport using .Errors

function get(account_id::Int32)::Vector{Score}
    try
        return SearchLight.find(Score, SQLWhereExpression("account_id = ? AND deleted_at is null", account_id), order=["score DESC"])
    catch e
        handle_exception(e)
    end
end

function post(account_id::Int32, address::String, facilities_data::String, facilities_data_2::String)::Float64
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
        return score
    catch e
        handle_exception(e)
    end
end

function delete(account_id::Int32, id::AbstractString)
    try
        #SearchLightの不具合 deleted_atがNothing型として扱われてしまう
        #score = SearchLight.findone(Score, account_id = account_id, id = id)
        #if score !== nothing
        #    score.deleted_at = now()
        #    SearchLight.save!(score)
        #end
        where_clause = string(SQLWhereExpression("account_id = ? AND id = ?", account_id, id))
        where_clause = replace(where_clause, r"^AND\s+" => "")
        SearchLight.query("UPDATE scores SET deleted_at = '$(Dates.format(now(), "yyyy-mm-dd HH:MM:SS.sss"))' where $where_clause")
    catch e
        handle_exception(e)
    end
end

function guest_get(guest_code::AbstractString)::Vector{Score}
    try
        return SearchLight.find(Score, SQLWhereExpression("guest_code = ? AND deleted_at is null", guest_code), order=["score DESC"])
    catch e
        handle_exception(e)
    end
end

function guest_post(guest_code::AbstractString, address::String, facilities_data::String, facilities_data_2::String)::Float64
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
        return score
    catch e
        handle_exception(e)
    end
end

function guest_delete(guest_code::AbstractString, id::AbstractString)
    try
        #SearchLightの不具合 deleted_atがNothing型として扱われてしまう
        #score = SearchLight.findone(Score, guest_code = guest_code, id = id)
        #if score !== nothing
        #    score.deleted_at = now()
        #    SearchLight.save!(score)
        #end
        where_clause = string(SQLWhereExpression("guest_code = ? AND id = ?", guest_code, id))
        where_clause = replace(where_clause, r"^AND\s+" => "")
        SearchLight.query("UPDATE scores SET deleted_at = '$(Dates.format(now(), "yyyy-mm-dd HH:MM:SS.sss"))' where $where_clause")
    catch e
        handle_exception(e)
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