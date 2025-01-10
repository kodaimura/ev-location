(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using EvLocation
const UserApp = EvLocation
EvLocation.main()
