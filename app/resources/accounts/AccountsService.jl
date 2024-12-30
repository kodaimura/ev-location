module AccountsService

include("../core/Jwt.jl")
include("Accounts.jl")

using SHA
using Dates
using Base64
using SearchLight
using .Accounts
import .Jwt

export signup, login, verify_token

function signup(account_name::String, account_password::String)
    account = Account(account_name=account_name, account_password=hash_password(account_password))
    try
        SearchLight.save!(account)
        return true, "Account created successfully"
    catch e
        return false, "Error creating account: $e"
    end
end

function login(account_name::String, account_password::String)
    account = SearchLight.findone(Account; account_name = account_name)
    if account === nothing
        return false, "Account not found"
    end

    if verify_password(account_password, account.account_password)
        payload = Dict("id" => account.id, "account_name" => account.account_name, "exp" => string(now() + Dates.Hour(1)))
        token = Jwt.create_jwt(payload)
        return true, token
    else
        return false, "Invalid credentials"
    end
end

function verify_token(token::String)
    valid, payload_or_error = Jwt.verify_jwt(token)
    if valid
        exp = DateTime(payload_or_error["exp"])
        if exp < now()
            return false, "Token expired"
        end
        return true, payload_or_error
    else
        return false, payload_or_error
    end
end

function hash_password(password::String)
    return Base64.base64encode(SHA.sha256(password))
end

function verify_password(password::String, hashed::String)
    return hash_password(password) == hashed
end

end