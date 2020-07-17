defmodule Lyskom do
  def new(host \\ "kom.lysator.liu.se", port \\ 4894) do
    DynamicSupervisor.start_child(Lyskom.Super, {Lyskom.Socket, [host, port]})
  end

  def login(pid, id_number, password, invisible \\ false),
    do: server_call(pid, {:login, id_number, password, invisible})

  def logout(pid), do: server_call(pid, {:logout})

  def terminate(pid) do
    logout(pid)
    DynamicSupervisor.terminate_child(Lyskom.Super, pid)
  end

  def get_info(pid), do: server_call(pid, {:get_info})

  def get_time(pid), do: server_call(pid, {:get_time})

  def lookup_z_name(pid, name, want_pers \\ true, want_confs \\ true),
    do: server_call(pid, {:lookup_z_name, name, want_pers, want_confs})

  def who_is_on(pid, want_visible \\ true, want_invisible \\ false, active_last \\ 1800),
    do: server_call(pid, {:who_is_on, want_visible, want_invisible, active_last})

  def get_conf_stat(pid, conf_no), do: server_call(pid, {:get_conf_stat, conf_no})

  def get_uconf_stat(pid, conf_no), do: server_call(pid, {:get_uconf_stat, conf_no})

  def query_async(pid), do: server_call(pid, {:query_async})

  def accept_async(pid, request_list), do: server_call(pid, {:accept_async, request_list})

  def get_text_stat(pid, text_no), do: server_call(pid, {:get_text_stat, text_no})

  def get_text(pid, text_no, start_char \\ 0, end_char \\ 1024 * 1024),
    do: server_call(pid, {:get_text, text_no, start_char, end_char})

  def get_unread_confs(pid, pers_no), do: server_call(pid, {:get_unread_confs, pers_no})

  def query_read_texts(pid, pers_no, conf_no, want_read_ranges \\ true, max_ranges \\ 1),
    do: server_call(pid, {:query_read_texts, pers_no, conf_no, want_read_ranges, max_ranges})

  def local_to_global(pid, conf_no, first_local_no, no_of_existing_texts \\ 255),
    do: server_call(pid, {:local_to_global, conf_no, first_local_no, no_of_existing_texts})

  def find_next_text_no(pid, start_no), do: server_call(pid, {:find_next_text_no, start_no})

  def get_person_stat(pid, pers_no), do: server_call(pid, {:get_person_stat, pers_no})

  def mark_as_read(pid, conf_no, text_no) when is_integer(text_no),
    do: mark_as_read(pid, conf_no, [text_no])

  def mark_as_read(pid, conf_no, local_texts) when is_list(local_texts),
    do: server_call(pid, {:mark_as_read, conf_no, local_texts})

  def send_message(pid, recipient, message),
    do: server_call(pid, {:send_message, recipient, message})

  def create_text(pid, args), do: server_call(pid, {:create_text, args})

  def create_text(pid, content, misc_items, aux_items),
    do: server_call(pid, {:create_text, content, misc_items, aux_items})

  def set_user_area(pid, pers_no, user_area),
    do: server_call(pid, {:set_user_area, pers_no, user_area})

  ## Convenience functions

  def listen_for_async(pid, list) do
    Registry.unregister(Lyskom.AsyncSubscribers, pid)

    cleaned_list =
      Enum.map(list, fn x ->
        if is_integer(x) do
          x
        else
          Lyskom.Constants.async(x)
        end
      end)

    {:ok, _} = Registry.register(Lyskom.AsyncSubscribers, pid, MapSet.new(cleaned_list))
    accept_async(pid, cleaned_list)
  end

  def text_and_stat(pid, text_no) do
    case get_text_stat(pid, text_no) do
      {:error, :no_such_text, _params} ->
        nil

      text_stat ->
        text_body = get_text(pid, text_no, 0, text_stat.no_of_chars)
        [subject, text_body] = String.split(text_body, "\n", parts: 2)

        case Enum.find(text_stat.aux_items, &(&1.tag == 1)) do
          aux = %Lyskom.Type.AuxItem{} ->
            if String.starts_with?(aux.data, ["text/", "x-kom/text"]) do
              case Regex.run(~r";charset=(.*)", aux.data) do
                nil ->
                  %{
                    status: text_stat,
                    subject: :iconv.convert("latin1", "utf8", subject),
                    body: :iconv.convert("latin1", "utf8", text_body)
                  }

                [_, type] ->
                  %{
                    status: text_stat,
                    subject: :iconv.convert(type, "utf8", subject),
                    body: :iconv.convert(type, "utf8", text_body)
                  }
              end
            else
              %{
                status: text_stat,
                subject: :iconv.convert("latin1", "utf8", subject),
                body: text_body
              }
            end

          nil ->
            # In the absence of a content_type, assume ISO-8859-1
            %{
              status: text_stat,
              subject: :iconv.convert("latin1", "utf8", subject),
              body: :iconv.convert("latin1", "utf8", text_body)
            }
        end
    end
  end

  def get_user_settings(pid, pers_no), do: Lyskom.UserArea.get_user_settings(pid, pers_no)

  def store_user_settings(pid, pers_no, term),
    do: Lyskom.UserArea.store_user_settings(pid, pers_no, term)

  defp server_call(pid, payload), do: GenServer.call(pid, {:call, payload}, :infinity)
end
