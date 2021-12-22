defmodule Stellar.TxBuild.SetOptions do
  @moduledoc """
  Sets various configuration options for an account.
  """
  alias Stellar.TxBuild.{
    Flags,
    OpValidate,
    OptionalAccount,
    OptionalAccountID,
    OptionalFlags,
    OptionalString32,
    OptionalSigner,
    OptionalString32,
    OptionalWeight,
    Signer,
    String32,
    Weight
  }

  alias StellarBase.XDR.{OperationBody, OperationType, Operations.SetOptions}

  @behaviour Stellar.TxBuild.XDR

  @type component :: {atom(), any()}
  @type validation :: {:ok, any()} | {:error, Keyword.t()}

  @type t :: %__MODULE__{
          inflation_destination: OptionalAccountID.t(),
          clear_flags: OptionalFlags.t(),
          set_flags: OptionalFlags.t(),
          master_weight: OptionalWeight.t(),
          low_threshold: OptionalWeight.t(),
          medium_threshold: OptionalWeight.t(),
          high_threshold: OptionalWeight.t(),
          home_domain: OptionalString32.t(),
          signer: OptionalSigner.t(),
          source_account: OptionalAccount.t()
        }

  defstruct [
    :inflation_destination,
    :clear_flags,
    :set_flags,
    :master_weight,
    :low_threshold,
    :medium_threshold,
    :high_threshold,
    :home_domain,
    :signer,
    :source_account
  ]

  @impl true
  def new(args, opts \\ [])

  def new(args, _opts) when is_list(args) do
    inf_dest = Keyword.get(args, :inflation_destination)
    clear_flags = Keyword.get(args, :clear_flags)
    set_flags = Keyword.get(args, :set_flags)
    master_weight = Keyword.get(args, :master_weight)
    low_threshold = Keyword.get(args, :low_threshold)
    med_threshold = Keyword.get(args, :medium_threshold)
    high_threshold = Keyword.get(args, :high_threshold)
    home_domain = Keyword.get(args, :home_domain)
    signer = Keyword.get(args, :signer)
    source_account = Keyword.get(args, :source_account)

    with {:ok, inf_dest} <- validate(:account_id, {:inflation_destination, inf_dest}),
         {:ok, clear_flags} <- validate(:flags, {:clear_flags, clear_flags}),
         {:ok, set_flags} <- validate(:flags, {:set_flags, set_flags}),
         {:ok, master_weight} <- validate(:weight, {:master_weight, master_weight}),
         {:ok, low_threshold} <- validate(:weight, {:low_threshold, low_threshold}),
         {:ok, med_threshold} <- validate(:weight, {:medium_threshold, med_threshold}),
         {:ok, high_threshold} <- validate(:weight, {:high_threshold, high_threshold}),
         {:ok, home_domain} <- validate(:string32, {:home_domain, home_domain}),
         {:ok, signer} <- validate(:signer, {:signer, signer}),
         {:ok, source_account} <- validate(:account, {:source_account, source_account}) do
      %__MODULE__{
        inflation_destination: inf_dest,
        clear_flags: clear_flags,
        set_flags: set_flags,
        master_weight: master_weight,
        low_threshold: low_threshold,
        medium_threshold: med_threshold,
        high_threshold: high_threshold,
        home_domain: home_domain,
        signer: signer,
        source_account: source_account
      }
    end
  end

  def new(_args, _opts), do: {:error, :invalid_operation_attributes}

  @impl true
  def to_xdr(%__MODULE__{
        inflation_destination: inf_dest,
        clear_flags: clear_flags,
        set_flags: set_flags,
        master_weight: master_weight,
        low_threshold: low_threshold,
        medium_threshold: med_threshold,
        high_threshold: high_threshold,
        home_domain: home_domain,
        signer: signer
      }) do
    op_type = OperationType.new(:SET_OPTIONS)
    inflation_destination = OptionalAccountID.to_xdr(inf_dest)
    clear_flags = OptionalFlags.to_xdr(clear_flags)
    set_flags = OptionalFlags.to_xdr(set_flags)
    master_weight = OptionalWeight.to_xdr(master_weight)
    low_threshold = OptionalWeight.to_xdr(low_threshold)
    med_threshold = OptionalWeight.to_xdr(med_threshold)
    high_threshold = OptionalWeight.to_xdr(high_threshold)
    home_domain = OptionalString32.to_xdr(home_domain)
    signer = OptionalSigner.to_xdr(signer)

    set_options =
      SetOptions.new(
        inflation_destination,
        clear_flags,
        set_flags,
        master_weight,
        low_threshold,
        med_threshold,
        high_threshold,
        home_domain,
        signer
      )

    OperationBody.new(set_options, op_type)
  end

  @spec validate(type :: atom(), component :: component()) :: validation()
  defp validate(:account_id, component) do
    OpValidate.validate_optional_account_id(component)
  end

  defp validate(:account, component) do
    OpValidate.validate_optional_account(component)
  end

  defp validate(:flags, {_field, nil}), do: {:ok, OptionalFlags.new()}

  defp validate(:flags, {field, value}) do
    case Flags.new(value) do
      %Flags{} = flags -> {:ok, OptionalFlags.new(flags)}
      {:error, reason} -> {:error, [{field, reason}]}
    end
  end

  defp validate(:weight, {_field, nil}), do: {:ok, OptionalWeight.new()}

  defp validate(:weight, {field, value}) do
    case Weight.new(value) do
      %Weight{} = weight -> {:ok, OptionalWeight.new(weight)}
      {:error, reason} -> {:error, [{field, reason}]}
    end
  end

  defp validate(:string32, {_field, nil}), do: {:ok, OptionalString32.new()}

  defp validate(:string32, {field, value}) do
    case String32.new(value) do
      %String32{} = str -> {:ok, OptionalString32.new(str)}
      {:error, reason} -> {:error, [{field, reason}]}
    end
  end

  defp validate(:signer, {_field, nil}), do: {:ok, OptionalSigner.new()}

  defp validate(:signer, {field, value}) do
    case Signer.new(value) do
      %Signer{} = signer -> {:ok, OptionalSigner.new(signer)}
      {:error, reason} -> {:error, [{field, reason}]}
    end
  end
end