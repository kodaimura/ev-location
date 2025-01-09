module ScoresController

include("ScoresService.jl")

import Genie.Renderer.Json as RendererJson
import Genie.Requests as Requests

using .ScoresService

export get, post, delete, guest_get, guest_post, guest_delete

function validate_request_keys(request::Dict{String, Any}, keys::Vector{String})
    missing_keys = [key for key in keys if !haskey(request, key)]
    if !isempty(missing_keys)
        throw(BadRequestError("Missing required keys: $(join(missing_keys, ", "))"))
    end
end

function guest_get(ctx::Dict{String, Any}, guest_code::AbstractString)
    try
        scores = ScoresService.guest_get(guest_code)
        return RendererJson.json(Dict("scores" => scores); status=200)
    catch e
        return json_error_response(e, Requests.request())
    end
end

function guest_post(ctx::Dict{String, Any}, guest_code::AbstractString)
    request = Requests.jsonpayload()
    try
        validate_request_keys(request, ["address", "facilities_data", "facilities_data_2"])
        address = request["address"]
        facilities_data = request["facilities_data"]
        facilities_data_2 = request["facilities_data_2"]

        score = ScoresService.guest_post(guest_code, address, facilities_data, facilities_data_2)
        return RendererJson.json(Dict("score" => score); status=200)
    catch e
        return json_error_response(e, Requests.request())
    end
end

function guest_delete(ctx::Dict{String, Any}, guest_code::AbstractString, id::AbstractString)
    try
        ScoresService.guest_delete(guest_code, id)
        return RendererJson.json(Dict(); status=200)
    catch e
        return json_error_response(e, Requests.request())
    end
end

function get(ctx::Dict{String, Any})
    try
        account_id = Int32(ctx["payload"]["id"])
        scores = ScoresService.get(account_id)
        return RendererJson.json(Dict("scores" => scores); status=200)
    catch e
        return json_error_response(e, Requests.request())
    end
end

function post(ctx::Dict{String, Any})
    request = Requests.jsonpayload()
    try
        account_id = Int32(ctx["payload"]["id"])
        validate_request_keys(request, ["address", "facilities_data", "facilities_data_2"])
        address = request["address"]
        facilities_data = request["facilities_data"]
        facilities_data_2 = request["facilities_data_2"]

        score = ScoresService.post(account_id, address, facilities_data, facilities_data_2)
        return RendererJson.json(Dict("score" => score); status=200)
    catch e
        return json_error_response(e, Requests.request())
    end
end

function delete(ctx::Dict{String, Any}, id::AbstractString)
    try
        account_id = Int32(ctx["payload"]["id"])
        ScoresService.delete(account_id, id)
        return RendererJson.json(Dict(); status=200)
    catch e
        return json_error_response(e, Requests.request())
    end
end

end