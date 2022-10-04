defmodule Stellar.SignedPayloadTx do
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
        "GBKF3TWYI73TZLO4SX4CG5EONLJW523356YWGLZ2IUCAOMFA65IEJXF7",
        "SAJFIOMK7L7GFGDZLNLCHZ7UOBOQS64BH43A6BZUTOQR5G3GL7JKH4TB"
      }

    {pk2, sk2} =
      keypair2 = {
        "GBCMLJLRMNC4SXGOOD7ZQTGWB5N3YA7CYHHBGJWIUTC5TB2RRSPWRHQZ",
        "SBEQE23AMLO3EX6HGAL54TGZOUVJIFMT44KYQNPK3DLQVD75NORQ343Q"
      }

    raw_payload = <<1, 2, 3, 4>>
    payload_xdr = VariableOpaque64.new(raw_payload)

    signed_payload =
      pk1
      |> StrKey.decode!(:ed25519_public_key)
      |> UInt256.new()
      |> SignerKeyEd25519SignedPayload.new(payload_xdr)
      |> SignerKeyEd25519SignedPayload.encode_xdr!()
      |> StrKey.encode!(:signed_payload)

    %{
      keypair1: keypair1,
      keypair2: keypair2,
      raw_payload: raw_payload,
      hex_payload: Base.encode16(raw_payload, case: :lower),
      signed_payload: signed_payload
    }
  end

  test "set options tx",
       %{
         keypair1: {pk1, sk1} = keypair1,
         keypair2: {pk2, sk2},
         signed_payload: signed_payload
       } = params do
    IO.inspect(params)
    # 1. SetOptions: set signed_payload signer
    source_account = Stellar.TxBuild.Account.new(pk1)
    {:ok, seq_num} = Stellar.Horizon.Accounts.fetch_next_sequence_number(pk1)
    sequence_number = Stellar.TxBuild.SequenceNumber.new(seq_num)

    set_options_op = Stellar.TxBuild.SetOptions.new(signer: {signed_payload, 1})

    signature1 = Stellar.TxBuild.Signature.new(keypair1)

    {:ok, envelope} =
      source_account
      |> Stellar.TxBuild.new(sequence_number: sequence_number)
      |> Stellar.TxBuild.add_operation(set_options_op)
      |> Stellar.TxBuild.sign(signature1)
      |> Stellar.TxBuild.envelope()

    IO.inspect(envelope)
  end

  test "payment using signature of signed_payload", %{
    keypair1: {pk1, sk1} = keypair1,
    keypair2: {pk2, sk2},
    hex_payload: hex_payload
  } do
    source_account = Stellar.TxBuild.Account.new(pk1)
    {:ok, seq_num} = Stellar.Horizon.Accounts.fetch_next_sequence_number(pk1)
    sequence_number = Stellar.TxBuild.SequenceNumber.new(seq_num)

    payment_op =
      Stellar.TxBuild.Payment.new(
        destination: pk2,
        asset: :native,
        amount: 1,
      )

    signature1 = Stellar.TxBuild.Signature.new(signed_payload: {hex_payload, sk1})

    {:ok, envelope} =
      source_account
      |> Stellar.TxBuild.new(sequence_number: sequence_number)
      |> Stellar.TxBuild.add_operation(payment_op)
      |> Stellar.TxBuild.sign(signature1)
      |> Stellar.TxBuild.envelope()

    IO.inspect(envelope)
  end
end
