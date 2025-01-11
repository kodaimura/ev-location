module AccountsController

include("AccountsService.jl")

import Genie.Renderer.Json as RendererJson
import Genie.Requests as Requests

using .AccountsService

export signup, login, logout

function validate_request_keys(request::Dict{String, Any}, keys::Vector{String})
    missing_keys = [key for key in keys if !haskey(request, key)]
    if !isempty(missing_keys)
        throw(BadRequestError("Missing required keys: $(join(missing_keys, ", "))"))
    end
end

function signup(ctx::Dict{String, Any})
    request = Requests.jsonpayload()
    try
        validate_request_keys(request, ["account_name", "account_password"])
        account_name = request["account_name"]
        account_password = request["account_password"]

        AccountsService.signup(account_name, account_password)
        return RendererJson.json(Dict(); status=201)
    catch e
        return json_error_response(e, Requests.request())
    end
end

function login(ctx::Dict{String, Any})
    request = Requests.jsonpayload()
    try
        validate_request_keys(request, ["account_name", "account_password"])
        account_name = request["account_name"]
        account_password = request["account_password"]
        
        account = AccountsService.login(account_name, account_password)
        if isnothing(account)
            throw(UnauthorizedError())
        end
        token = AccountsService.create_jwt(account)
        cookie_header = "token=$token; Path=/; HttpOnly; Secure; SameSite=Lax"
        return RendererJson.json(Dict("token" => token); status=200, headers=Dict("Set-Cookie" => cookie_header))
    catch e
        return json_error_response(e, Requests.request())
    end
end

function logout(ctx::Dict{String, Any})
    try
        cookie_header = "token=; Path=/; HttpOnly; Secure; SameSite=Lax; Expires=Thu, 01 Jan 1970 00:00:00 GMT"
        return RendererJson.json(Dict(); status=200, headers=Dict("Set-Cookie" => cookie_header))
    catch e
        return json_error_response(e, Requests.request())
    end
end

end
