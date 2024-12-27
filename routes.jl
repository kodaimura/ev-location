using Genie.Router

route("/") do
  serve_static_file("index.html")
end

route("/login") do
  serve_static_file("login.html")
end

route("/signup") do
  serve_static_file("signup.html")
end