defmodule Foo do
  require Logger

  @filtered [1167, 20, 6086, 5863, 634]

  def async_printer(connection) do
    receive do
      {:async_new_text_old, no, stat} ->
        IO.puts("#{username(connection, stat.author)} created text #{no}.")

      {:async_new_text, no, stat} ->
        filter_text(connection, no, stat)

      {:async_deleted_text, no, _stat} ->
        IO.puts("Text number #{no} was deleted.")

      {:async_login, user, _session} ->
        IO.puts("User #{username(connection, user)} logged in.")
        true

      {:async_logout, user, _session} ->
        IO.puts("User #{username(connection, user)} logged out.")
        true

      {:async_sync_db} ->
        IO.puts("Databasen synkas. Eller har synkat klart.")
        true

      {:async_i_am_on, pers_no, conf_no, _session_no, what, _name} ->
        [
          "#{username(connection, pers_no)} i #{username(connection, conf_no)}: ",
          :white,
          "#{what}"
        ]
        |> IO.ANSI.format()
        |> IO.puts()

      # {:async_i_am_on, _pers_no, _conf_no, _session_no, _what, _name} ->
      #  true

      {:async_text_aux_changed, text_no, _deleted, _added} ->
        [:green, "Changed aux_info for text ", :white, "#{text_no}"]
        |> IO.ANSI.format()
        |> IO.puts()

      {:async_new_name, _conf_no, old_name, new_name} ->
        [:white, old_name, :yellow, " changed name to ", :white, new_name]
        |> IO.ANSI.format()
        |> IO.puts()

      msg ->
        Logger.debug("Got a message: #{inspect(msg)}")
    after
      300_000 ->
        Lyskom.get_time(connection)
    end

    Foo.async_printer(connection)
  end

  def filter_text(connection, no, stat) do
    if stat.author in @filtered do
      stat.misc_info
      |> Enum.filter(fn mi -> mi.type in [:recpt, :cc_recpt, :bcc_recpt] end)
      |> Enum.each(fn mi ->
        Lyskom.mark_as_read(connection, Map.get(mi, mi.type), mi.loc_no)

        [
          :light_black_background,
          :green,
          "Filtered local text ",
          :white,
          "#{mi.loc_no}",
          :green,
          " in conference ",
          :white,
          "#{username(connection, Map.get(mi, mi.type))}."
        ]
        |> IO.ANSI.format()
        |> IO.puts()
      end)
    else
      [:yellow, "#{username(connection, stat.author)} created text ", :bright, "#{no}."]
      |> IO.ANSI.format()
      |> IO.puts()
    end
  end

  def username(_connection, 0) do
    "<inget möte>"
  end

  def username(connection, pers_no) do
    stat = Lyskom.get_conf_stat(connection, pers_no)
    stat.name
  end

  def start do
    {:ok, connection} = Lyskom.new('kom.lysator.liu.se')
    :ok = Lyskom.login(connection, 2429, "gnapp", true)

    Lyskom.listen_for_async(connection, [
      5,
      6,
      8,
      9,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22
    ])

    async_printer(connection)
  end
end
