module ActionDispatch::Routing
  class Mapper

  protected
    def devise_capturable(mapping, controllers)
      get 'federate_logout' => 'sessions#destroy'
      get 'reset_password' => 'passwords#edit'
    end

  end
end
