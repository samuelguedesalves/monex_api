defmodule MonexApi.Users do
  @moduledoc """
  Module to operate entity Users
  """

  alias MonexApi.Repo
  alias MonexApi.Users.User
  alias MonexApiWeb.AuthToken

  require Logger

  @doc """
  create_user(params)

  example of the usage:

      params = %{
        "first_name" => "Samuel",
        "last_name" => "Guedes",
        "email" => "example@email.com",
        "balance" => 500000,
        "password" => "123456"
      }

      create_user(params)
  """
  @spec create_user(params :: Map.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(params) do
    Logger.info("user will be created with following parameters: #{inspect(params)}")

    params
    |> User.changeset_create()
    |> Repo.insert()
    |> case do
      {:ok, _user} = result ->
        Logger.info("user successfully created")
        result

      {:error, reason} = result ->
        Logger.error("error while creating user due: #{inspect(reason)}")
        result
    end
  end

  @doc """
  get_user_by_id(params)

  example of the usage:

      user_id = 99
      get_user_by_id(user_id)
  """
  @spec get_user_by_id(id :: Integer.t()) :: User.t() | nil
  def get_user_by_id(id) when is_integer(id) do
    Logger.info("user will be getted with following id: #{inspect(id)}")

    case Repo.get(User, id) do
      result when is_nil(result) ->
        Logger.error("user with id \"#{id}\" was not found")
        result

      result ->
        Logger.info("user with id \"#{id}\" was founded")
        result
    end
  end

  @doc """
  get_user_by_email(email)

  example of the usage:

      user_email = "example@email.com"
      get_user_by_email(user_email)
  """
  @spec get_user_by_email(email :: String.t()) :: User.t() | nil
  def get_user_by_email(email) when is_bitstring(email) do
    Logger.info("user will be getted with following email: #{inspect(email)}")

    case Repo.get_by(User, email: email) do
      nil ->
        Logger.error("user with email \"#{email}\" was not found")
        {:error, "user not found"}

      %User{} = user ->
        Logger.info("user with email \"#{email}\" was founded")
        {:ok, user}
    end
  end

  @doc """
  update_user_balance(user, new_balance)

  example of the usage:

      user = %User{}
      new_balance = 999_999
      update_user_balance(user, new_balance)
  """
  @spec update_user_balance(user :: User.t(), new_balance :: Integer.t()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def update_user_balance(%User{} = user, new_balance) do
    user
    |> User.changeset_update(%{balance: new_balance})
    |> Repo.update()
    |> case do
      {:ok, _user} = result ->
        Logger.info("user balance successfully updated")
        result

      {:error, reason} = result ->
        Logger.error("failed to update user balance due: #{inspect(reason)}")
        result
    end
  end

  @doc """
  update_user(user, attrs)

  example of the usage:

      user = %User{}
      attrs = %{
        "first_name" => "Samuel",
        "last_name" => "Guedes",
        "email" => "example@email.com",
        "balance" => 500000,
        "password" => "123456"
      }

      update_user(user, attrs)
  """
  @spec update_user(User.t(), Map.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset_update(attrs)
    |> Repo.update()
    |> case do
      {:ok, _} = result ->
        Logger.info("user successfully updated")
        result

      {:error, reason} = result ->
        Logger.error("failed to update user due: #{inspect(reason)}")
        result
    end
  end

  @doc """
  auth_user(email, password)

  example of the usage:

      email = "example@email.com"
      password = "123456"

      auth_user(user, password)
  """
  @spec auth_user(email :: String.t(), password :: String.t()) ::
          {:ok, %{user: User.t(), token: String.t()}} | {:error, :erro_while_authentication}
  def auth_user(email, password) when is_bitstring(email) and is_bitstring(password) do
    with {:ok, user} <- get_user_by_email(email),
         true <- Pbkdf2.verify_pass(password, user.password_hash),
         token when is_bitstring(token) <- AuthToken.create(user) do
      Logger.info("[USERS] user successfully authenticated")
      {:ok, %{user: user, token: token}}
    else
      error ->
        Logger.error("failed to authenticate user due: #{inspect(error)}")
        {:error, :erro_while_authentication}
    end
  end
end
