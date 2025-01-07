module FacilitiesController

include("FacilitiesService.jl")

import Genie.Renderer.Json as RenderJson
import Genie.Requests as Requests
import .FacilitiesService

export guest_get, guest_post, get, post

function validate_request_keys(request::Dict{String, Any}, keys::Vector{String})
    missing_keys = [key for key in keys if !haskey(request, key)]
    return isempty(missing_keys), missing_keys
end

function guest_get(ctx::Dict{String, Any}, guest_code::AbstractString)
    facilities, success = FacilitiesService.guest_get(guest_code)
    if success
        return RenderJson.json(Dict("facilities" => facilities); status=200)
    else
        return RenderJson.json(Dict(); status=500)
    end
end

function guest_post(ctx::Dict{String, Any}, guest_code::AbstractString)
    request = Requests.jsonpayload()
    is_valid, missing_keys = validate_request_keys(request, ["facilities_data"])
    if !is_valid
        return RenderJson.json(Dict("error" => "Missing required keys", "missing_keys" => missing_keys); status=400)
    end

    facilities_data = request["facilities_data"]
    success = FacilitiesService.guest_post(guest_code, facilities_data)
    if success
        return RenderJson.json(Dict(); status=200)
    else
        return RenderJson.json(Dict(); status=500)
    end
end

function get(ctx::Dict{String, Any})
    account_id = Int32(ctx["payload"]["id"])
    facilities, success = FacilitiesService.get(account_id)
    if success
        return RenderJson.json(Dict("facilities" => facilities); status=200)
    else
        return RenderJson.json(Dict(); status=500)
    end
end

function post(ctx::Dict{String, Any})
    account_id = Int32(ctx["payload"]["id"])
    request = Requests.jsonpayload()
    is_valid, missing_keys = validate_request_keys(request, ["facilities_data"])
    if !is_valid
        return RenderJson.json(Dict("error" => "Missing required keys", "missing_keys" => missing_keys); status=400)
    end

    facilities_data = request["facilities_data"]
    success = FacilitiesService.post(account_id, facilities_data)
    if success
        return RenderJson.json(Dict(); status=200)
    else
        return RenderJson.json(Dict(); status=500)
    end
end

end