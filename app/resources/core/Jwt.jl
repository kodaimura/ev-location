module Jwt

import SHA: hmac_sha256
import Base64: base64encode, base64decode
import JSON

export create, verify

function base64url_encode(data::Vector{UInt8})::String
    return replace(base64encode(String(data)), r"\+" => "-", "/" => "_", "=" => "")
end

function base64url_decode(data::String)::Vector{UInt8}
    return base64decode(replace(data, "-" => "+", "_" => "/"))
end

function create(payload::Dict{String, Any})::String
    header = Dict("alg" => "HS256", "typ" => "JWT")
    header_encoded = base64url_encode(Vector{UInt8}(codeunits(JSON.json(header))))
    payload_encoded = base64url_encode(Vector{UInt8}(codeunits(JSON.json(payload))))
    secret_key = Vector{UInt8}(codeunits(ENV["JWT_SECRET"]))
    signature = hmac_sha256(secret_key, "$header_encoded.$payload_encoded")
    signature_encoded = base64url_encode(signature)
    return "$header_encoded.$payload_encoded.$signature_encoded"
end

function verify(token::AbstractString)::Tuple{Bool, Any}
    parts = split(token, ".")
    if length(parts) != 3
        return false, "Invalid token format: expected 3 parts separated by dots"
    end

    header_encoded, payload_encoded, signature_encoded = parts

    secret_key = Vector{UInt8}(ENV["JWT_SECRET"])
    expected_signature = hmac_sha256(secret_key, "$header_encoded.$payload_encoded")
    expected_signature_encoded = base64url_encode(expected_signature)

    if signature_encoded == expected_signature_encoded
        try
            payload = JSON.parse(String(Jwt.base64url_decode(payload_encoded)))
            return true, payload
        catch e
            return false, "Error decoding payload: $(e.message)"
        end
    else
        return false, "Invalid signature"
    end
end

end
