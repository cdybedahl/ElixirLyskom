defmodule Lyskom.Prot_A.Type do

  defmodule AuxItem do
    defstruct [:no, :tag, :creator, :created_at, :flags, :inherit_limit, :data]
  end

  defmodule MiscInfo do
    defstruct [:type, :data]
  end

  ### Encoding

  def hollerith(str) do
    "#{String.length(str)}H#{str}"
  end

  def boolean(true) do
    1
  end

  def boolean(false) do
    0
  end

end
