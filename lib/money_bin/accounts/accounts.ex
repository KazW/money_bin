defmodule MoneyBin.Accounts do
  use MoneyBin, :service

  @moduledoc """
  This module is the primary interface for creating and retrieving accounts.
  It also contains a query that can be used for preloading ecto associations with aggregate data.
  """

  @doc """
  Creates a `MoneyBin.Account`.

  ## Examples

      iex> MoneyBin.Accounts.create()
      %MoneyBin.Account{}

  """
  def create(attrs \\ %{}), do: attrs |> @schemas[:account].changeset |> @repo.insert!

  @doc """
  Retrieves a `MoneyBin.Account` with the aggregate data included, uses `account_query/0`.

  ## Examples

      iex> MoneyBin.Accounts.find(account_id)
      %MoneyBin.Account{}

  """
  def find(%_{account_id: id}), do: find(id)
  def find(id), do: account_query() |> where([account], account.id == ^id) |> @repo.one

  @doc """
  An `Ecto.Query` to retrieve the aggregate information for an account.

  ## Examples

      iex> MoneyBin.Accounts.account_query()
      %Ecto.Query{}

  """
  def account_query,
    do:
      from(
        account in @schemas[:account],
        left_join: entry in assoc(account, :entries),
        group_by: account.id,
        select_merge: %{
          debit_total: coalesce(sum(entry.debit_amount), 0),
          credit_total: coalesce(sum(entry.credit_amount), 0),
          balance:
            fragment(
              "? - ?",
              coalesce(sum(entry.debit_amount), 0),
              coalesce(sum(entry.credit_amount), 0)
            ),
          entry_count: count(entry.id)
        }
      )
end
