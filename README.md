# MandrillQueue::Mailer

DSL for sending mailers through Mailchimps Mandrill API. This gem enqueues the
message on a background worker (`Resque` only for now, but I want to refactor
so that it doesnt matter).

The DSL is modelled on the JSON api [here](https://mandrillapp.com/api/docs/messages.ruby.html#method=send-template).

_This is my first gem, so tell me when I suck and I will try and absorb your genius
to not suck so much.

## The DSL

    # app/mailers/my_mailer.rb
    class MyMailer < MandrillQueue::Mailer
      # Template names are inferred from the class_name (with Mailer) + the method
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
    # Devise will also call deliver, so you can put your devise templates on Mandrill!
    # It will not render your devise views, but you can do it manually a la `message() {html '...'}`
    MyMailer.welcome_many(users).deliver

## Installation

You already know this bit:

    gem 'mandrill-queue'

but didn't know this (but it's optional):

    rails g mandrill_queue:initializer

Global configuration options are documented in the initializer
but heres a taster:
    MandrillQueue.configure do |config|
      config.queue = :hipster_queue
      # ...
    end

## Setting up the worker

Run it with a rake task like so:

    rake resque:work QUEUES=mailer

TODO: I still need to check that everything is OK when running the worker in Rails
since I run mine outside Rails as a lightweight worker using:

    rake resque:work -r ./worker.rb QUEUES=mailer

## TODO

1. Refactor so that it can work with `Sidekiq` - this is an easy one!
2. Render ActionView views to mailers

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
