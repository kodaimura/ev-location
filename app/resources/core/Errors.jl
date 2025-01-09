module Errors

import Genie.Renderer.Json as RendererJson
import HTTP
import JSON

export handle_exception, json_error_response
export ExpectedError, UnexpectedError
export BadRequestError, UnauthorizedError, ForbiddenError, NotFoundError, ConflictError
export InternalServerError, ServiceUnavailableError

abstract type ExpectedError <: Exception end
abstract type UnexpectedError <: Exception end

mutable struct BadRequestError <: ExpectedError
    message::String
end
mutable struct UnauthorizedError <: ExpectedError end
mutable struct ForbiddenError <: ExpectedError end 
mutable struct NotFoundError <: ExpectedError end
mutable struct ConflictError <: ExpectedError end

mutable struct InternalServerError <: UnexpectedError end
mutable struct ServiceUnavailableError <: UnexpectedError end

# サービス層用のエラーハンドリング
function handle_exception(e::Exception)
    if e isa ExpectedError
        throw(e)
    else
        @error "$e"
        throw(InternalServerError())
    end
end

# コントローラ層用のJSONレスポンスエラーハンドリング
function json_error_response(e::Exception, request::HTTP.Request)
    status_code = get_status_code(e)
    message = get_error_message(e)
    if e isa UnexpectedError
        @error "request: $request"
    end
    return RendererJson.json(Dict("error" => message); status=status_code)
end

function get_status_code(e::Exception)
    if e isa BadRequestError
        return 400
    elseif e isa UnauthorizedError
        return 401
    elseif e isa ForbiddenError
        return 403
    elseif e isa NotFoundError
        return 404
    elseif e isa ConflictError
        return 409
    elseif e isa InternalServerError
        return 500
    elseif e isa ServiceUnavailableError
        return 503
    else
        return 500
    end
end

function get_error_message(e::Exception)
    if e isa ExpectedError
        if e isa BadRequestError
            return "Bad request. $(e.message)"
        elseif e isa UnauthorizedError
            return "Unauthorized access."
        elseif e isa ForbiddenError
            return "Forbidden action."
        elseif e isa NotFoundError
            return "Resource not found."
        elseif e isa ConflictError
            return "Conflict with existing resource."
        else
            return "Expected error."
        end
    elseif e isa UnexpectedError
        if e isa InternalServerError
            return "Server error."
        elseif e isa ServiceUnavailableError
            return "Service unavailable."
        else
            return "Unexpected error."
        end
    else
        return "Unknown error."
    end
end

end