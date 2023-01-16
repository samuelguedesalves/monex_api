alias MonexApi.{User, Repo}

user_params = %{email: "admin@monex.com", name: "admin", password: "123456", amount: 200_000_000}

user_params |> User.changeset_create() |> Repo.insert!()
