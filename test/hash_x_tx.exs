defmodule Stellar.HashxTx do
  use ExUnit.Case

  alias StellarBase.XDR.{
    VariableOpaque64,
    UInt256,
    SignerKeyEd25519SignedPayload
  }

  alias StellarBase.StrKey

  setup do
    # ACCOUNT 1
    # Public Key	GBV37ROUUTVC5PLC3T5ZCKTZRMSJQUFRP3VZNAIAMDKHXX6OWKR5ELI4
    # Secret Key	SBSNZ2ALGP6D7PG36DKLXHZJLBEEA5XWHDZJIXAMYE7DYOWYAQUNVE3I

    # ACCOUNT 2
    # Public Key  GBCMLJLRMNC4SXGOOD7ZQTGWB5N3YA7CYHHBGJWIUTC5TB2RRSPWRHQZ
    # Secret Key  SBEQE23AMLO3EX6HGAL54TGZOUVJIFMT44KYQNPK3DLQVD75NORQ343Q
    {pk1, sk1} =
      keypair1 = {
        "GBV37ROUUTVC5PLC3T5ZCKTZRMSJQUFRP3VZNAIAMDKHXX6OWKR5ELI4",
        "SBSNZ2ALGP6D7PG36DKLXHZJLBEEA5XWHDZJIXAMYE7DYOWYAQUNVE3I"
      }

    {pk2, sk2} =
      keypair2 = {
        "GBCMLJLRMNC4SXGOOD7ZQTGWB5N3YA7CYHHBGJWIUTC5TB2RRSPWRHQZ",
        "SBEQE23AMLO3EX6HGAL54TGZOUVJIFMT44KYQNPK3DLQVD75NORQ343Q"
      }

    raw_preimage =
      <<37, 115, 193, 39, 204, 224, 190, 248, 12, 251, 213, 33, 46, 170, 236, 55, 88, 33, 172,
        109, 176, 93, 53, 67, 186, 198, 71, 19, 14, 107, 216, 223>>

    hex_preimage = Base.encode16(raw_preimage, case: :lower)

    raw_hash_x =
      :sha256
      |> :crypto.hash(raw_preimage)

    hash_x_key = StrKey.encode!(raw_hash_x, :sha256_hash)

    hex_hash_x = Base.encode16(raw_hash_x, case: :lower)

    %{
      keypair1: keypair1,
      keypair2: keypair2,
      raw_preimage: raw_preimage,
      hex_preimage: hex_preimage,
      hash_x_key: hash_x_key,
      hex_hash_x: hex_hash_x
    }
  end

  test "set options tx",
       %{
         keypair1: {pk1, sk1} = keypair1,
         keypair2: {pk2, sk2},
         hash_x_key: hash_x_key
       } = params do
    IO.inspect(params)
    # 1. SetOptions: set signed_payload signer
    source_account = Stellar.TxBuild.Account.new(pk1)
    {:ok, seq_num} = Stellar.Horizon.Accounts.fetch_next_sequence_number(pk1)
    sequence_number = Stellar.TxBuild.SequenceNumber.new(seq_num)

    set_options_op = Stellar.TxBuild.SetOptions.new(signer: {hash_x_key, 0})

    signature1 = Stellar.TxBuild.Signature.new(keypair1)

    {:ok, envelope} =
      source_account
      |> Stellar.TxBuild.new(sequence_number: sequence_number)
      |> Stellar.TxBuild.add_operation(set_options_op)
      |> Stellar.TxBuild.sign(signature1)
      |> Stellar.TxBuild.envelope()

    IO.inspect(envelope)
  end

  test "payment using signature of hash_x", %{
    keypair1: {pk1, sk1} = keypair1,
    keypair2: {pk2, sk2},
    hex_preimage: hex_preimage,
    hash_x_key: hash_x_key
  } do
    source_account = Stellar.TxBuild.Account.new(pk1)
    {:ok, seq_num} = Stellar.Horizon.Accounts.fetch_next_sequence_number(pk1)
    sequence_number = Stellar.TxBuild.SequenceNumber.new(seq_num)

    payment_op =
      Stellar.TxBuild.Payment.new(
        destination: pk2,
        asset: :native,
        amount: 1,
        source_account: pk1
      )

    signature2 = Stellar.TxBuild.Signature.new(preimage: hex_preimage)

    {:ok, envelope} =
      source_account
      |> Stellar.TxBuild.new(sequence_number: sequence_number)
      |> Stellar.TxBuild.add_operation(payment_op)
      |> Stellar.TxBuild.sign(signature2)
      |> Stellar.TxBuild.envelope()

    IO.inspect(envelope)
  end
end
