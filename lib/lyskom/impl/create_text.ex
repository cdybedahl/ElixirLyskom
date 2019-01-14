defmodule Lyskom.Impl.CreateText do
  def to_prot_a(args) do
    subject = Keyword.get(args, :subject, "")
    body = Keyword.get(args, :body, "")
    content = subject <> "\n" <> body

    misc_items = Enum.filter(args, fn {type, _data} -> type in [:recpt, :cc_recpt, :bcc_recpt, :comm_to, :footn_to] end)
    aux_items = [%Lyskom.ProtA.Type.AuxItem{tag: 1, data: "text/plain;charset=utf8", flags: %Lyskom.ProtA.Type.AuxItemFlags{}, inherit_limit: 0}]

    [content, misc_items, aux_items]
  end
end
