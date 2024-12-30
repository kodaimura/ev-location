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
  AccountsController.login()
end

route("/api/signup", method="POST") do
  AccountsController.signup()
end

route("/verify-token", method="POST") do
  AccountsController.verify_token()
end