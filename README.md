# Devise::Capturable

`Devise::Capturable` is a gem that makes it possible to use the Janrain Engage user registration widget, while still having a Devise authentication setup with a Rails `User` model.

In the following I use the name `User` for the Devise user model, but it will work with any Devise-enabled model.

## Flow

This gem will replace the normal Devise `registrations` and `sessions` views with the Janrain user registration widget. The flow is as follows.

* User clicks a login link
* User is presented with the user registration widget and either registers or logs in
* The gem automatically listens to the widget's `onCaptureLoginSuccess` event, grabs the oauth code, and makes a `POST` request with the OAuth code to the `sessions_controller`
* The gem will grab the oauth token in the `session_controller`, load the user data from the Capture API (to ensure the validity of the token), and either create a new user or log in the user if the user already exists in the Rails DB.

## Setup

You will need to perform these steps to setup the gem.

#### Add gem to Gemfile

```ruby
gem "devise_capturable", :git => "git://github.com/runemadsen/devise-capturable.git"
```

#### Add `:capturable` to your `User` model

```ruby
class User < ActiveRecord::Base
  devise ..., :capturable
end
```

#### Update initializer

In your `config/initializers/devise.rb` initializer, add the following settings.

```ruby
Devise.setup do |config|
  config.capturable_endpoint = "https://myapp.janraincapture.com"  
  config.capturable_client_id = "myclientid"
  config.capturable_client_secret = "myclientsecret"
end
```

#### Add Gem Javascript to you asset pipeline

The gem ships with a JS file that automatically subscribes to the login event and makes a POST to the `sessions_controller`. Make sure to include it in you asset pipeline.

```javascript
//= require devise_capturable
```

#### Add Janrain Javascript

Now add the script provided by Janrain with `janrainDefaultSettings()`, `janrainInitLoad()`, and all the HTML template strings to your application layout. You might need to include a different script in your development environment.

Keep in mind that this script does not need to include any `onCaptureLoginSuccess` event listeners or other event code. The gem will handle that for you.

```html
<html>
  <head>
  	...
    <script type="text/javascript" id="janrainCaptureDevScript">
      // YOUR CODE HERE
     </script>
  </head>
  <body>
  	...
  </body>
 </html>
```

#### Add Janrain CSS

Now add the Janrain CSS to your asset pipeline. Simply copy `janrain.css` and `janrain-mobile.css` to `app/assets/stylesheets`.

#### Add links

The gem ships with a helper method to show a link that opens the widget. You will use this to show the login / registration form, but use the normal `destroy_user_session_path` helper to log out the user. This is because Devise, not Capture, is controlling the user cookie.

```erb
<ul class="nav">
  <% if user_signed_in? %>
    <li><%= link_to 'Logout', destroy_user_session_path, :method=>'delete' %></li>
  <% else %>
    <li><%= link_to_capturable "Sign In / Sign Up" %></li>
  <% end %>
</ul>
```

#### Done!

That's it! 

By default Devise will now create a database record when the user logs in for the first time. On following logins, the user will just be logged in. The only property Devise will save in the user model is the `email` address provided by Capture. You can however change this (See "Changing Defaults")

## Automated Settings

The Janrain User Registration widget relies on settings that are 1) never used and 2) breaks the widget if they are not present. To circumvent this madness, this gem will automatically set a bunch of janrain setting variables for you:

```javascript
// these settings will always be the same
janrain.settings.capture.flowName = 'signIn';
janrain.settings.capture.responseType = 'code';
janrain.settings.capture.setProfileCookie = false;
janrain.settings.capture.keepProfileCookieAfterLogout = false;
janrain.settings.language = 'en';

// these settings are never used but crashes the widget if not present
janrain.settings.capture.redirectUri = 'http://stupidsettings.com';
```

You can delete these settings from your embed code, as the gem will set them for you. Remember that you still need a `tokenUrl` setting with a whitelisted URL, even though this setting is never used either.

## Changing defaults


#### Overriding `set_capturable_params`

There are times where you might want to save more than the `email` of your user in the Rails `User` model. You can override the `set_capturable_params` instance method to do this. Here's an example where I'm also saving the `uuid`. The `capture_data` parameter passed to the function is the Janrain Capture `entity` JSON result that has a bunch of information about the user.

```ruby
class User < ActiveRecord::Base
  devise ..., :capturable
  attr_accessible ..., :email, uuid
  def set_capturable_params(capture_data)
  	self.email = capture_data["email"]
  	self.uuid = capture_data["uuid"]
  end
end
```

#### Overriding `find_with_capturable_params`

When a user logs in, Devise will call the Capture API and try to find a user with the email returned by the API. You can change this by overriding the `find_with_capturable_params` instance method in your `User` model. Here's an example where I'm telling Devise to find the user by the `uuid` instead.

```ruby
def find_with_capturable_params(capture_data)
	self.find_by_uuid(capture_data["uuid"])
end
```

#### Disabling User Creation

By default the gem will create a user if the user doesn't exist in the system. If you want to disable the creation of new users, and only allow current users to log in, you can disable automatic account creation in your `config/intitializers/devise.rb` initializer.

```ruby
Devise.setup do |config|
	config.capturable_auto_create_account = false
end
```

## Example Application

I've made an example application that demonstrates how to integrate this gem with Rails. You can find it here.

[Rails Capturable Example](https://github.com/runemadsen/capture_example)

## TODO

* Ability to add the Janrain script to the asset pipeline. However, it relies on an 'id', which makes it harder.
* Remove normal Devise sign_in routes? Or leave it up to the user?

