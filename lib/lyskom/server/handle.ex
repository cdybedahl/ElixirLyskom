defmodule Lyskom.Server.Handle do
  require Logger
  import Lyskom.ProtA.Type

  def call(
        {:login, id_number, password, invisible},
        from,
        state
      ) do
    prot_a_call(:login, 62, from, [id_number, hollerith(password), boolean(invisible)], state)
  end

  def call({:logout}, from, state) do
    prot_a_call(:logout, 1, from, [], state)
  end

  def call({:get_info}, from, state) do
    prot_a_call(:get_info, 94, from, [], state)
  end

  def call({:get_time}, from, state) do
    prot_a_call(:get_time, 35, from, [], state)
  end

  def call({:lookup_z_name, name, want_pers, want_confs}, from, state) do
    prot_a_call(
      :lookup_z_name,
      76,
      from,
      [hollerith(name), boolean(want_pers), boolean(want_confs)],
      state
    )
  end

  def call({:who_is_on, want_visible, want_invisible, active_last}, from, state) do
    prot_a_call(
      :who_is_on,
      83,
      from,
      [boolean(want_visible), boolean(want_invisible), active_last],
      state
    )
  end

  def call({:get_conf_stat, conf_no}, from, state) do
    case Lyskom.Cache.get(:get_conf_stat, conf_no, state.name_base) do
      nil ->
        prot_a_call(:get_conf_stat, 91, from, [conf_no], state)

      data ->
        {:reply, data, state}
    end
  end

  def call({:query_async}, from, state) do
    prot_a_call(:query_async, 81, from, [], state)
  end

  def call({:accept_async, request_list}, from, state) do
    prot_a_call(:accept_async, 80, from, [array(request_list, &Integer.to_string/1)], state)
  end

  def call({:get_text_stat, text_no}, from, state) do
    prot_a_call(:get_text_stat, 90, from, [text_no], state)
  end

  def call({:get_text, text_no, start_char, end_char}, from, state) do
    prot_a_call(:get_text, 25, from, [text_no, start_char, end_char], state)
  end

  def call({:get_unread_confs, pers_no}, from, state) do
    prot_a_call(:get_unread_confs, 52, from, [pers_no], state)
  end

  def call({:query_read_texts, pers_no, conf_no, want_read_ranges, max_ranges}, from, state) do
    prot_a_call(
      :query_read_texts,
      107,
      from,
      [pers_no, conf_no, boolean(want_read_ranges), max_ranges],
      state
    )
  end

  def call({:local_to_global, conf_no, first_local_no, no_of_existing_texts}, from, state) do
    prot_a_call(
      :local_to_global,
      103,
      from,
      [conf_no, first_local_no, no_of_existing_texts],
      state
    )
  end

  def call({:find_next_text_no, start_no}, from, state) do
    prot_a_call(:find_next_text_no, 60, from, [start_no], state)
  end

  def call({:get_person_stat, pers_no}, from, state) do
    prot_a_call(:get_person_stat, 49, from, [pers_no], state)
  end

  def call({:mark_as_read, conf_no, local_texts}, from, state) do
    prot_a_call(
      :mark_as_read,
      27,
      from,
      [conf_no, array(local_texts, &Integer.to_string/1)],
      state
    )
  end

  def call({:send_message, recipient, message}, from, state) do
    prot_a_call(:send_message, 53, from, [recipient, hollerith(encode_string(message))], state)
  end

  def call({:create_text, args}, from, state) do
    prot_a_call(:create_text, 86, from, Lyskom.Impl.CreateText.to_prot_a(args), state)
  end

  # Helper functions ##########################################################
  def add_call_to_state(state = %{next_call_id: next_id}, call_args) do
    state = put_in(state.next_call_id, next_id + 1)
    put_in(state.pending[next_id], call_args)
  end

  def prot_a_call(
        call_type,
        call_no,
        from,
        args,
        state = %{name_base: name, next_call_id: next_id}
      ) do
    [next_id, call_no | args]
    |> Enum.join(" ")
    |> Kernel.<>("\n")
    |> Lyskom.Socket.send(name)

    {:noreply, add_call_to_state(state, {call_type, from, args})}
  end
end
