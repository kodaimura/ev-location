using Genie.Router
using Genie.Requests
using Genie.Cookies
using Genie.Renderer
using Genie.Renderer.Json
using HTTP
import .Jwt
import .CommonsController
import .FacilitiesController
import .ScoresController

route("/") do
  #is_authorized()
  return serve_static_file("index.html")
end

route("/login") do
  return serve_static_file("login.html")
end

route("/signup") do
  return serve_static_file("signup.html")
end

route("/api/login", method="POST") do
  return AccountsController.login(get_context())
end

route("/api/signup", method="POST") do
  return AccountsController.signup(get_context())
end

route("/api/handover", method="POST") do
  return CommonsController.handover(get_context())
end

route("/api/accounts/me") do
  if is_authorized()
    payload = get_context()["payload"]
    return Genie.Renderer.Json.json(Dict("id" => payload["id"], "account_name" => payload["account_name"]); status=200)
  end
  return Genie.Renderer.Json.json(Dict(); status=401)
end

route("/api/guest/:guest_code/facilities") do
  return FacilitiesController.guest_get(get_context(), params(:guest_code))
end

route("/api/guest/:guest_code/facilities", method="POST") do
  return FacilitiesController.guest_post(get_context(), params(:guest_code))
end

route("/api/guest/:guest_code/scores") do
  return ScoresController.guest_get(get_context(), params(:guest_code))
end

route("/api/guest/:guest_code/scores", method="POST") do
  return ScoresController.guest_post(get_context(), params(:guest_code))
end

route("/api/guest/:guest_code/scores/:id", method="DELETE") do
  return ScoresController.guest_delete(get_context(), params(:guest_code), params(:id))
end

#
#route("/api/facilities", method="POST") do
#  return FacilitiesController.post(get_context())
#end

###################################################################################################
function redirect_login()
  Genie.Renderer.redirect("login")
end

function json_unauthorized()
  Genie.Renderer.Json.json(Dict(); status=401)
end

function get_context()::Dict{String, Any}
  cookie = Genie.Cookies.getcookies(Genie.Requests.request())
  token = get_cookie_value(cookie, "token")
  ctx = Dict{String, Any}()
  ctx["payload"] = Jwt.decode_payload(token)
  return ctx
end

function is_authorized()::Bool
  cookie = Genie.Cookies.getcookies(Genie.Requests.request())
  token = get_cookie_value(cookie, "token")
  if isnothing(token)
    return false
  end

  try
    return Jwt.verify(token)
  catch e
    return false
  end
end

function get_cookie_value(cookies::Vector{HTTP.Cookies.Cookie}, name::String)::Union{String, Nothing}
  for cookie in cookies
    if cookie.name == name
      return cookie.value
    end
  end
  return nothing
end
###################################################################################################