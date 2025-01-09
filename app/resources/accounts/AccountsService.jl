module AccountsService

include("../core/Errors.jl")
include("../core/Jwt.jl")
include("Accounts.jl")

using Reexport
using SearchLight
import SHA
import Base64
import Dates

import .Jwt
import .Accounts: Account
@reexport using .Errors

function signup(account_name::String, account_password::String)
    try
        account = SearchLight.findone(Account, account_name = account_name)
        if !isnothing(account)
            throw(ConflictError())
        end
        account = Account(account_name=account_name, account_password=hash_password(account_password))
        SearchLight.save!(account)
    catch e
        handle_exception(e)
    end
end

function login(account_name::String, account_password::String)::Account
    try
        account = SearchLight.findone(Account, account_name = account_name)
        if isnothing(account)
            throw(UnauthorizedError())
        end
        if hash_password(account_password) != account.account_password
            throw(UnauthorizedError())
        end
        return account
    catch e
        handle_exception(e)
    end
end

function create_jwt(account::Account)::String
    payload = Dict(
        "id" => account.id.value, 
        "account_name" => account.account_name, 
        "exp" => string(Dates.now() + Dates.Month(3))
    )
    return Jwt.create(payload)
end

function hash_password(password::String)
    return Base64.base64encode(SHA.sha256(password))
end

end
