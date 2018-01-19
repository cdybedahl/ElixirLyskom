defmodule Lyskom.Prot_A.Type do
  alias __MODULE__

  defmodule AuxItem do
    defstruct [:no, :tag, :creator, :created_at, :flags, :inherit_limit, :data]
  end

  defmodule MiscInfo do
    defstruct [:type, :data]
  end

  defmodule ConfZInfo do
    defstruct [:name, :conf_type, :conf_no]

    def new([name, type, no]) do
      %Type.ConfZInfo{
        name: name,
        conf_type: Type.ConfType.new(type),
        conf_no: List.to_integer(no)
      }
    end
  end

  defmodule ConfType do
    defstruct rd_prot: false,
              original: false,
              secret: false,
              letterbox: false,
              allow_anonymous: false,
              forbid_secret: false,
              reserved2: false,
              reserved3: false

    def new([rd, orig, secret, letter]) do
      %Type.ConfType{
        rd_prot: rd == ?1,
        original: orig == ?1,
        secret: secret == ?1,
        letterbox: letter == ?1
      }
    end

    def new([rd, orig, secret, letter, aa, forbid, res2, res3]) do
      %Type.ConfType{
        rd_prot: rd == ?1,
        original: orig == ?1,
        secret: secret == ?1,
        letterbox: letter == ?1,
        allow_anonymous: aa == ?1,
        forbid_secret: forbid == ?1,
        reserved2: res2 == ?1,
        reserved3: res3 == ?1
      }
    end
  end

  ### Encoding

  def hollerith(str) do
    "#{String.length(str)}H#{str}"
  end

  def boolean(true) do
    1
  end

  def boolean(false) do
    0
  end
end
