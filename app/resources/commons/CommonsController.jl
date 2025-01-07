module CommonsController

include("CommonsService.jl")

import Genie.Renderer.Json as RenderJson
import Genie.Requests as Requests
import .CommonsService

export handover

function validate_request_keys(request::Dict{String, Any}, keys::Vector{String})
    missing_keys = [key for key in keys if !haskey(request, key)]
    return isempty(missing_keys), missing_keys
end

function handover(ctx::Dict{String, Any})
    request = Requests.jsonpayload()
    is_valid, missing_keys = validate_request_keys(request, ["guest_code"])
    if !is_valid
        return RenderJson.json(Dict("error" => "Missing required keys", "missing_keys" => missing_keys); status=400)
    end

    guest_code = request["guest_code"]
    account_id = Int32(ctx["payload"]["id"])
    success = CommonsService.handover(guest_code, account_id)
    if success
        return RenderJson.json(Dict(); status=200)
    else
        return RenderJson.json(Dict(); status=500)
    end
end

end