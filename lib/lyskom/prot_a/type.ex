defmodule Lyskom.ProtA.Type do
  alias __MODULE__

  import List, only: [to_integer: 1]

  #############################################################################
  defmodule AuxItem do
    defstruct [:no, :tag, :creator, :created_at, :flags, :inherit_limit, :data]

    def new(list) do
      [no, tag, creator | list] = list
      {created_at, list} = Enum.split(list, 9)
      [flags, limit, data] = list

      %Type.AuxItem{
        no: to_integer(no),
        tag: to_integer(tag),
        creator: to_integer(creator),
        created_at: Type.Time.new(created_at),
        flags: Type.AuxItemFlags.new(flags),
        inherit_limit: to_integer(limit),
        data: data
      }
    end
  end

  #############################################################################
  defmodule AuxItemFlags do
    defstruct [
      :deleted,
      :inherit,
      :secret,
      :hide_creator,
      :dont_garb,
      :reserved2,
      :reserved3,
      :reserved4
    ]

    def new([del, inh, sec, hid, don, re2, re3, re4]) do
      %Type.AuxItemFlags{
        deleted: del == ?1,
        inherit: inh == ?1,
        secret: sec == ?1,
        hide_creator: hid == ?1,
        dont_garb: don == ?1,
        reserved2: re2 == ?1,
        reserved3: re3 == ?1,
        reserved4: re4 == ?1
      }
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
        conf_no: to_integer(no)
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
        session: to_integer(sess),
        person: to_integer(pers),
        working_conference: to_integer(conf),
        idle_time: to_integer(idle),
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
        expire,
        auxitemlist
      ] = list

      auxitems = Enum.map(auxitemlist, &Type.AuxItem.new/1)

      %Type.Conference{
        name: name,
        type: Type.ConfType.new(type),
        creation_time: Type.Time.new(ctime),
        last_written: Type.Time.new(written),
        creator: to_integer(creator),
        presentation: to_integer(pres),
        supervisor: to_integer(supervisor),
        permitted_submitters: to_integer(permitted),
        super_conf: to_integer(superconf),
        msg_of_day: to_integer(motd),
        nice: to_integer(nice),
        keep_commented: to_integer(keep),
        no_of_members: to_integer(no_of_members),
        first_local_no: to_integer(firstlocal),
        no_of_texts: to_integer(no_of_texts),
        expire: to_integer(expire),
        aux_items: auxitems
      }
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
        seconds: to_integer(sec),
        minutes: to_integer(min),
        hours: to_integer(hour),
        day: to_integer(day),
        month: to_integer(mon),
        year: to_integer(year),
        day_of_week: to_integer(dow),
        day_of_year: to_integer(doy),
        is_dst: dst == '1'
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
