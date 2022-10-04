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
        "GBKF3TWYI73TZLO4SX4CG5EONLJW523356YWGLZ2IUCAOMFA65IEJXF7",
        "SAJFIOMK7L7GFGDZLNLCHZ7UOBOQS64BH43A6BZUTOQR5G3GL7JKH4TB"
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
      |> IO.inspect()

    # |> Stellar.TxBuild.sign([signature1, signature2])

    {:ok, envelope} = Stellar.TxBuild.envelope(tx_build)
    IO.inspect(envelope)
    IO.inspect(Stellar.TxBuild.Transaction.hash(tx))
  end

  test "set options tx",
       %{
         keypair1: {pk1, sk1} = keypair1,
         keypair2: {pk2, sk2},
         time_bounds: time_bounds
       } = params do
    IO.inspect(params)
    # 1. SetOptions: set signed_payload signer
    source_account = Stellar.TxBuild.Account.new(pk1)
    {:ok, seq_num} = Stellar.Horizon.Accounts.fetch_next_sequence_number(pk1)
    sequence_number = Stellar.TxBuild.SequenceNumber.new(seq_num)

    set_options_op =
      Stellar.TxBuild.SetOptions.new(
        signer: {"TDBXU5VXD6WJY2RIGONCYXNPZT2VYVVKNBYLHX2HKLJZQHIUXAA4NU4X", 0}
      )

    signature1 = Stellar.TxBuild.Signature.new(keypair1)

    {:ok, envelope} =
      source_account
      |> Stellar.TxBuild.new(sequence_number: sequence_number, time_bounds: time_bounds)
      |> Stellar.TxBuild.add_operation(set_options_op)
      |> Stellar.TxBuild.sign(signature1)
      |> Stellar.TxBuild.envelope()

    IO.inspect(envelope)
  end

  test "compare txs from base64 xdr" do
    tx_sdk = "AAAAAgAAAABUXc7YR/c8rdyV+CN0jmrTbut777FjLzpFBAcwoPdQRAAAAGQABOM0AAAABgAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAABAAAAAFRdzthH9zyt3JX4I3SOatNu63vvsWMvOkUEBzCg91BEAAAAAQAAAABExaVxY0XJXM5w/5hM1g9bvAPiwc4TJsikxdmHUYyfaAAAAAAAAAAAO5rKAAAAAAAAAAAA"
    tx_lab = "AAAAAgAAAABUXc7YR/c8rdyV+CN0jmrTbut777FjLzpFBAcwoPdQRAAAAGQABOM0AAAABgAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAABAAAAAFRdzthH9zyt3JX4I3SOatNu63vvsWMvOkUEBzCg91BEAAAAAQAAAABExaVxY0XJXM5w/5hM1g9bvAPiwc4TJsikxdmHUYyfaAAAAAAAAAAAO5rKAAAAAAAAAAAA"

    assert tx_sdk == tx_lab
    # Stellar.TxBuild.TransactionEnvelope.from_base64()
  end
end
