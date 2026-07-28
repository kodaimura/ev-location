using Test, SearchLight, Main.UserApp, Dates
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

  account = AccountsService.Account(id=SearchLight.DbId(1), account_name="tester")
  access_token = AccountsService.create_access_token(account)
  refresh_token = AccountsService.create_refresh_token(account)
  access_payload = Jwt.verified_payload(access_token; token_type="access")
  refresh_payload = Jwt.verified_payload(refresh_token; token_type="refresh")

  @test Jwt.verify(access_token; token_type="access")
  @test !Jwt.verify(access_token; token_type="refresh")
  @test Jwt.verify(refresh_token; token_type="refresh")
  @test !Jwt.verify(refresh_token; token_type="access")
  @test access_payload["id"] == 1
  @test refresh_payload["id"] == 1
  @test Dates.DateTime(access_payload["exp"]) <= Dates.now() + Dates.Minute(AccountsService.ACCESS_TOKEN_TTL_MINUTES + 1)
  @test Dates.DateTime(refresh_payload["exp"]) <= Dates.now() + Dates.Day(AccountsService.REFRESH_TOKEN_TTL_DAYS) + Dates.Minute(1)

  original_env = get(ENV, "GENIE_ENV", "")
  try
    ENV["GENIE_ENV"] = "dev"
    @test !occursin("Secure", AccountsController.auth_cookie_header("token"))
    @test startswith(AccountsController.auth_cookie_header("token"), "refresh_token=token")
    @test occursin("Max-Age=2592000", AccountsController.auth_cookie_header("token"; max_age=AccountsController.REFRESH_TOKEN_MAX_AGE_SECONDS))

    ENV["GENIE_ENV"] = "prod"
    @test occursin("Secure", AccountsController.auth_cookie_header("token"))
  finally
    ENV["GENIE_ENV"] = original_env
  end

  response = Genie.Renderer.Json.json(
    AccountsController.access_token_response(access_token);
    status=200,
    headers=AccountsController.HTTP.Headers(["Set-Cookie" => AccountsController.auth_cookie_header(refresh_token)])
  )
  @test response.status == 200
  @test haskey(response.headers, "Set-Cookie")

end;
