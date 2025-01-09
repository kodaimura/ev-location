module FacilitiesService

include("../core/Errors.jl")
include("Facilities.jl")

using Reexport
using SearchLight

import .Facilities: Facility
@reexport using .Errors

function get(account_id::Int32)::Facility
    try
        facility = SearchLight.findone(Facility, account_id = account_id)
        if isnothing(facility)
            throw(NotFoundError())
        end
        return facility
    catch e
        handle_exception(e)
    end
end

function post(account_id::Int32, facilities_data::String)
    try
        facility = SearchLight.findone(Facility, account_id = account_id)
        if isnothing(facility)
            facility = Facility(account_id=account_id, facilities_data=facilities_data)
            SearchLight.save!(facility)
        else
            facility.facilities_data = facilities_data
            SearchLight.save!(facility)
        end
    catch e
        handle_exception(e)
    end
end

function guest_get(guest_code::AbstractString)::Facility
    try
        facility = SearchLight.findone(Facility, guest_code = guest_code)
        if isnothing(facility)
            throw(NotFoundError())
        end
        return facility
    catch e
        handle_exception(e)
    end
end

function guest_post(guest_code::AbstractString, facilities_data::String)
    try
        facility = SearchLight.findone(Facility, guest_code = guest_code)
        if isnothing(facility)
            facility = Facility(guest_code=guest_code, facilities_data=facilities_data)
            SearchLight.save!(facility)
        else
            facility.facilities_data = facilities_data
            SearchLight.save!(facility)
        end
    catch e
        handle_exception(e)
    end
end

end