require IEx

defmodule MoneyBin.Schemas.JournalEntry do
  use MoneyBin, :schema

  schema @tables[:journal_entry] do
    belongs_to(:transaction, @schemas[:transaction])
    belongs_to(:ledger, @schemas[:ledger])

    field(:credit_amount, :decimal, default: nil)
    field(:debit_amount, :decimal, default: nil)

    timestamps()
  end

  @fields [:transaction_id, :ledger_id, :debit_amount, :credit_amount]
  @required_fields [:ledger_id]

  @doc false
  def changeset(entry \\ %__MODULE__{}, attrs) do
    entry
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> constrained_assoc_cast(:transaction)
    |> constrained_assoc_cast(:ledger)
    |> unique_constraint(:ledger_id, name: :journal_entries_transaction_id_ledger_id_index)
    |> validate_amounts
    |> validate_greater_than_zero
  end

  defp validate_greater_than_zero(%{valid?: false} = changeset), do: changeset

  defp validate_greater_than_zero(%{valid?: true, changes: changes} = changeset) do
    field = if changes[:debit_amount], do: :debit_amount, else: :credit_amount
    amount = changes[field]

    case D.cmp(amount, 0) do
      :gt -> changeset
      _ -> add_error(changeset, field, "must be greater than 0")
    end
  end

  defp validate_amounts(%{valid?: false} = changeset), do: changeset

  defp validate_amounts(%{valid?: true, changes: changes} = changeset) do
    cond do
      changes[:debit_amount] == nil && changes[:credit_amount] == nil ->
        add_error(changeset, :base, "debit_amount or credit_amount required")

      changes[:debit_amount] && changes[:credit_amount] ->
        add_error(
          changeset,
          :base,
          "credit_amount and debit_amount cannot be set on the same entry"
        )

      true ->
        changeset
    end
  end
end
