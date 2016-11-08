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

####Available config parameters and default values:

Sometimes it's necessary to make several requests to the API at the same time. In this case, each request in the batch will need to share the same auth token. This setting determines how far apart the requests can be while still using the same auth token.
```
batch_request_buffer_throttle = 2.weeks
```


By default the authorization headers will change after each request. The client is responsible for keeping track of the changing tokens. Change this to false to prevent the Authorization header from changing after each request.
```
change_headers_on_each_request = true
```


Set default provider for newly created user. This field uses to determine what field will be used as uid
```
default_provider = 'email'
```


By default, users will need to re-authenticate after 2 weeks. This setting determines how long tokens will remain valid after they are issued.
```
token_lifespan = 2.weeks
```


Sets the max number of concurrent devices per user, which is 10 by default. After this limit is reached, the oldest tokens will be removed.
```
max_number_of_devices = 10
```


Makes it possible to change the headers names
```
headers_names = {:'access-token' => 'access-token',
                 :'client' => 'client',
                 :'expiry' => 'expiry',
                 :'uid' => 'uid',
                 :'token-type' => 'token-type' }
```


When set to false, does not sign a user in automatically after their password is reset. Defaults to false, so a user is not signed in automatically after a reset.
```
remove_tokens_after_password_reset = false
```

####Within the Grape API:

```
class Posts < Grape::API
  auth :grape_devise_auth, resource_class: :user

  helpers GrapeDeviseAuth::AuthHelpers

  # ...
end
```

####Inside your User model:

```
class User < ActiveRecord::Base
  include GrapeDeviseAuth::Concerns::User

  # ...
end
```

####Endpoints can be called by `method_name_YOUR_MAPPING_HERE!` (e.g. `authenticate_user!`).

For Example:

```
get '/' do
  authenticate_user!
  login_user!
  logout_user!
  register_user!
end
```

Every endpoind has a version that doesn't fail or returns 401. For example authenticate_user(notice that it lacks of exclamation mark)


Get current auth headers:

```
user_auth_headers
```


####Devise routes must be present:

```
Rails.application.routes.draw do
  devise_for :users
end
```

###Necessary parameters for endpoints:

login_user!        - uid and password (inside request body)

register_user!     - uid and any fields you have validations for (inside request body)

authenticate_user! - uid, client, access-token (inside request headers)



[1]: https://github.com/mcordell/grape_devise_token_auth
[2]: https://github.com/intridea/grape
[3]: https://github.com/plataformatec/devise

