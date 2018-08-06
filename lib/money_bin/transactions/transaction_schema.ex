defmodule MoneyBin.Schemas.Transaction do
  use MoneyBin, :schema

  schema @tables[:transaction] do
    has_many(:entries, @schemas[:journal_entry])

    belongs_to(
      :reversed_transaction,
      @schemas[:transaction],
      foreign_key: :reversal_for_transaction_id
    )

    field(:amount, :decimal)

    timestamps()
  end

  @fields [:reversal_for_transaction_id]

  @doc false
  def changeset(transaction \\ %__MODULE__{}, attrs) do
    transaction
    |> cast(attrs, @fields)
    |> constrained_assoc_cast(:reversed_transaction)
    |> unique_constraint(:reversal_for_transaction_id)
    |> cast_assoc(:entries, required: true)
    |> validate_length(:entries, min: 2)
    |> validate_amount
  end

  defp validate_amount(%{valid?: false} = changeset), do: changeset

  defp validate_amount(%{valid?: true, changes: changes} = changeset) do
    entries = changes[:entries] |> Enum.map(& &1.changes)
    debits = amount_sum(entries, :debit_amount)
    credits = amount_sum(entries, :credit_amount)

    if D.equal?(debits, credits) do
      put_change(changeset, :amount, debits)
    else
      add_error(changeset, :entries, "debit total must equal credit total")
    end
  end

  defp amount_sum(entries, key),
    do:
      entries
      |> Enum.map(fn x -> x[key] || D.new("0") end)
      |> Enum.reduce(&D.add/2)
end