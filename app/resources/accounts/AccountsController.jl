module AccountsController

include("AccountsService.jl")

import Genie.Renderer.Json as RenderJson
import Genie.Requests as Requests
import .AccountsService

export signup, login, verify_token

function validate_request_keys(request::Dict{String, Any}, keys::Vector{String})
    missing_keys = [key for key in keys if !haskey(request, key)]
    return isempty(missing_keys), missing_keys
end

function signup()
    request = Requests.jsonpayload()
    is_valid, missing_keys = validate_request_keys(request, ["account_name", "account_password"])
    if !is_valid
        return RenderJson.json(Dict("error" => "Missing required keys", "missing_keys" => missing_keys); status=400)
    end

    account_name = request["account_name"]
    account_password = request["account_password"]
    success, message = AccountsService.signup(account_name, account_password)
    if success
        return RenderJson.json(Dict("message" => message); status=201)
    else
        return RenderJson.json(Dict("error" => message); status=400)
    end
end

function login()
    request = Requests.jsonpayload()
    is_valid, missing_keys = validate_request_keys(request, ["account_name", "account_password"])
    if !is_valid
        return RenderJson.json(Dict("error" => "Missing required keys", "missing_keys" => missing_keys); status=400)
    end

    account_name = request["account_name"]
    account_password = request["account_password"]
    success, response = AccountsService.login(account_name, account_password)
    if success
        return RenderJson.json(Dict("token" => response); status=200)
    else
        return RenderJson.json(Dict("error" => response); status=401)
    end
end

function verify_token()
    request = Requests.jsonpayload()
    is_valid, missing_keys = validate_request_keys(request, ["token"])
    if !is_valid
        return RenderJson.json(Dict("error" => "Missing required keys", "missing_keys" => missing_keys); status=400)
    end

    token = request["token"]
    success, payload_or_error = AccountsService.verify_token(token)
    if success
        return RenderJson.json(Dict("payload" => payload_or_error); status=200)
    else
        return RenderJson.json(Dict("error" => payload_or_error); status=401)
    end
end

end
