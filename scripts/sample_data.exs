# Run with `mix run sample_data.exs`
# Generates some sample data for development mode

defmodule SampleData do
  def checksum(package) do
    :crypto.hash(:sha256, package) |> Base.encode16
  end

  def create_user(username, email, password) do
    case HexWeb.User.create(%{username: username, email: email, password: password}, true) do
      {:ok, user} ->
        user
      {:error, error} ->
        IO.puts "creating user '#{username}' failed: #{inspect error}"
        nil
    end
  end
end

alias HexWeb.Package
alias HexWeb.Release
alias HexWeb.Stats.Download
alias HexWeb.Stats.PackageDownload
alias HexWeb.Stats.ReleaseDownload

lorem = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

HexWeb.Repo.transaction(fn ->
  eric = SampleData.create_user("eric", "eric@example.com", "eric")
  jose = SampleData.create_user("jose", "jose@example.com", "jose")

  if eric == nil or jose == nil do
    IO.puts "\nThere has been an error creating the sample users.\nIf the error says '... already taken' hex_web was probably already set up."
  end

  unless eric == nil do
    {:ok, decimal} =
      Package.create(eric, %{
        name: "decimal",
        meta: %{
          contributors: ["Eric Meadows-Jönsson"],
          licenses: ["Apache 2.0", "MIT"],
          links: %{"Github" => "http://example.com/github",
                   "Documentation" => "http://example.com/documentation"},
          description: "Arbitrary precision decimal arithmetic for Elixir"}})

    {:ok, _} = Release.create(decimal, %{version: "0.0.1", app: "decimal"}, SampleData.checksum("decimal 0.0.1"))
    {:ok, _} = Release.create(decimal, %{version: "0.0.2", app: "decimal"}, SampleData.checksum("decimal 0.0.2"))
    {:ok, _} = Release.create(decimal, %{version: "0.1.0", app: "decimal"}, SampleData.checksum("decimal 0.1.0"))

    {:ok, postgrex} =
      Package.create(eric, %{
        name: "postgrex",
        meta: %{
          contributors: ["Eric Meadows-Jönsson", "José Valim"],
          licenses: ["Apache 2.0"],
          links: %{"Github" => "http://example.com/github"},
          description: lorem}})

    {:ok, _} = Release.create(postgrex, %{version: "0.0.1", app: "postgrex"}, SampleData.checksum("postgrex 0.0.1"))
    {:ok, _} = Release.create(postgrex, %{version: "0.0.2", app: "postgrex", requirements: %{decimal: "~> 0.0.1"}}, SampleData.checksum("postgrex 0.0.2"))
    {:ok, _} = Release.create(postgrex, %{version: "0.1.0", app: "postgrex", requirements: %{decimal: "0.1.0"}}, SampleData.checksum("postgrex 0.1.0"))
  end

  unless jose == nil do
    {:ok, ecto} =
      Package.create(jose, %{
        name: "ecto",
        meta: %{
          contributors: ["Eric Meadows-Jönsson", "José Valim"],
          licenses: [],
          links: %{"Github" => "http://example.com/github"},
          description: lorem}})

    {:ok, _}   = Release.create(ecto, %{version: "0.0.1", app: "ecto"}, SampleData.checksum("ecto 0.0.1"))
    {:ok, _}   = Release.create(ecto, %{version: "0.0.2", app: "ecto", requirements: %{postgrex: "~> 0.0.1"}}, SampleData.checksum("ecto 0.0.2"))
    {:ok, _}   = Release.create(ecto, %{version: "0.1.0", app: "ecto", requirements: %{postgrex: "~> 0.0.2"}}, SampleData.checksum("ecto 0.1.0"))
    {:ok, _}   = Release.create(ecto, %{version: "0.1.1", app: "ecto", requirements: %{postgrex: "~> 0.1.0"}}, SampleData.checksum("ecto 0.1.1"))
    {:ok, _}   = Release.create(ecto, %{version: "0.1.2", app: "ecto", requirements: %{postgrex: "== 0.1.0", decimal: "0.0.1"}}, SampleData.checksum("ecto 0.1.2"))
    {:ok, _}   = Release.create(ecto, %{version: "0.1.3", app: "ecto", requirements: %{postgrex: "0.1.0", decimal: "0.0.2"}}, SampleData.checksum("ecto 0.1.3"))
    {:ok, rel} = Release.create(ecto, %{version: "0.2.0", app: "ecto", requirements: %{postgrex: "~> 0.1.0", decimal: "~> 0.1.0"}}, SampleData.checksum("ecto 0.2.0"))

    yesterday = Ecto.Type.load!(Ecto.Date, HexWeb.Util.yesterday)
    %Download{release_id: rel.id, downloads: 42, day: yesterday}
    |> HexWeb.Repo.insert
  end

  PackageDownload.refresh
  ReleaseDownload.refresh
end)
