include("./app/resources/controllers/AccountController.jl")

using Genie.Router
using Genie.Requests
import .AccountController

route("/") do
  serve_static_file("index.html")
end

route("/login") do
  serve_static_file("login.html")
end

route("/signup") do
  serve_static_file("signup.html")
end

route("/api/login", method="POST") do
  request = Genie.Requests.jsonpayload()
  AccountController.login(request)
end

route("/api/signup", method="POST") do
  request = Genie.Requests.jsonpayload()
  println(typeof(request))
  AccountController.signup(request)
end

route("/verify-token", method="POST") do
  request = Genie.Requests.jsonpayload()
  AccountController.verify_token(request)
end