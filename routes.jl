using Genie.Router
using Genie.Requests
using Genie.Cookies
using Genie.Renderer
using Genie.Renderer.Json
using HTTP

route("/") do
  #is_authorized() || return json_unauthorized()
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

route("/api/logout", method="POST") do
  return AccountsController.logout(get_context())
end

route("/api/refresh", method="POST") do
  return AccountsController.refresh(get_context())
end

route("/api/signup", method="POST") do
  return AccountsController.signup(get_context())
end

route("/api/handover", method="POST") do
  is_authorized() || return json_unauthorized()
  return CommonsController.handover(get_context())
end

route("/api/maps/config") do
  return CommonsController.maps_config()
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

route("/api/facilities") do
  is_authorized() || return json_unauthorized()
  return FacilitiesController.get(get_context())
end

route("/api/facilities", method="POST") do
  is_authorized() || return json_unauthorized()
  return FacilitiesController.post(get_context())
end

route("/api/scores") do
  is_authorized() || return json_unauthorized()
  return ScoresController.get(get_context())
end

route("/api/scores", method="POST") do
  is_authorized() || return json_unauthorized()
  return ScoresController.post(get_context())
end

route("/api/scores/:id", method="DELETE") do
  is_authorized() || return json_unauthorized()
  return ScoresController.delete(get_context(), params(:id))
end

###################################################################################################
function redirect_login()
  Genie.Renderer.redirect("login")
end

function json_unauthorized()
  Genie.Renderer.Json.json(Dict(); status=401)
end

function get_context()::Dict{String, Any}
  ctx = Dict{String, Any}()
  token = get_bearer_token()
  if !isnothing(token)
    payload = Jwt.verified_payload(token; token_type="access")
    if !isnothing(payload)
      ctx["payload"] = payload
    end
  end
  return ctx
end

function is_authorized()::Bool
  token = get_bearer_token()
  if isnothing(token)
    return false
  end

  try
    return Jwt.verify(token; token_type="access")
  catch e
    return false
  end
end

function get_bearer_token()::Union{String, Nothing}
  authorization = HTTP.header(Genie.Requests.request(), "Authorization", "")
  prefix = "Bearer "
  if startswith(authorization, prefix)
    return strip(authorization[length(prefix)+1:end])
  end
  return nothing
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
