include("./app/resources/accounts/AccountsController.jl")

using Genie.Router
using Genie.Requests
import .AccountsController

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
  AccountsController.login(request)
end

route("/api/signup", method="POST") do
  request = Genie.Requests.jsonpayload()
  println(typeof(request))
  AccountsController.signup(request)
end

route("/verify-token", method="POST") do
  request = Genie.Requests.jsonpayload()
  AccountsController.verify_token(request)
end