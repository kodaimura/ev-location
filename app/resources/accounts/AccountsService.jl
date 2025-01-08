module AccountsService

include("../core/Jwt.jl")
include("Accounts.jl")

using SearchLight
import SHA
import Base64
import Dates
import .Accounts: Account
import .Jwt

export signup, login

struct ConflictError <: Exception end
struct InternalError <: Exception end
struct UnauthorizedError <: Exception end

function signup(account_name::String, account_password::String)
    try
        account = SearchLight.findone(Account, account_name = account_name)
        if !nothing(account)
            throw(ConflictError())
        end
        account = Account(account_name=account_name, account_password=hash_password(account_password))
        SearchLight.save!(account)
    catch e
        @error "Error during signup: $e"
        throw(InternalError())
    end
end

function login(account_name::String, account_password::String)::Account
    try
        account = SearchLight.findone(Account, account_name = account_name)
        if nothing(account)
            throw(UnauthorizedError())
        end
        if hash_password(account_password) != account.account_password
            throw(UnauthorizedError())
        end
        return account
    catch e
        @error "Error during login: $e"
        throw(InternalError())
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

end
