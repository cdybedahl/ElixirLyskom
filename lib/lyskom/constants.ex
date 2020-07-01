defmodule Lyskom.Constants do
  @asyncs %{
    0 => :async_new_text_old,
    1 => :async_i_am_off,
    2 => :async_i_am_on_obsolete,
    5 => :async_new_name,
    6 => :async_i_am_on,
    7 => :async_sync_db,
    8 => :async_leave_conf,
    9 => :async_login,
    10 => :async_broadcast,
    11 => :async_rejected_connection,
    12 => :async_send_message,
    13 => :async_logout,
    14 => :async_deleted_text,
    15 => :async_new_text,
    16 => :async_new_recipient,
    17 => :async_sub_recipient,
    18 => :async_new_membership,
    19 => :async_new_user_area,
    20 => :async_new_presentation,
    21 => :async_new_motd,
    22 => :async_text_aux_changed
  }

  @errors %{
    0 => :no_error,
    2 => :not_implemented,
    3 => :obsolete_call,
    4 => :invalid_password,
    5 => :string_too_long,
    6 => :login_first,
    7 => :login_disallowed,
    8 => :conference_zero,
    9 => :undefined_conference,
    10 => :undefined_person,
    11 => :access_denied,
    12 => :permission_denied,
    13 => :not_member,
    14 => :no_such_text,
    15 => :text_zero,
    16 => :no_such_local_text,
    17 => :local_text_zero,
    18 => :bad_name,
    19 => :index_out_of_range,
    20 => :conference_exists,
    21 => :person_exists,
    22 => :secret_public,
    23 => :letterbox,
    24 => :ldb_error,
    25 => :illegal_misc,
    26 => :illegal_info_type,
    27 => :already_recipient,
    28 => :already_comment,
    29 => :already_footnote,
    30 => :not_recipient,
    31 => :not_comment,
    32 => :not_footnote,
    33 => :recipient_limit,
    34 => :comment_limit,
    35 => :footnote_limit,
    36 => :mark_limit,
    37 => :not_author,
    38 => :no_connect,
    39 => :out_of_memory,
    40 => :server_is_crazy,
    41 => :client_is_crazy,
    42 => :undefined_session,
    43 => :regexp_error,
    44 => :not_marked,
    45 => :temporary_failure,
    46 => :long_array,
    47 => :anonymous_rejected,
    48 => :illegal_aux_item,
    49 => :aux_item_permission,
    50 => :unknown_async,
    51 => :internal_error,
    52 => :feature_disabled,
    53 => :message_not_sent,
    54 => :invalid_membership_type,
    55 => :invalid_range,
    56 => :invalid_range_list,
    57 => :undefined_measurement,
    58 => :priority_denied,
    59 => :weight_denied,
    60 => :weight_zero,
    61 => :bad_bool
  }

  def async(l) when is_list(l), do: async(List.to_integer(l))
  def async(s) when is_binary(s), do: async(String.to_integer(s))

  for {number, atom} <- @asyncs do
    def async(unquote(number)) when is_integer(unquote(number)), do: unquote(atom)
    def async(unquote(atom)) when is_atom(unquote(atom)), do: unquote(number)
  end

  def async(_), do: throw("Not a defined asynchronous call")

  def error_code(l) when is_list(l), do: error_code(List.to_integer(l))
  def error_code(s) when is_binary(s), do: error_code(String.to_integer(s))

  for {number, atom} <- @errors do
    def error_code(unquote(number)) when is_integer(unquote(number)), do: unquote(atom)
    def error_code(unquote(atom)) when is_atom(unquote(atom)), do: unquote(number)
  end

  def error_code(_), do: throw("Not a defined error_codehronous call")
end
