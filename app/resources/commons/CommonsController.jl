module CommonsController

include("CommonsService.jl")

import Genie.Renderer.Json as RendererJson
import Genie.Requests as Requests

using .CommonsService

export handover

function validate_request_keys(request::Dict{String, Any}, keys::Vector{String})
    missing_keys = [key for key in keys if !haskey(request, key)]
    if !isempty(missing_keys)
        throw(BadRequestError("Missing required keys: $(join(missing_keys, ", "))"))
    end
end

function handover(ctx::Dict{String, Any})
    request = Requests.jsonpayload()
    try
        account_id = Int32(ctx["payload"]["id"])
        validate_request_keys(request, ["guest_code"])
        guest_code = request["guest_code"]

        CommonsService.handover(guest_code, account_id)
        return RendererJson.json(Dict(); status=200)
    catch e
        return json_error_response(e, Requests.request())
    end
end

end