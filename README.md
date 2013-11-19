==========================
  MandrillQueue::Mailer
==========================

DSL for sending mailers through Mailchimps Mandrill API. This gem enqueues the
message on a background worker (`Resque` only for now, but I want to refactor
so that it doesnt matter).

The DSL is modelled on the JSON api [here](https://mandrillapp.com/api/docs/messages.ruby.html#method=send-template).

## The DSL

```ruby
# app/mailers/my_mailer.rb
class MyMailer < MandrillQueue::Mailer
  # Template names are inferred from the class_name (without Mailer) + the method
  # name. Spaces are `sluggified`. If you want to override the prefixes use:
  # template_prefix 'my-project'
  # now templates will be 'my-project' + sluggified method
  #
  # template_prefix '' means no prefix will be used

  # Set defaults for all methods here.
  # The full DSL is available here so feel free to include `merge_vars`,
  # `preserve_recipients`, `to` etc.
  # Settings here have a lower precedence than method settings.
  #
  defaults do
    # Setting the default template will disable implicit template names
    # template 'master_template'
    message do
      from_email 'no-reply@mysite.com'
    end

    content do ... end
  end

  def welcome_dave
    template 'welcome'

    message do
      to 'dave@amazabal.ls', 'Dave' # Name optional
      cc 'davesmom@yahoo.com'
      bcc 'daves-sis@gmail.com'

      to [{email: 'another@person.com', name: 'Another'}, ...]
    end

    # Template content
    # e.g. <div mc:edit="my_tag"></div>
    content do
      my_tag '<p>Content!</p>'
    end
  end

  def welcome_many(users)
    message do
      # If the given parameter is an array of objects or hashes
      # that respond_to?/has_key? `email` then we're good to go.
      # Same goes for `name`. Second and third parameters override this
      # e.g. to users, :work_email, :fullname
      to users

      # You can also do your own mapping (to, cc and bcc have the same DSL):
      cc users do |user|
        email user.work_email
        name "#{user.firstname} #{user.lastname}"
      end
    end
  end

  def message_with_merge_vars(vars) # Template slug: my-message-with-merge-vars
    message do
      to 'some@email.com'

      global_merge_vars do ... end
      global_merge_vars {vars: 'everywhere'}

      # Substitute *|MERGE_VARS|* in your template for given recipients
      merge_vars 'some@email.com' do
        key 'value'
        whatever 'you want'
        this_will 'only apply to some@email.com'
      end
      # If an array of objects/hashes contains an email method or key
      # that will be used as the recipient and the rest as normal vars.
      merge_vars vars #, :other_email_field

      track_clicks false
  end

  # Use send_at/send_in (no difference) to tell Mandrill to delay sending
  send_in 2.days.from_now
end

def html_message(html)
  message do
    # (omitted)
    html "<html><body>#{html}</html></body>"
  end
end

# Meanwhile in another file...
# maybe your controller...
# Just like ActionMailer (note the class method calls are handed to instance methods)
MyMailer.welcome_many(users).deliver
```

## Installation

You probably already know this bit:

    gem 'resque' # Support for Sidekiq and writing custom adapters coming soon...
    gem 'mandrill-queue'

but didn't know this (but it's optional):

    rails g mandrill_queue:initializer

Global configuration options are documented in the initializer
but heres a taster:

```ruby
    MandrillQueue.configure do |config|
      config.queue = :hipster_queue
      # ...
    end
```

## Setting up the worker

Run it with a rake task like so:

    rake resque:work QUEUES=mailer

TODO: I still need to check that everything is OK when running the worker in Rails
since I run mine outside Rails as a lightweight worker using:

    rake resque:work -r ./worker.rb QUEUES=mailer


## Devise mailer integration

Since Mandrill_Queue quacks like ActionMailer where it counts, getting your Devise
mailers on Mandrill infrastructure is pretty easy. Here is my implementation:

```ruby
class DeviseMailer < MandrillResque::Mailer
  defaults do
    message do
      from_email Devise.mailer_sender
      track_clicks false
      track_opens false
      view_content_link false
    end
  end

  # Setup a template with the slug: devise-confirmation-instructions
  def confirmation_instructions(record, token, opts = {})
    confirm_url = user_confirmation_url(record, confirmation_token: token)
    devise_mail(record, {name: record.fullname, confirmation_url: confirm_url})
  end

  # Slug: devise-reset-password-instructions
  def reset_password_instructions(record, token, opts = {})
    reset_url = edit_user_password_url(record, reset_password_token: token)
    devise_mail(record, {name: record.fullname, reset_url: reset_url})
  end

  # Slug: devise-unlock-instructions
  def unlock_instructions(record, token, opts = {})
    unlock_url = user_unlock_url(record, unlock_token: token)
    devise_mail(record, {name: record.fullname, unlock_url: unlock_url})
  end

  protected
  def devise_mail(record, global_vars = {})
    message do
      to record, :email, :fullname

      global_merge_vars global_vars
    end
  end
end
```

## TODO

1. Refactor so that it can work with `Sidekiq` or a custom adapter - coming soon...
2. Allow synchonous sending.
2. Render ActionView views to mailers.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
