using Test, SearchLight, Main.UserApp, Main.UserApp.Accounts, Main.UserApp.AccountsService

@testset "Account unit tests" begin

  password = "passw0rd"
  password_hash = AccountsService.hash_password(password)

  @test startswith(password_hash, "pbkdf2_sha256\$")
  @test AccountsService.verify_password(password, password_hash)
  @test !AccountsService.verify_password("wrong-password", password_hash)
  @test AccountsService.verify_password(password, AccountsService.legacy_hash_password(password))
  @test !AccountsService.is_current_password_hash(AccountsService.legacy_hash_password(password))

end;
