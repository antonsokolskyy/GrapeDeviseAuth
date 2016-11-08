# GrapeDeviseAuth

GrapeDeviseAuth allows to use [devise][3] based registration/authorization inside [grape][2]. This gem is based on [grape_devise_auth_token][1] so all credit goes to its authors.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'grape_devise_auth'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grape_devise_auth

## Usage

Place this line in an initializer in your rails app or at least somewhere before
the grape API will get loaded:

```ruby
GrapeDeviseAuth.setup!
```

Available config parameters and default values:

```
batch_request_buffer_throttle = 2.weeks
change_headers_on_each_request = true
authenticate_all = false
default_provider = 'email'
@token_lifespan = 2.weeks
@max_number_of_devices = 10
@headers_names = {:'access-token' => 'access-token',
                        :'client' => 'client',
                        :'expiry' => 'expiry',
                        :'uid' => 'uid',
                        :'token-type' => 'token-type' }
@remove_tokens_after_password_reset = false
```

Within the Grape API:

```
class Posts < Grape::API
  auth :grape_devise_auth, resource_class: :user

  helpers GrapeDeviseAuth::AuthHelpers

  # ...
end
```

Inside your User model:

```
include GrapeDeviseAuth::Concerns::User

  # ...
```

Endpoints can be called by `method_name_YOUR_MAPPING_HERE!` (e.g. `authenticate_user!`).

For Example:

```
get '/' do
  authenticate_user!
  login_user!
  logout_user!
  register_user!
end
```

Devise routes must be present:

```
Rails.application.routes.draw do
  devise_for :users
end
```

Every endpoind has a version that doesn't fail or returns 401. For example authenticate_user(notice that it lacks of exclamation mark)


Necessary parameters for endpoints:

login_user!        - uid and password (inside request body)

register_user!     - uid and any field to have validation for (inside request body)

authenticate_user! - uid, client, access-token (inside request headers)



[1]: https://github.com/mcordell/grape_devise_token_auth
[2]: https://github.com/intridea/grape
[3]: https://github.com/plataformatec/devise

