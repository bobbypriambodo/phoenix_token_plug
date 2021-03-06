defmodule PhoenixTokenPlug.VerifyHeaderTest do
  use ExUnit.Case, async: true

  import Plug.Conn

  alias PhoenixTokenPlug.VerifyHeader

  defmodule TokenEndpoint do
    def config(:secret_key_base), do: "abc123"
  end

  @user %{id: 1}

  test "does nothing if no token provided" do
    conn = conn() |> VerifyHeader.call([])
    assert conn.assigns[:user] == nil
    assert conn.assigns[:token] == nil
  end

  test "does nothing if signing salt is different" do
    conn = authorized_conn("user") |> VerifyHeader.call(salt: "not_user")
    assert conn.assigns[:user] == nil
    assert conn.assigns[:token] == nil
  end

  test "assigns user to conn if token valid" do
    conn = authorized_conn("user") |> VerifyHeader.call(salt: "user")
    assert conn.assigns.user == @user
  end

  test "assigns token to conn if token valid" do
    conn = authorized_conn("user") |> VerifyHeader.call(salt: "user")
    assert conn.assigns.token != nil
  end

  test "salt defaults to \"user\"" do
    conn = authorized_conn("user") |> VerifyHeader.call([])
    assert conn.assigns.user == @user
  end

  test "can use salt other than user" do
    conn = authorized_conn("other_salt") |> VerifyHeader.call(salt: "other_salt")
    assert conn.assigns.user == @user
  end

  test "can customize assign key" do
    conn = authorized_conn() |> VerifyHeader.call(key: :foo)
    assert conn.assigns.foo == @user
  end

  defp authorized_conn(salt \\ "user") do
    token = get_token(conn(), salt, @user)
    conn() |> put_req_header("authorization", "Bearer #{token}")
  end

  defp conn do
    %Plug.Conn{} |> Plug.Conn.put_private(:phoenix_endpoint, TokenEndpoint)
  end

  defp get_token(conn, salt, payload) do
    Phoenix.Token.sign(conn, salt, payload)
  end

end
