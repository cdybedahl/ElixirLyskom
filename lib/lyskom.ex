defmodule Lyskom do
  require Logger

  def new() do
    name_base = make_ref()

    {:ok, _pid} =
      DynamicSupervisor.start_child(
        Lyskom.DynamicSupervisor,
        {Lyskom.Supervisor, name_base}
      )

    {:ok, name_base}
  end

  def login(connection, id_number, password, invisible \\ false) do
    GenServer.call(Lyskom.Server._name(connection), {:login, id_number, password, invisible}, :infinity)
  end

  def logout(connection) do
    GenServer.call(Lyskom.Server._name(connection), {:logout}, :infinity)
  end

  def lookup_z_name(connection, name, want_pers \\ true, want_confs \\ true) do
    GenServer.call(Lyskom.Server._name(connection), {:lookup_z_name, name, want_pers, want_confs}, :infinity)
  end

  def who_is_on(connection, want_visible \\ true, want_invisible \\ false, active_last \\ 1800) do
    GenServer.call(Lyskom.Server._name(connection), {:who_is_on, want_visible, want_invisible, active_last}, :infinity)
  end

  def get_conf_stat(connection, conf_no) do
    GenServer.call(Lyskom.Server._name(connection), {:get_conf_stat, conf_no}, :infinity)
  end

  def query_async(connection) do
    GenServer.call(Lyskom.Server._name(connection), {:query_async}, :infinity)
  end

  def accept_async(connection, request_list) do
    GenServer.call(Lyskom.Server._name(connection), {:accept_async, request_list}, :infinity)
  end

  def get_text_stat(connection, text_no) do
    GenServer.call(Lyskom.Server._name(connection), {:get_text_stat, text_no}, :infinity)
  end

  def get_text(connection, text_no, start_char \\ 0, end_char \\ 1024 * 1024) do
    GenServer.call(Lyskom.Server._name(connection), {:get_text, text_no, start_char, end_char}, :infinity)
  end

  def get_unread_confs(connection, pers_no) do
    GenServer.call(Lyskom.Server._name(connection), {:get_unread_confs, pers_no}, :infinity)
  end

  def query_read_texts(connection, pers_no, conf_no, want_read_ranges \\ true, max_ranges \\ 1) do
    GenServer.call(
      Lyskom.Server._name(connection),
      {:query_read_texts, pers_no, conf_no, want_read_ranges, max_ranges},
      :infinity
    )
  end

  def local_to_global(connection, conf_no, first_local_no, no_of_existing_texts \\ 255) do
    GenServer.call(
      Lyskom.Server._name(connection),
      {:local_to_global, conf_no, first_local_no, no_of_existing_texts},
      :infinity
    )
  end
end
