defmodule Monex.Users do
  @moduledoc """
  Module to operate entity Users
  """

  alias Monex.Repo
  alias Monex.Users.Email
  alias Monex.Users.User
  alias MonexWeb.AuthToken

  require Logger

  @doc """
  create_user(params)

  # Example of the usage:

      iex> params = %{
            "first_name" => "Samuel",
            "last_name" => "Guedes",
            "email" => "example@email.com",
            "balance" => 500000,
            "password" => "123456"
          }

      iex> create_user(params)
  """
  @spec create_user(params :: Map.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(params) do
    Logger.info("user will be created with following parameters: #{inspect(params)}")

    params
    |> User.changeset_create()
    |> Repo.insert()
    |> case do
      {:ok, user} = result ->
        Email.welcome(user)
        Logger.info("user successfully created")
        result

      {:error, reason} = result ->
        Logger.error("error while creating user due: #{inspect(reason)}")
        result
    end
  end

  @doc """
  get_user_by_id(params)

  # Example of the usage:

      iex> user_id = 99
      iex> get_user_by_id(user_id)
      %User{} | nil
  """
  @spec get_user_by_id(id :: Integer.t()) :: User.t() | nil
  def get_user_by_id(id) when is_integer(id) do
    Logger.info("user will be read with following id: #{inspect(id)}")

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

  # Example of the usage:

      iex> user_email = "example@email.com"
      iex> get_user_by_email(user_email)
      %User{} | nil
  """
  @spec get_user_by_email(email :: String.t()) :: User.t() | nil
  def get_user_by_email(email) when is_bitstring(email) do
    Logger.info("user will be read with following email: #{inspect(email)}")

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

  # Example of the usage:

      iex> user = %User{}
      iex> new_balance = 999_999
      iex> update_user_balance(user, new_balance)
      {:ok, %User{}} | {:error, %Ecto.Changeset{}}
  """
  @spec update_user_balance(user :: User.t(), new_balance :: Integer.t()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
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

  # Example of the usage:

      iex> user = %User{}
      iex> attrs = %{
            "first_name" => "Samuel",
            "last_name" => "Guedes",
            "email" => "example@email.com",
            "balance" => 500000,
            "password" => "123456"
          }
      iex> update_user(user, attrs)
      {:ok, %User{}} | {:error, %Ecto.Changeset{}}
  """
  @spec update_user(User.t(), Map.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
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

  # Example of the usage:

      iex> email = "example@email.com"
      iex> password = "123456"
      iex> auth_user(user, password)
      {:ok, %{user: %User{}, token: "..."}} | {:error, reason}
  """
  @spec auth_user(email :: String.t(), password :: String.t()) ::
          {:ok, %{user: User.t(), token: String.t()}} | {:error, :error_while_authentication}
  def auth_user(email, password) when is_bitstring(email) and is_bitstring(password) do
    with {:ok, user} <- get_user_by_email(email),
         true <- Pbkdf2.verify_pass(password, user.password_hash),
         token when is_bitstring(token) <- AuthToken.create(user) do
      Logger.info("[USERS] user successfully authenticated")
      {:ok, %{user: user, token: token}}
    else
      error ->
        Logger.error("failed to authenticate user due: #{inspect(error)}")
        {:error, :error_while_authentication}
    end
  end
end
