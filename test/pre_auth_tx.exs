defmodule Stellar.PreAuthTx do
  use ExUnit.Case

  alias StellarBase.XDR.{
    VariableOpaque64,
    UInt256,
    SignerKeyEd25519SignedPayload
  }

  alias StellarBase.StrKey

  setup do
    # ACCOUNT 1
    # Public Key	GBKF3TWYI73TZLO4SX4CG5EONLJW523356YWGLZ2IUCAOMFA65IEJXF7
    # Secret Key	SAJFIOMK7L7GFGDZLNLCHZ7UOBOQS64BH43A6BZUTOQR5G3GL7JKH4TB

    # ACCOUNT 2
    # Public Key  GBCMLJLRMNC4SXGOOD7ZQTGWB5N3YA7CYHHBGJWIUTC5TB2RRSPWRHQZ
    # Secret Key  SBEQE23AMLO3EX6HGAL54TGZOUVJIFMT44KYQNPK3DLQVD75NORQ343Q
    {pk1, sk1} =
      keypair1 = {
        "GBF2MB6MFY52Z7OPKHFBIOBE5JOUOZH4NI6AWVC3CRPTGETT3Q7BNK63",
        "SBV3ZTORJG6SI3NYDFZBL5EPFUGNWEPE3HS3WOMDUBDPWC3WBYKET4XA"
      }

    {pk2, sk2} =
      keypair2 = {
        "GBCMLJLRMNC4SXGOOD7ZQTGWB5N3YA7CYHHBGJWIUTC5TB2RRSPWRHQZ",
        "SBEQE23AMLO3EX6HGAL54TGZOUVJIFMT44KYQNPK3DLQVD75NORQ343Q"
      }

    %{
      keypair1: keypair1,
      keypair2: keypair2,
      time_bounds: Stellar.TxBuild.TimeBounds.new()
    }
  end

  test "payment using signature of pre_auth_tx", %{
    keypair1: {pk1, sk1} = keypair1,
    keypair2: {pk2, sk2},
    time_bounds: time_bounds
  } do
    source_account = Stellar.TxBuild.Account.new(pk1)
    {:ok, seq_num} = Stellar.Horizon.Accounts.fetch_next_sequence_number(pk1)
    sequence_number = Stellar.TxBuild.SequenceNumber.new(seq_num + 1)

    payment_op =
      Stellar.TxBuild.Payment.new(
        destination: pk2,
        asset: :native,
        amount: 100,
        source_account: pk1
      )

    {:ok, %Stellar.TxBuild{tx: tx}} =
      tx_build =
      source_account
      |> Stellar.TxBuild.new(sequence_number: sequence_number, time_bounds: time_bounds)
      |> Stellar.TxBuild.add_operation(payment_op)

    # |> Stellar.TxBuild.sign([signature1, signature2])

    {:ok, envelope} = Stellar.TxBuild.envelope(tx_build)

    IO.inspect("TX ENVELOPE ->")
    IO.inspect(envelope)
    IO.inspect("TX HASH ->")
    IO.inspect(Stellar.TxBuild.Transaction.hash(tx))
  end

  test "set options tx",
       %{
         keypair1: {pk1, sk1} = keypair1,
         keypair2: {pk2, sk2},
         time_bounds: time_bounds
       } = params do
    # IO.inspect(params)
    # 1. SetOptions: set signed_payload signer
    source_account = Stellar.TxBuild.Account.new(pk1)
    {:ok, seq_num} = Stellar.Horizon.Accounts.fetch_next_sequence_number(pk1)
    sequence_number = Stellar.TxBuild.SequenceNumber.new(seq_num)

    # Replace with the generated HASH
    signer_key =
      "42890b283cdcf16beed3afde9c06d830b9bf4762bbf77b31b5688477f61f861d"
      |> Base.decode16!(case: :lower)
      |>  StellarBase.StrKey.encode!(:pre_auth_tx)

    set_options_op =
      Stellar.TxBuild.SetOptions.new(
        signer: {signer_key, 1}
      )

    signature1 = Stellar.TxBuild.Signature.new(keypair1)

    {:ok, %Stellar.TxBuild{tx: tx}} =
        tx_build =
        source_account \
      |> Stellar.TxBuild.new(sequence_number: sequence_number, time_bounds: time_bounds)
      |> Stellar.TxBuild.add_operation(set_options_op)
      |> Stellar.TxBuild.sign(signature1)

    hash_tx = Stellar.TxBuild.Transaction.hash(tx)
    base_signature = Stellar.TxBuild.Transaction.base_signature(tx)
    {:ok, envelope} = Stellar.TxBuild.envelope(tx_build)

    IO.inspect(%{
      envelope: envelope,
      signer_key: signer_key,
      hash_tx: hash_tx,
      base_signature: base_signature
    })
  end
end
