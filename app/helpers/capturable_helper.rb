module CapturableHelper
  def display_logout?
    clean_url = request.original_url.split('?')[0]
    [new_user_session_url, user_reset_password_url].exclude? clean_url
  end
end