module ScoresController

include("ScoresService.jl")

import Genie.Renderer.Json as RenderJson
import Genie.Requests as Requests
import .ScoresService

export guest_get, guest_post, guest_delete, get, post, delete

function validate_request_keys(request::Dict{String, Any}, keys::Vector{String})
    missing_keys = [key for key in keys if !haskey(request, key)]
    return isempty(missing_keys), missing_keys
end

function guest_get(ctx::Dict{String, Any}, guest_code::AbstractString)
    scores, success = ScoresService.guest_get(guest_code)
    if success
        return RenderJson.json(Dict("scores" => scores); status=200)
    else
        return RenderJson.json(Dict(); status=500)
    end
end

function guest_post(ctx::Dict{String, Any}, guest_code::AbstractString)
    request = Requests.jsonpayload()
    is_valid, missing_keys = validate_request_keys(request, ["address", "facilities_data", "facilities_data_2"])
    if !is_valid
        return RenderJson.json(Dict("error" => "Missing required keys", "missing_keys" => missing_keys); status=400)
    end

    address = request["address"]
    facilities_data = request["facilities_data"]
    facilities_data_2 = request["facilities_data_2"]
    score, success = ScoresService.guest_post(guest_code, address, facilities_data, facilities_data_2)
    if success
        return RenderJson.json(Dict("score" => score); status=200)
    else
        return RenderJson.json(Dict(); status=500)
    end
end

function guest_delete(ctx::Dict{String, Any}, guest_code::AbstractString, id::AbstractString)
    success = ScoresService.guest_delete(guest_code, id)
    if success
        return RenderJson.json(Dict(); status=200)
    else
        return RenderJson.json(Dict(); status=500)
    end
end

function get(ctx::Dict{String, Any})
    account_id = Int32(ctx["payload"]["id"])
    scores, success = ScoresService.get(account_id)
    if success
        return RenderJson.json(Dict("scores" => scores); status=200)
    else
        return RenderJson.json(Dict(); status=500)
    end
end

function post(ctx::Dict{String, Any})
    account_id = Int32(ctx["payload"]["id"])
    request = Requests.jsonpayload()
    is_valid, missing_keys = validate_request_keys(request, ["address", "facilities_data", "facilities_data_2"])
    if !is_valid
        return RenderJson.json(Dict("error" => "Missing required keys", "missing_keys" => missing_keys); status=400)
    end

    address = request["address"]
    facilities_data = request["facilities_data"]
    facilities_data_2 = request["facilities_data_2"]
    score, success = ScoresService.post(account_id, address, facilities_data, facilities_data_2)
    if success
        return RenderJson.json(Dict("score" => score); status=200)
    else
        return RenderJson.json(Dict(); status=500)
    end
end

function delete(ctx::Dict{String, Any}, id::AbstractString)
    account_id = Int32(ctx["payload"]["id"])
    success = ScoresService.delete(account_id, id)
    if success
        return RenderJson.json(Dict(); status=200)
    else
        return RenderJson.json(Dict(); status=500)
    end
end

end