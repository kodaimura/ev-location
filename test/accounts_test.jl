using Test, SearchLight, Main.UserApp
using Main.UserApp.Accounts, Main.UserApp.AccountsController, Main.UserApp.AccountsService
using Main.UserApp.AccountsService.Jwt
using Genie.Renderer.Json

@testset "Account unit tests" begin

  ENV["JWT_SECRET"] = "test-jwt-secret"

  password = "passw0rd"
  password_hash = AccountsService.hash_password(password)

  @test startswith(password_hash, "pbkdf2_sha256\$")
  @test AccountsService.verify_password(password, password_hash)
  @test !AccountsService.verify_password("wrong-password", password_hash)
  @test AccountsService.verify_password(password, AccountsService.legacy_hash_password(password))
  @test !AccountsService.is_current_password_hash(AccountsService.legacy_hash_password(password))

  token = AccountsService.create_jwt(AccountsService.Account(id=SearchLight.DbId(1), account_name="tester"))
  @test Jwt.verify(token)

  original_env = get(ENV, "GENIE_ENV", "")
  try
    ENV["GENIE_ENV"] = "dev"
    @test !occursin("Secure", AccountsController.auth_cookie_header("token"))

    ENV["GENIE_ENV"] = "prod"
    @test occursin("Secure", AccountsController.auth_cookie_header("token"))
  finally
    ENV["GENIE_ENV"] = original_env
  end

  response = Genie.Renderer.Json.json(
    Dict("token" => token);
    status=200,
    headers=AccountsController.HTTP.Headers(["Set-Cookie" => AccountsController.auth_cookie_header(token)])
  )
  @test response.status == 200
  @test haskey(response.headers, "Set-Cookie")

end;
