defmodule Lyskom.ProtA.Type do
  alias __MODULE__

  #############################################################################
  defmodule AuxItem do
    defstruct [:no, :tag, :creator, :created_at, :flags, :inherit_limit, :data]

    def new(_list) do

    end
  end

  #############################################################################
  defmodule MiscInfo do
    defstruct [:type, :data]
  end

  #############################################################################
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

  #############################################################################
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

  #############################################################################
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

  #############################################################################
  defmodule SessionFlags do
    defstruct invisible: false, user_active_used: false

    def new([invis, used, _, _, _, _, _, _]) do
      %Type.SessionFlags{
        invisible: invis,
        user_active_used: used
      }
    end
  end

  #############################################################################
  defmodule Conference do
    defstruct [
      :name,
      :type,
      :creation_time,
      :last_written,
      :creator,
      :presentation,
      :supervisor,
      :permitted_submitters,
      :super_conf,
      :msg_of_day,
      :nice,
      :keep_commented,
      :no_of_members,
      :first_local_no,
      :no_of_texts,
      :expire,
      :aux_items
    ]

    def new(list) do
      [name, type | list] = list
      {ctime, list} = Enum.split(list, 9)
      {written, list} = Enum.split(list, 9)

      [
        creator,
        pres,
        supervisor,
        permitted,
        superconf,
        motd,
        nice,
        keep,
        no_of_members,
        firstlocal,
        no_of_texts,
        expire | list
      ] = list
      auxitems = Enum.map(list,&Type.AuxItem.new/1)
      # TODO: use all those
    end
  end

  #############################################################################
  defmodule Time do
    defstruct [
      :seconds,
      :minutes,
      :hours,
      :day,
      :month,
      :year,
      :day_of_week,
      :day_of_year,
      :is_dst
    ]

    def new([sec, min, hour, day, mon, year, dow, doy, dst]) do
      %Type.Time{
        seconds: sec,
        minutes: min,
        hours: hour,
        day: day,
        month: mon,
        year: year,
        day_of_week: dow,
        day_of_year: doy,
        is_dst: dst
      }
    end
  end

  #############################################################################
  ### Encoding
  #############################################################################

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
