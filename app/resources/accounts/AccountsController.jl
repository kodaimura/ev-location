module AccountsController

include("AccountsService.jl")

import Genie.Renderer.Json as RenderJson
import Genie.Requests as Requests
import .AccountsService

export signup, login

function validate_request_keys(request::Dict{String, Any}, keys::Vector{String})
    missing_keys = [key for key in keys if !haskey(request, key)]
    return isempty(missing_keys), missing_keys
end

function signup(ctx::Dict{String, Any})
    request = Requests.jsonpayload()
    is_valid, missing_keys = validate_request_keys(request, ["account_name", "account_password"])
    if !is_valid
        return RenderJson.json(Dict("error" => "Missing required keys", "missing_keys" => missing_keys); status=400)
    end

    account_name = request["account_name"]
    account_password = request["account_password"]
    success = AccountsService.signup(account_name, account_password)
    if success
        return RenderJson.json(Dict(); status=201)
    else
        return RenderJson.json(Dict("error" => message); status=400)
    end
end

function login(ctx::Dict{String, Any})
    request = Requests.jsonpayload()
    is_valid, missing_keys = validate_request_keys(request, ["account_name", "account_password"])
    if !is_valid
        return RenderJson.json(Dict("error" => "Missing required keys", "missing_keys" => missing_keys); status=400)
    end

    account_name = request["account_name"]
    account_password = request["account_password"]
    account = AccountsService.login(account_name, account_password)
    if account != nothing
        token = AccountsService.create_jwt(account)
        cookie_header = "token=$token; Path=/; HttpOnly; Secure; SameSite=Lax"
        return RenderJson.json(Dict("token" => token); status=200, headers=Dict("Set-Cookie" => cookie_header))
    else
        return RenderJson.json(Dict("error" => "login failed"); status=401)
    end
end

end
