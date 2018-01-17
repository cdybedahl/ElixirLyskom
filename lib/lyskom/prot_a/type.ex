defmodule Lyskom.Type do

  defmodule AuxItem do
    defstruct [:no, :tag, :creator, :created_at, :flags, :inherit_limit, :data]
  end

  defmodule MiscInfo do
    defstruct [:type, :data]
  end

end
