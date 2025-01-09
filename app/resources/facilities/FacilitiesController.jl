module FacilitiesController

include("FacilitiesService.jl")

import Genie.Renderer.Json as RendererJson
import Genie.Requests as Requests

using .FacilitiesService

export get, post, guest_get, guest_post

function validate_request_keys(request::Dict{String, Any}, keys::Vector{String})
    missing_keys = [key for key in keys if !haskey(request, key)]
    if !isempty(missing_keys)
        throw(BadRequestError("Missing required keys: $(join(missing_keys, ", "))"))
    end
end

function get(ctx::Dict{String, Any})
    try
        account_id = Int32(ctx["payload"]["id"])
        facilities = FacilitiesService.get(account_id)
        if isnothing(facilities)
            throw(NotFoundError())
        end
        return RendererJson.json(Dict("facilities" => facilities); status=200)
    catch e
        return json_error_response(e, Requests.request())
    end
end

function post(ctx::Dict{String, Any})
    request = Requests.jsonpayload()
    try
        account_id = Int32(ctx["payload"]["id"])
        validate_request_keys(request, ["facilities_data"])
        facilities_data = request["facilities_data"]

        FacilitiesService.post(account_id, facilities_data)
        return RendererJson.json(Dict(); status=200)
    catch e
        return json_error_response(e, Requests.request())
    end
end

function guest_get(ctx::Dict{String, Any}, guest_code::AbstractString)
    try
        facilities = FacilitiesService.guest_get(guest_code)
        if isnothing(facilities)
            throw(NotFoundError())
        end
        return RendererJson.json(Dict("facilities" => facilities); status=200)
    catch e
        return json_error_response(e, Requests.request())
    end
end

function guest_post(ctx::Dict{String, Any}, guest_code::AbstractString)
    request = Requests.jsonpayload()
    try
        validate_request_keys(request, ["facilities_data"])
        facilities_data = request["facilities_data"]

        FacilitiesService.guest_post(guest_code, facilities_data)
        return RendererJson.json(Dict(); status=200)
    catch e
        return json_error_response(e, Requests.request())
    end
end

end