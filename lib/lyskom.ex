defmodule Lyskom do
  @server Lyskom.Server

  def login(id_number, password, invisible \\ false) do
    GenServer.call(@server, {:login, id_number, password, invisible}, :infinity)
  end

  def logout do
    GenServer.call(@server, {:logout}, :infinity)
  end

  def lookup_z_name(name, want_pers \\ true, want_confs \\ true) do
    GenServer.call(@server, {:lookup_z_name, name, want_pers, want_confs}, :infinity)
  end

  def who_is_on(want_visible \\ true, want_invisible \\ false, active_last \\ 1800) do
    GenServer.call(@server, {:who_is_on, want_visible, want_invisible, active_last}, :infinity)
  end

  def get_conf_stat(conf_no) do
    GenServer.call(@server, {:get_conf_stat, conf_no}, :infinity)
  end

  def query_async() do
    GenServer.call(@server, {:query_async}, :infinity)
  end

  def accept_async(request_list) do
    GenServer.call(@server, {:accept_async, request_list}, :infinity)
  end

  def get_text_stat(text_no) do
    GenServer.call(@server, {:get_text_stat, text_no}, :infinity)
  end

  def get_text(text_no, start_char \\ 0, end_char \\ 1024 * 1024) do
    GenServer.call(@server, {:get_text, text_no, start_char, end_char}, :infinity)
  end

  def get_unread_confs(pers_no) do
    GenServer.call(@server, {:get_unread_confs, pers_no}, :infinity)
  end

  def query_read_texts(pers_no, conf_no, want_read_ranges \\ true, max_ranges \\ 1) do
    GenServer.call(
      @server,
      {:query_read_texts, pers_no, conf_no, want_read_ranges, max_ranges},
      :infinity
    )
  end

  def local_to_global(conf_no, first_local_no, no_of_existing_texts \\ 255) do
    GenServer.call(
      @server,
      {:local_to_global, conf_no, first_local_no, no_of_existing_texts},
      :infinity
    )
  end
end
