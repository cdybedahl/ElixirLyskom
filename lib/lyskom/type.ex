defmodule Lyskom.Type do
  alias __MODULE__
  require Logger

  import List, only: [to_integer: 1]

  #############################################################################
  ### Helpers
  #############################################################################

  def decode_string(bin) do
    :iconv.convert("latin1", "utf8", bin)
  end

  def encode_string(str) do
    :iconv.convert("utf8", "iso-8859-1", str)
  end

  #############################################################################
  defmodule Info do
    defstruct [
      :version,
      :conf_pres_conf,
      :pers_pres_conf,
      :motd_conf,
      :kom_news_conf,
      :motd_of_lyskom,
      :aux_items
    ]

    def new(list) do
      [version, conf_pres, pers_pres, motd_conf, news, motd, auxitemlist] = list
      auxitems = Enum.map(auxitemlist, &Type.AuxItem.new/1)

      %Type.Info{
        version: version,
        conf_pres_conf: conf_pres,
        pers_pres_conf: pers_pres,
        motd_conf: motd_conf,
        kom_news_conf: news,
        motd_of_lyskom: motd,
        aux_items: auxitems
      }
    end
  end

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
        data: Type.decode_string(data)
      }
    end

    def prot_a(%Type.AuxItem{} = item) do
      [
        Integer.to_string(item.tag),
        Type.AuxItemFlags.prot_a(item.flags),
        Integer.to_string(item.inherit_limit),
        Type.hollerith(item.data)
      ]
      |> Enum.join(" ")
    end
  end

  #############################################################################
  defmodule AuxItemFlags do
    @keys [
      :deleted,
      :inherit,
      :secret,
      :hide_creator,
      :dont_garb,
      :reserved2,
      :reserved3,
      :reserved4
    ]
    defstruct @keys

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

    def prot_a(%Type.AuxItemFlags{} = flags) do
      Type.bitstring(@keys, flags)
    end
  end

  #############################################################################
  defmodule MiscInfo do
    defstruct [:type, :data]

    def new(list) do
      new(list, [])
    end

    defp new([], acc) do
      acc
      |> Enum.reverse()
      |> fix()
    end

    defp new(['0', conf_no | tail], acc) do
      new(tail, [{:recpt, to_integer(conf_no)} | acc])
    end

    defp new(['1', conf_no | tail], acc) do
      new(tail, [{:cc_recpt, to_integer(conf_no)} | acc])
    end

    defp new(['2', text_no | tail], acc) do
      new(tail, [{:comm_to, to_integer(text_no)} | acc])
    end

    defp new(['3', text_no | tail], acc) do
      new(tail, [{:comm_in, to_integer(text_no)} | acc])
    end

    defp new(['4', text_no | tail], acc) do
      new(tail, [{:footn_to, to_integer(text_no)} | acc])
    end

    defp new(['5', text_no | tail], acc) do
      new(tail, [{:footn_in, to_integer(text_no)} | acc])
    end

    defp new(['6', local_text_no | tail], acc) do
      new(tail, [{:loc_no, to_integer(local_text_no)} | acc])
    end

    defp new(['7' | tail], acc) do
      {t, tail} = Enum.split(tail, 9)
      new(tail, [{:rec_time, Type.Time.new(t)} | acc])
    end

    defp new(['8', pers_no | tail], acc) do
      new(tail, [{:sent_by, to_integer(pers_no)} | acc])
    end

    defp new(['9' | tail], acc) do
      {t, tail} = Enum.split(tail, 9)
      new(tail, [{:sent_at, Type.Time.new(t)} | acc])
    end

    defp new(['15', conf_no | tail], acc) do
      new(tail, [{:bcc_recpt, to_integer(conf_no)} | acc])
    end

    def prot_a({type, data}) do
      Map.get(
        %{
          recpt: "0",
          cc_recpt: "1",
          comm_to: "2",
          footn_to: "4",
          bcc_recpt: "15"
        },
        type
      ) <> " " <> Integer.to_string(data)
    end

    def fix([]) do
      []
    end

    def fix(list) do
      fix(list, [], [])
    end

    defp fix([], cur, acc) do
      [cur | acc]
      |> Enum.reverse()
      |> Enum.map(&Map.new/1)
      |> Enum.reject(fn n -> n == %{} end)
    end

    defp fix([{type, _} = head | tail], cur, acc) do
      if type in [:recpt, :cc_recpt, :bcc_recpt, :comm_in, :comm_to, :footn_to, :footn_in] do
        fix(tail, [head, type: type], [cur | acc])
      else
        fix(tail, [head | cur], acc)
      end
    end
  end

  #############################################################################
  defmodule ConfZInfo do
    defstruct [:name, :conf_type, :conf_no]

    def new([name, type, no]) do
      %Type.ConfZInfo{
        name: Type.decode_string(name),
        conf_type: Type.ConfType.new(type),
        conf_no: to_integer(no)
      }
    end
  end

  #############################################################################
  defmodule ConfType do
    @keys rd_prot: false,
          original: false,
          secret: false,
          letterbox: false,
          allow_anonymous: false,
          forbid_secret: false,
          reserved2: false,
          reserved3: false
    defstruct @keys

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

    def prot_a(%Type.ConfType{} = flags) do
      Type.bitstring(@keys, flags)
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
        what_am_i_doing: Type.decode_string(what)
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
        name: Type.decode_string(name),
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
      mi_list = Enum.concat(mi_list)

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
  defmodule Membership do
    defstruct [
      :position,
      :last_time_read,
      :conference,
      :priority,
      :read_ranges,
      :added_by,
      :added_at,
      :type
    ]

    def new(list) do
      [pos | list] = list
      {ltr, list} = Enum.split(list, 9)
      [conf, prio, ranges, by | list] = list
      {aa, list} = Enum.split(list, 9)
      [type] = list

      %Type.Membership{
        position: to_integer(pos),
        last_time_read: Time.new(ltr),
        conference: to_integer(conf),
        priority: to_integer(prio),
        read_ranges: Enum.map(ranges, fn [m, n] -> {to_integer(m), to_integer(n)} end),
        added_by: to_integer(by),
        added_at: Time.new(aa),
        type: Type.MembershipType.new(type)
      }
    end
  end

  #############################################################################
  defmodule MembershipType do
    defstruct [
      :invitation,
      :passive,
      :secret,
      :passive_message_invert,
      :reserved2,
      :reserved3,
      :reserved4,
      :reserved5
    ]

    def new([inv, pas, sec, pmi, re2, re3, re4, re5]) do
      %Type.MembershipType{
        invitation: inv == ?1,
        passive: pas == ?1,
        secret: sec == ?1,
        passive_message_invert: pmi == ?1,
        reserved2: re2 == ?1,
        reserved3: re3 == ?1,
        reserved4: re4 == ?1,
        reserved5: re5 == ?1
      }
    end
  end

  #############################################################################
  defmodule TextMapping do
    defstruct [:range_begin, :range_end, :more_texts_exist, :block]

    def new([rbeg, rend, more | block]) do
      %Type.TextMapping{
        range_begin: to_integer(rbeg),
        range_end: to_integer(rend),
        more_texts_exist: more == ?1,
        block: parse_block(block)
      }
    end

    defp parse_block(['1', first_local_no, text_no_list]) do
      first = to_integer(first_local_no)
      list = Enum.map(text_no_list, fn [n] -> to_integer(n) end)

      Enum.zip(first..(first + Enum.count(list)), list)
      |> Enum.filter(fn {_m, n} -> n != 0 end)
      |> Enum.into(%{})
    end

    defp parse_block(['0', pair_list]) do
      pair_list
      |> Enum.map(fn [m, n] -> {to_integer(m), to_integer(n)} end)
      |> Enum.into(%{})
    end
  end

  #############################################################################
  defmodule PersonalFlags do
    @keys [:unread_is_secret, :flg2, :flg3, :flg4, :flg5, :flg6, :flg7, :flg8]
    defstruct @keys

    def new([uis, f2, f3, f4, f5, f6, f7, f8]) do
      %Type.PersonalFlags{
        unread_is_secret: uis == ?1,
        flg2: f2 == ?1,
        flg3: f3 == ?1,
        flg4: f4 == ?1,
        flg5: f5 == ?1,
        flg6: f6 == ?1,
        flg7: f7 == ?1,
        flg8: f8 == ?1
      }
    end

    def prot_a(flags) do
      Type.bitstring(@keys, flags)
    end
  end

  #############################################################################
  defmodule PrivBits do
    defstruct [
      :wheel,
      :admin,
      :statistic,
      :create_pers,
      :create_conf,
      :change_name,
      :flg7,
      :flg8,
      :flg9,
      :flg10,
      :flg11,
      :flg12,
      :flg13,
      :flg14,
      :flg15,
      :flg16
    ]

    def new([w, a, s, cp, cc, cn, f7, f8, f9, f10, f11, f12, f13, f14, f15, f16]) do
      %Type.PrivBits{
        wheel: w == ?1,
        admin: a == ?1,
        statistic: s == ?1,
        create_pers: cp == ?1,
        create_conf: cc == ?1,
        change_name: cn == ?1,
        flg7: f7 == ?1,
        flg8: f8 == ?1,
        flg9: f9 == ?1,
        flg10: f10 == ?1,
        flg11: f11 == ?1,
        flg12: f12 == ?1,
        flg13: f13 == ?1,
        flg14: f14 == ?1,
        flg15: f15 == ?1,
        flg16: f16 == ?1
      }
    end
  end

  #############################################################################
  defmodule Person do
    defstruct [
      :username,
      :privileges,
      :flags,
      :last_login,
      :user_area,
      :total_time_present,
      :sessions,
      :created_lines,
      :created_bytes,
      :read_texts,
      :no_of_text_fetches,
      :created_persons,
      :created_confs,
      :first_created_local_no,
      :no_of_created_texts,
      :no_of_marks,
      :no_of_confs
    ]

    def new(list) do
      [uname, privs, flags | list] = list
      {last_login, list} = Enum.split(list, 9)

      [
        area,
        total,
        sessions,
        clines,
        cbytes,
        read,
        fetches,
        cpersons,
        cconfs,
        first,
        no_texts,
        no_marks,
        no_confs
      ] = list

      %Type.Person{
        username: Type.decode_string(uname),
        privileges: Type.PrivBits.new(privs),
        flags: Type.PersonalFlags.new(flags),
        last_login: Type.Time.new(last_login),
        user_area: to_integer(area),
        total_time_present: to_integer(total),
        sessions: to_integer(sessions),
        created_lines: to_integer(clines),
        created_bytes: to_integer(cbytes),
        read_texts: to_integer(read),
        no_of_text_fetches: to_integer(fetches),
        created_persons: to_integer(cpersons),
        created_confs: to_integer(cconfs),
        first_created_local_no: to_integer(first),
        no_of_created_texts: to_integer(no_texts),
        no_of_marks: to_integer(no_marks),
        no_of_confs: to_integer(no_confs)
      }
    end
  end

  #############################################################################
  ### Encoding
  #############################################################################

  def array(list) do
    "#{Enum.count(list)} { #{Enum.join(list, " ")} }"
  end

  def array(list, coder) do
    "#{Enum.count(list)} { #{Enum.join(Enum.map(list, coder), " ")} }"
  end

  def hollerith(str) when is_binary(str) do
    "#{byte_size(str)}H#{str}"
  end

  def boolean(true) do
    1
  end

  def boolean(false) do
    0
  end

  def bitstring(keys, flags) do
    for n <- keys do
      Map.get(%{true: ?1, false: ?0, nil: ?0}, Map.get(flags, n))
    end
    |> List.to_string()
  end
end
