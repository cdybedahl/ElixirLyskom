defmodule Lyskom.ProtA.Type do
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

  defmodule DynamicSessionInfo do
    defstruct [:session, :person, :working_conference, :idle_time, :flags, :what_am_i_doing]

    def new([sess, pers, conf, idle, flags, what]) do
      %Type.DynamicSessionInfo{
        session: List.to_integer(sess),
        person: List.to_integer(pers),
        working_conference: List.to_integer(conf),
        idle_time: List.to_integer(idle),
        flags: Type.SessionFlags.new(Enum.map(flags, fn n -> n == ?1 end)),
        what_am_i_doing: what
      }
    end
  end

  defmodule SessionFlags do
    defstruct [invisible: false, user_active_used: false]

    def new([invis, used, _,_,_,_,_,_]) do
      %Type.SessionFlags{
        invisible: invis,
        user_active_used: used
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
