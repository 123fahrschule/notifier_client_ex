defmodule NotifierClient.Identifier do
  @moduledoc false

  def uuid do
    <<a::32, b::16, c::16, d::16, e::48>> = :crypto.strong_rand_bytes(16)

    c = Bitwise.band(c, 0x0FFF) |> Bitwise.bor(0x4000)
    d = Bitwise.band(d, 0x3FFF) |> Bitwise.bor(0x8000)

    [
      Base.encode16(<<a::32>>, case: :lower),
      Base.encode16(<<b::16>>, case: :lower),
      Base.encode16(<<c::16>>, case: :lower),
      Base.encode16(<<d::16>>, case: :lower),
      Base.encode16(<<e::48>>, case: :lower)
    ]
    |> Enum.join("-")
  end

  def source_urn("de.123fahrschule:" <> _ = source), do: source

  def source_urn(source_service) do
    "de.123fahrschule:" <> to_string(source_service)
  end
end
