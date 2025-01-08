(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using EvLoc
const UserApp = EvLoc
EvLoc.main()
