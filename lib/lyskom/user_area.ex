defmodule Lyskom.UserArea do
  import Lyskom.Type, only: [hollerith: 1]
  import Lyskom, only: [get_person_stat: 2, get_text: 2, create_text: 4, set_user_area: 3]

  @user_area_key "elixir"

  def get_user_settings(pid, pers_no) do
    case get_person_stat(pid, pers_no) do
      err = {:error, _msg, _args} ->
        err

      ps ->
        case get_text(pid, ps.user_area) do
          {:error, :text_zero, _args} ->
            %{}

          err = {:error, _msg, _args} ->
            err

          t ->
            m = parse(t)

            case Map.get(m, @user_area_key) do
              nil ->
                %{}

              bin ->
                bin |> Base.decode64!() |> :erlang.binary_to_term()
            end
        end
    end
  end

  def store_user_settings(pid, pers_no, term) do
    case get_person_stat(pid, pers_no) do
      err = {:error, _msg, _args} ->
        err

      ps ->
        case get_text(pid, ps.user_area) do
          {:error, :text_zero, _args} ->
            data =
              term
              |> :erlang.term_to_binary()
              |> Base.encode64()

            body =
              Map.put(%{}, @user_area_key, data)
              |> assemble()

            text_no = create_text(pid, body, [], [])
            set_user_area(pid, pers_no, text_no)

          err = {:error, _msg, _args} ->
            err

          t ->
            m = parse(t)

            data =
              term
              |> :erlang.term_to_binary()
              |> Base.encode64()

            body = Map.put(m, @user_area_key, data) |> assemble()
            text_no = create_text(pid, body, [], [])
            set_user_area(pid, pers_no, text_no)
        end
    end
  end

  def parse(bin) do
    [toc | others] = extract(bin)

    Enum.zip(extract(toc), others)
    |> Enum.into(%{})
  end

  def assemble(m) do
    {names, data} = Enum.unzip(m)

    toc =
      " " <>
        (names
         |> Enum.map(&hollerith/1)
         |> Enum.join(" "))

    others =
      data
      |> Enum.map(&hollerith/1)
      |> Enum.join(" ")

    " " <> hollerith(toc) <> " " <> others
  end

  defp extract(str) do
    extract(str, [])
  end

  defp extract("", acc) do
    Enum.reverse(acc)
  end

  defp extract(str, acc) do
    {item, rest} = get_next_hollerith(str)
    extract(rest, [item | acc])
  end

  defp get_next_hollerith(str) do
    str = String.trim(str)
    [len, rest] = String.split(str, "H", parts: 2)
    String.split_at(rest, String.to_integer(len))
  end
end
