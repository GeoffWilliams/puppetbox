[![Build Status](https://travis-ci.org/GeoffWilliams/puppetbox.svg?branch=master)](https://travis-ci.org/GeoffWilliams/puppetbox)
# Puppetbox

 A box running puppet :)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'puppetbox'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install puppetbox

## Usage

TODO: Write usage instructions here

## Development

### Additional vagrant boxes
Many vagrant boxes that would be useful can't be shared for legal reasons, eg windows, suse, etc.  These requirements can be worked around by users producing their own Vagrant boxes for internal use.

A really good source of build scripts is [bento](https://github.com/chef/bento) from Chef.

PuppetBox requires each box:
* Has puppet installed
* Has all puppet executables in `$PATH`
* Has the ability to work with vagrant shared folders.  This usually means guestbox additions must be installed, although rsync can work in some situations.  When using rsync, remember that your code will only be synced as your VM is reloaded

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/puppetbox.
