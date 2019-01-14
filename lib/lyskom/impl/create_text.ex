defmodule Lyskom.Impl.CreateText do
  alias Lyskom.ProtA.Type

  def to_prot_a(args) do
    subject = Keyword.get(args, :subject, "")
    body = Keyword.get(args, :body, "")
    content = Type.hollerith(subject <> "\n" <> body)

    misc_items =
      Enum.filter(args, fn {type, _data} ->
        type in [:recpt, :cc_recpt, :bcc_recpt, :comm_to, :footn_to]
      end)
      |> Type.array(&Type.MiscInfo.prot_a/1)

    aux_items =
      [
        %Type.AuxItem{
          tag: 1,
          data: "text/x-kom-basic;charset=utf-8",
          flags: %Type.AuxItemFlags{},
          inherit_limit: 0
        }
      ]
      |> Type.array(&Type.AuxItem.prot_a/1)

    [content, misc_items, aux_items]
  end
end
