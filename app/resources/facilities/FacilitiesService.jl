module FacilitiesService

include("Facilities.jl")

import SearchLight
import .Facilities: Facility

export guest_get, guest_post

function guest_get(guest_code::AbstractString)::Tuple{Union{Facility, Nothing}, Bool}
    try
        facility = SearchLight.findone(Facility; guest_code = guest_code)
        return facility, true
    catch e
        return nothing, false
    end
end

function guest_post(guest_code::AbstractString, facilities_data::String)::Bool
    existing_facility = SearchLight.findone(Facility; guest_code = guest_code)

    try
        if existing_facility !== nothing
            existing_facility.facilities_data = facilities_data
            SearchLight.save!(existing_facility)
        else
            facility = Facility(guest_code=guest_code, facilities_data=facilities_data)
            SearchLight.save!(facility)
        end
        return true
    catch e
        return false
    end
end

end