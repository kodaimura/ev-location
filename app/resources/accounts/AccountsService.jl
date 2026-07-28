module AccountsService

include("../core/Errors.jl")
include("../core/Jwt.jl")
include("Accounts.jl")

using Reexport
using SearchLight
import SHA: hmac_sha256, sha256
import Base64
import Dates
import Random

import .Jwt
import .Accounts: Account
@reexport using .Errors

const PASSWORD_HASH_ALGORITHM = "pbkdf2_sha256"
const PASSWORD_HASH_ITERATIONS = 210_000
const PASSWORD_SALT_BYTES = 16
const PASSWORD_HASH_BYTES = 32
const ACCESS_TOKEN_TTL_MINUTES = 15
const REFRESH_TOKEN_TTL_DAYS = 30

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
        if !verify_password(account_password, account.account_password)
            throw(UnauthorizedError())
        end
        if !is_current_password_hash(account.account_password)
            account.account_password = hash_password(account_password)
            SearchLight.save!(account)
        end
        return account
    catch e
        handle_exception(e)
    end
end

function change_password(account_id::Int32, current_password::String, new_password::String)
    try
        account = SearchLight.findone(Account, id = account_id)
        if isnothing(account) || !verify_password(current_password, account.account_password)
            throw(UnauthorizedError())
        end

        account.account_password = hash_password(new_password)
        SearchLight.save!(account)
    catch e
        handle_exception(e)
    end
end

function create_jwt(account::Account)::String
    return create_refresh_token(account)
end

function create_access_token(account::Account)::String
    payload = Dict(
        "id" => account.id.value, 
        "account_name" => account.account_name, 
        "token_type" => "access",
        "exp" => string(Dates.now() + Dates.Minute(ACCESS_TOKEN_TTL_MINUTES))
    )
    return Jwt.create(payload)
end

function create_refresh_token(account::Account)::String
    payload = Dict(
        "id" => account.id.value,
        "account_name" => account.account_name,
        "token_type" => "refresh",
        "exp" => string(Dates.now() + Dates.Day(REFRESH_TOKEN_TTL_DAYS))
    )
    return Jwt.create(payload)
end

function hash_password(password::String)
    salt = random_bytes(PASSWORD_SALT_BYTES)
    derived_key = pbkdf2_sha256(password, salt, PASSWORD_HASH_ITERATIONS, PASSWORD_HASH_BYTES)
    return join([
        PASSWORD_HASH_ALGORITHM,
        string(PASSWORD_HASH_ITERATIONS),
        Base64.base64encode(salt),
        Base64.base64encode(derived_key)
    ], "\$")
end

function verify_password(password::String, stored_hash::String)::Bool
    if is_current_password_hash(stored_hash)
        parts = split(stored_hash, "\$")
        iterations = parse(Int, parts[2])
        salt = Base64.base64decode(parts[3])
        expected_hash = Base64.base64decode(parts[4])
        actual_hash = pbkdf2_sha256(password, salt, iterations, length(expected_hash))
        return secure_compare(actual_hash, expected_hash)
    end

    return secure_compare(Vector{UInt8}(codeunits(legacy_hash_password(password))), Vector{UInt8}(codeunits(stored_hash)))
end

function is_current_password_hash(stored_hash::String)::Bool
    parts = split(stored_hash, "\$")
    return length(parts) == 4 && parts[1] == PASSWORD_HASH_ALGORITHM
end

function legacy_hash_password(password::String)::String
    return Base64.base64encode(sha256(password))
end

function random_bytes(length::Int)::Vector{UInt8}
    bytes = Vector{UInt8}(undef, length)
    Random.rand!(Random.RandomDevice(), bytes)
    return bytes
end

function pbkdf2_sha256(password::String, salt::Vector{UInt8}, iterations::Int, key_length::Int)::Vector{UInt8}
    iterations > 0 || throw(BadRequestError("Invalid password hash iterations."))
    key_length > 0 || throw(BadRequestError("Invalid password hash length."))

    password_bytes = Vector{UInt8}(codeunits(password))
    derived_key = UInt8[]
    block_index = UInt32(1)
    while length(derived_key) < key_length
        block = pbkdf2_block(password_bytes, salt, iterations, block_index)
        append!(derived_key, block)
        block_index += UInt32(1)
    end
    return derived_key[1:key_length]
end

function pbkdf2_block(password::Vector{UInt8}, salt::Vector{UInt8}, iterations::Int, block_index::UInt32)::Vector{UInt8}
    block_input = vcat(salt, UInt8[
        UInt8((block_index >> 24) & 0xff),
        UInt8((block_index >> 16) & 0xff),
        UInt8((block_index >> 8) & 0xff),
        UInt8(block_index & 0xff),
    ])
    u = hmac_sha256(password, block_input)
    result = copy(u)
    for _ in 2:iterations
        u = hmac_sha256(password, u)
        for i in eachindex(result)
            result[i] = xor(result[i], u[i])
        end
    end
    return result
end

function secure_compare(a::Vector{UInt8}, b::Vector{UInt8})::Bool
    diff = xor(length(a), length(b))
    for i in 1:min(length(a), length(b))
        diff |= xor(a[i], b[i])
    end
    return diff == 0
end

end
