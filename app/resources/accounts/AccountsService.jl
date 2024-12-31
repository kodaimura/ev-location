module AccountsService

include("../core/Jwt.jl")
include("Accounts.jl")

import SHA
import Base64
import Dates
import SearchLight
import .Accounts: Account
import .Jwt

export signup, login

function signup(account_name::String, account_password::String)::Bool
    account = Account(account_name=account_name, account_password=hash_password(account_password))
    try
        SearchLight.save!(account)
        return true
    catch e
        return false
    end
end

function login(account_name::String, account_password::String)::Union{Nothing, Account}
    account = SearchLight.findone(Account; account_name = account_name)
    if account === nothing
        return nothing
    end

    if verify_password(account_password, account.account_password)
        return account
    else
        return nothing
    end
end

function create_jwt(account::Account)::String
    payload = Dict("id" => account.id, "account_name" => account.account_name, "exp" => string(Dates.now() + Dates.Hour(1)))
    return Jwt.create(payload)
end

function hash_password(password::String)
    return Base64.base64encode(SHA.sha256(password))
end

function verify_password(password::String, hashed::String)
    return hash_password(password) == hashed
end

end