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
    
    try
        AccountsService.signup(account_name, account_password)
        return RenderJson.json(Dict(); status=201)
    catch e
        if e isa ConflictError
            return RenderJson.json(Dict("error" => "Account name already exists"); status=409)
        elseif e isa InternalError
            return RenderJson.json(Dict("error" => "Failed to sign up. Please try again later."); status=500)
        else
            return RenderJson.json(Dict("error" => "An unexpected error occurred"); status=500)
        end
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
    
    try
        account = AccountsService.login(account_name, account_password)
        if !nothing(account)
            token = AccountsService.create_jwt(account)
            cookie_header = "token=$token; Path=/; HttpOnly; Secure; SameSite=Lax"
            return RenderJson.json(Dict("token" => token); status=200, headers=Dict("Set-Cookie" => cookie_header))
        else
            return RenderJson.json(Dict("error" => "Invalid account credentials"); status=401)
        end
    catch e
        if e isa UnauthorizedError
            return RenderJson.json(Dict("error" => "Invalid account credentials"); status=401)
        elseif e isa InternalError
            return RenderJson.json(Dict("error" => "Login failed. Please try again later."); status=500)
        else
            return RenderJson.json(Dict("error" => "An unexpected error occurred"); status=500)
        end
    end
end

end
