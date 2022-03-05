# Carioca

## Installation

Install it yourself as:

    $ gem install carioca

## Usage


### Basic usage

Create you own gem :

    $ bundle gem yourgem
    $ cd yourgem
    $ vi yourgem.gemspec

check all the TODO in your gemspec, specify concretly you Gem specification, add the following line :

```ruby
     spec.add_dependency "carioca", "~> 2.0"
```
and after :

    $ bundle add carioca
    $ mkdir -p config/locales

Edit the Rakefil, and add the following line :

```ruby
require "carioca/rake/manage"
```
Verify, all is right with :

    $ rake -T
    rake build                         # Build yourgem-0.1.0.gem into the pkg directory
    rake carioca:registry:add_service  # Adding service to Carioca Registry file
    rake clean                         # Remove any temporary products
    rake clobber                       # Remove any generated files
    rake install                       # Build and install yourgem-0.1.0.gem into system gems
    rake install:local                 # Build and install yourgem-0.1.0.gem into system gems without network access
    rake release[remote]               # Create tag v0.1.0 and build and push yourgem-0.1.0.gem to Set to 'http://mygemserver.com'
    rake spec                          # Run RSpec code examples

You could now initialize the Carioca registry following the wizard, with (sample with a simple UUID generator gem): 

    $ rake carioca:registry:add_service
    Carioca : registering service :
    Registry File path ? ./config/carioca.registry
    Service name ? uuid
    Choose the service type ? gem
    Description ? The uuid service
    Service [uuid] inline Proc Ruby code ? UUID
    Give the Rubygem name ?  uuid
    Did this service have dependencies ?  no

     => Service : uuid
    Definition
     * type: gem
     * description: The uuid service
     * service: UUID
     * resource: uuid
    Is it correct ?  Yes
    Carioca : Registry saved

This will initiate a Carioca Registry (YAML file, the format will be describe after, the wizard support all type of services, managed by Carioca, all keys are Symbols):

    $ cat config/carioca.registry
    ---
    :uuid:
      :type: :gem
      :description: The uuid service
      :service: UUID
      :resource: uuid

Now your are ready to use Carioca :

In this sample, we are going th create a demo command. 
Firstly, we have to configure a basic usage of Carioca, this could be made in the lib path, in the root gem library. 

    $ emacs lib/yourgem.rb 

content of the destination file 

```ruby

# frozen_string_literal: true

require_relative "yourgem/version"
require 'carioca'


Carioca::Registry.configure do |spec|
  spec.debug = true
end

module Yourgem
  class Error < StandardError; end

  class YourgemCMD < Carioca::Container
    def test
      logger.info(self.to_s) { "Log me as an instance method" }
      logger.warn(self.class.to_s) {"Give me an UUID : "  + uuid.generate}
    end

    inject service: :uuid

    logger.info(self.to_s) { "Log me as class method" }

  end

end

```

    $ emacs exe/yourgem_cmd

content of the file

```ruby
require 'yourgem'

yourgem_cmd = Yourgem::YourgemCMD::new
yourgem_cmd.test
```

After this, don't forget to stage new files, and you could build & install the gem before running your new command for the first time :

    $ git add config/ exe/
    $ rake install && yourgem_cmd
    yourgem 0.1.0 built to pkg/yourgem-0.1.0.gem.
    yourgem (0.1.0) installed.
    D, [2022-03-04T23:11:52.663459 #88808] DEBUG -- Carioca: Preloaded service :i18n on locale : en
    D, [2022-03-04T23:11:52.663519 #88808] DEBUG -- Carioca: Preloaded service :logger ready on STDOUT
    D, [2022-03-04T23:11:52.663537 #88808] DEBUG -- Carioca: Initializing Carioca registry
    D, [2022-03-04T23:11:52.663550 #88808] DEBUG -- Carioca: Preparing builtins services
    D, [2022-03-04T23:11:52.663580 #88808] DEBUG -- Carioca: Adding service configuration
    D, [2022-03-04T23:11:52.663609 #88808] DEBUG -- Carioca: Adding service i18n
    D, [2022-03-04T23:11:52.663649 #88808] DEBUG -- Carioca: Initializing registry from file : ./config/carioca.registry
    D, [2022-03-04T23:11:52.663773 #88808] DEBUG -- Carioca: Adding service uuid
    D, [2022-03-04T23:11:52.663794 #88808] DEBUG -- Carioca: Registry initialized successfully
    I, [2022-03-04T23:11:52.663802 #88808]  INFO -- Sample::YourGemCMD: Log me as class method
    I, [2022-03-04T23:11:52.663813 #88808]  INFO -- #<Sample::YourGemCMD:0x00000001312c0bf0>: Log me as an instance method
    D, [2022-03-04T23:11:52.663844 #88808] DEBUG -- Carioca: Starting service uuid
    W, [2022-03-04T23:11:52.682812 #88808]  WARN -- Sample::YourGemCMD: Give me an UUID : 0505f3f0-7e36-013a-22c7-1e00870a7189

You could see, somme interesting things : 
* Carioca have an internationalisation service (this service will be explain in detail after): 
  * default configured on :en locale
  * must be in French (:fr) or English (:en), other traductions are welcome
* Carioca have a builtin logger service using regular Logger from Stdlib (also explain in detail in this document)
  * default logging on STDOUT, but could be redirect in the configure bloc
* Carioca give us some usefull traces in debug   
* Carioca come with a Container Class Template
  * the Container automatically inject :logger, :i18n and a :configuration service (explain in detail after) 
  * the Container provide a class method macro :inject 
    *  this macro give a way to use other services defined in the registry file (service could be register inline, presented after)   

## A step further 


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Ultragreen/carioca.
