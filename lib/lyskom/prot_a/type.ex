defmodule Lyskom.ProtA.Type do
  alias __MODULE__
  require Logger

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

    def new(list) do
      Enum.reverse(_new(list, []))
    end

    def _new([], acc) do
      acc
    end

    # TODO: Add all misc_info types
    def _new(['0' , conf_no | tail], acc) do
      _new(tail, [{:recpt, to_integer(conf_no)} | acc])
    end
    def _new(['1' , conf_no | tail], acc) do
      _new(tail, [{:cc_recpt, to_integer(conf_no)} | acc])
    end
    def _new(['2' , text_no | tail], acc) do
      _new(tail, [{:comm_to, to_integer(text_no)} | acc])
    end
    def _new(['3' , text_no | tail], acc) do
      _new(tail, [{:comm_in, to_integer(text_no)} | acc])
    end
    def _new(['4' , text_no | tail], acc) do
      _new(tail, [{:footn_to, to_integer(text_no)} | acc])
    end
    def _new(['5' , text_no | tail], acc) do
      _new(tail, [{:footn_in, to_integer(text_no)} | acc])
    end
    def _new(['6' , local_text_no | tail], acc) do
      _new(tail, [{:loc_no, to_integer(local_text_no)} | acc])
    end
    def _new(['7' | tail], acc) do
      {t, tail} = Enum.split(tail,9)
      _new(tail, [{:rec_time, Type.Time.new(t)} | acc])
    end
    def _new(['8' , pers_no | tail], acc) do
      _new(tail, [{:sent_by, to_integer(pers_no)} | acc])
    end
    def _new(['9' | tail], acc) do
      {t, tail} = Enum.split(tail,9)
      _new(tail, [{:sent_at, Type.Time.new(t)} | acc])
    end
    def _new(['15' , conf_no | tail], acc) do
      _new(tail, [{:bcc_recpt, to_integer(conf_no)} | acc])
    end
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
        flags: Type.SessionFlags.new(flags),
        what_am_i_doing: what
      }
    end
  end

  #############################################################################
  defmodule SessionFlags do
    defstruct invisible: false, user_active_used: false

    def new([invis, used, _, _, _, _, _, _]) do
      %Type.SessionFlags{
        invisible: invis == ?1,
        user_active_used: used == ?1
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
    def new([sec, min, hour, day, mon, year, _dow, _doy, _dst]) do
      Timex.to_datetime(
        {{1900 + to_integer(year), 1 + to_integer(mon), to_integer(day)},
         {to_integer(hour), to_integer(min), to_integer(sec)}},
        :local
      )
    end
  end

  #############################################################################
  defmodule TextStat do
    defstruct [
      :creation_time,
      :author,
      :no_of_lines,
      :no_of_chars,
      :no_of_marks,
      :misc_info,
      :aux_items
    ]

    def new(list) do
      {ctime, list} = Enum.split(list, 9)
      [author, lines, chars, marks, mi_list, ai_list] = list
      aux_items = Enum.map(ai_list, &Type.AuxItem.new/1)
      # The following line is a sign that the array handling needs to be redone.
      mi_list = List.foldl(mi_list, [], fn n, acc -> acc ++ n end)

      %Type.TextStat{
        creation_time: Type.Time.new(ctime),
        author: to_integer(author),
        no_of_lines: to_integer(lines),
        no_of_chars: to_integer(chars),
        no_of_marks: to_integer(marks),
        misc_info: Type.MiscInfo.new(mi_list),
        aux_items: aux_items
      }
    end

    @doc "For use with async call number 0 (async-new-text-old)."
    def old(list) do
      {ctime, list} = Enum.split(list, 9)
      [author, lines, chars, marks, mi_list] = list
      # The following line is a sign that the array handling needs to be redone.
      mi_list = List.foldl(mi_list, [], fn n, acc -> acc ++ n end)

      %Type.TextStat{
        creation_time: Type.Time.new(ctime),
        author: to_integer(author),
        no_of_lines: to_integer(lines),
        no_of_chars: to_integer(chars),
        no_of_marks: to_integer(marks),
        misc_info: Type.MiscInfo.new(mi_list),
        aux_items: []
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
