module FacilitiesController

include("FacilitiesService.jl")

import Genie.Renderer.Json as RenderJson
import Genie.Requests as Requests
import .FacilitiesService

export guest_post

function validate_request_keys(request::Dict{String, Any}, keys::Vector{String})
    missing_keys = [key for key in keys if !haskey(request, key)]
    return isempty(missing_keys), missing_keys
end

function guest_post(ctx::Dict{String, Any})
    request = Requests.jsonpayload()
    is_valid, missing_keys = validate_request_keys(request, ["guest_code", "facilities_data"])
    if !is_valid
        return RenderJson.json(Dict("error" => "Missing required keys", "missing_keys" => missing_keys); status=400)
    end

    guest_code = request["guest_code"]
    facilities_data = request["facilities_data"]
    success = FacilitiesService.guest_post(guest_code, facilities_data)
    if success
        return RenderJson.json(Dict(); status=200)
    else
        return RenderJson.json(Dict(); status=500)
    end
end

end