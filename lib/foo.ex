defmodule Foo do
  require Logger

  def async_printer do
    receive do
      {:async_new_text_old, no, stat} ->
        Logger.info("#{username(stat.author)} created text #{no}.")

      {:async_new_text, no, stat} ->
        Logger.info("#{username(stat.author)} created text #{no}.")

      {:async_login, _user, _session} ->
        # Logger.info("User #{username(user)} logged in.")
        true

      {:async_logout, _user, _session} ->
        # Logger.info("User #{username(user)} logged out.")
        true

      {:async_sync_db} ->
        # Logger.info("Databasen synkas. Eller har synkat klart.")
        true

      {:async_i_am_on, pers_no, conf_no, _session_no, what, _name} ->
        Logger.info("#{username(pers_no)} i #{username(conf_no)} #{what}")

      msg ->
        Logger.debug("Got a message: #{inspect(msg)}")
    end

    Foo.async_printer()
  end

  def username(0) do
    "<inget möte>"
  end

  def username(pers_no) do
    stat = Lyskom.get_conf_stat(pers_no)
    stat.name
  end

  def start do
    :ok = Lyskom.login(2429, "gnapp", true)
    Lyskom.AsyncHandler.add_client(spawn(&async_printer/0))
    Lyskom.accept_async([5, 6, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22])
  end
end
