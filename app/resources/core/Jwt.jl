module Jwt

using SHA
using Base64
import JSON

export create_jwt, verify_jwt

function hmac_sha256(key::AbstractString, data::AbstractString)::String
    return hmac_sha256(data, key)
end

function base64urlencode(data::AbstractString)::String
    return replace(base64encode(data), r"\+" => "-", "/" => "_", "=" => "")
end

function base64urldecode(data::AbstractString)::Vector{UInt8}
    return base64decode(replace(data, "-" => "+", "_" => "/"))
end

function create_jwt(payload::Dict{String, Any}, secret::AbstractString)::String
    header = Dict("alg" => "HS256", "typ" => "JWT")
    header_encoded = base64urlencode(JSON.json(header))
    payload_encoded = base64urlencode(JSON.json(payload))
    signature = hmac_sha256(secret, "$header_encoded.$payload_encoded")
    signature_encoded = base64urlencode(signature)
    return "$header_encoded.$payload_encoded.$signature_encoded"
end

function verify_jwt(token::AbstractString, secret::AbstractString)::Tuple{Bool, Any}
    parts = split(token, ".")
    if length(parts) != 3
        return false, "Invalid token format: expected 3 parts separated by dots"
    end

    header_encoded, payload_encoded, signature_encoded = parts
    expected_signature = hmac_sha256(secret, "$header_encoded.$payload_encoded")
    expected_signature_encoded = base64urlencode(expected_signature)

    if signature_encoded == expected_signature_encoded
        try
            payload = JSON.parse(String(base64urldecode(payload_encoded)))
            return true, payload
        catch e
            return false, "Error decoding payload: $(e.message)"
        end
    else
        return false, "Invalid signature"
    end
end

end
