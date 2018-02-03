defmodule Foo do
  require Logger

  def async_printer do
    receive do
      {:async_new_text_old, no, stat} ->
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

      msg ->
        Logger.debug("Got a message: #{inspect(msg)}")
    end

    Foo.async_printer()
  end

  def username(pers_no) do
    stat = Lyskom.get_conf_stat(pers_no)
    stat.name
  end

  def start do
    :ok = Lyskom.login(2429, "gnapp", true)
    Lyskom.AsyncHandler.add_client(spawn(&async_printer/0))
  end
end
