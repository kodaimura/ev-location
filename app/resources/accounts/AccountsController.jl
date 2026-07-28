module AccountsController

include("AccountsService.jl")

import Genie.Renderer.Json as RendererJson
import Genie.Requests as Requests
import Genie.Cookies as Cookies
import HTTP
import SearchLight

using .AccountsService

export signup, login, refresh, logout

const REFRESH_COOKIE_NAME = "refresh_token"
const LEGACY_COOKIE_NAME = "token"
const ACCESS_TOKEN_EXPIRES_IN_SECONDS = AccountsService.ACCESS_TOKEN_TTL_MINUTES * 60
const REFRESH_TOKEN_MAX_AGE_SECONDS = AccountsService.REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60

function auth_cookie_header(
    value::String;
    name::String=REFRESH_COOKIE_NAME,
    max_age::Union{Int, Nothing}=nothing,
    expires::Union{String, Nothing}=nothing
)
    parts = ["$name=$value", "Path=/", "HttpOnly", "SameSite=Lax"]
    if get(ENV, "GENIE_ENV", "dev") == "prod"
        push!(parts, "Secure")
    end
    if !isnothing(max_age)
        push!(parts, "Max-Age=$max_age")
    end
    if !isnothing(expires)
        push!(parts, "Expires=$expires")
    end
    return join(parts, "; ")
end

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
        access_token = AccountsService.create_access_token(account)
        refresh_token = AccountsService.create_refresh_token(account)
        cookie_header = auth_cookie_header(refresh_token; max_age=REFRESH_TOKEN_MAX_AGE_SECONDS)
        return RendererJson.json(
            access_token_response(access_token);
            status=200,
            headers=HTTP.Headers(["Set-Cookie" => cookie_header])
        )
    catch e
        return json_error_response(e, Requests.request())
    end
end

function refresh(ctx::Dict{String, Any})
    try
        refresh_token = request_cookie_value(REFRESH_COOKIE_NAME)
        if isnothing(refresh_token)
            throw(UnauthorizedError())
        end

        payload = AccountsService.Jwt.verified_payload(refresh_token; token_type="refresh")
        if isnothing(payload)
            throw(UnauthorizedError())
        end

        access_token = AccountsService.create_access_token(AccountsService.Account(
            id=SearchLight.DbId(Int(payload["id"])),
            account_name=String(payload["account_name"])
        ))
        return RendererJson.json(access_token_response(access_token); status=200)
    catch e
        return json_error_response(e, Requests.request())
    end
end

function logout(ctx::Dict{String, Any})
    try
        expired_at = "Thu, 01 Jan 1970 00:00:00 GMT"
        headers = HTTP.Headers([
            "Set-Cookie" => auth_cookie_header("", name=REFRESH_COOKIE_NAME, max_age=0, expires=expired_at),
            "Set-Cookie" => auth_cookie_header("", name=LEGACY_COOKIE_NAME, max_age=0, expires=expired_at),
        ])
        return RendererJson.json(Dict(); status=200, headers=headers)
    catch e
        return json_error_response(e, Requests.request())
    end
end

function access_token_response(access_token::String)::Dict{String, Any}
    return Dict(
        "access_token" => access_token,
        "token_type" => "Bearer",
        "expires_in" => ACCESS_TOKEN_EXPIRES_IN_SECONDS
    )
end

function request_cookie_value(name::String)::Union{String, Nothing}
    cookies = Cookies.getcookies(Requests.request())
    for cookie in cookies
        if cookie.name == name
            return cookie.value
        end
    end
    return nothing
end

end
