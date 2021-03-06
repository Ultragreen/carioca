# Carioca

## Content

Author:: Romain GEORGES <romain@ultragreen.net> 
Version:: 1.0
WWW:: http://www.ultragreen.net/projects/carioca

## Description 

CARIOCA is Configuration Agent and Registry with Inversion Of Control for your Applications
Carioca provide a full IoC light Container for designing your applications
Carioca provide :
- a complete Configuration Agent 
- A service Registry (base on IOC/DI pattern)

[![Build Status](https://travis-ci.org/lecid/carioca.png?branch=master)](https://travis-ci.org/lecid/carioca)


## Installation

In a valid Ruby environment :

```
   $ sudo zsh
   # gem ins carioca
```
## Implementation 

* [Carioca]
* [Carioca::Services]
* [Carioca:Services::Registry]

## Utilisation

Carioca may be used to create Ruby applications, based on a service registry 
Carioca come with somes builtin services :
* logger : an Internal logger based on the logger gem.
* Configuration : a Configuration Service, with Yaml percistance, and pretty accessors.
* Debug : a Class Debugger, based on Proxy Design pattern and meta-programation like method_missing   

### Getting start

#### Preparing Gem

Just after Installation, Carioca :

```
  $ gem ins bundler # if needed
  $ bunlde gem myapp
  $ cd myapp
```

Edit your myapp.gemspec, add this line in Gem::Specification bloc :

```ruby
  gem.add_dependency 'carioca'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'carioca'
```

Description and summary need to be changed to be correctly displayed on Rubygems.

so, execute bundle :

```
  $ bundle
```

Your environment, is ready to create your app

#### Prepare Carioca

```
  $ mkdir config
  $ mkdir bin
```

edit bin/myapp :

```ruby
  require 'rubygems' 
  require 'carioca'

  registry = Carioca::Services::Registry.init :file => 'config/myservices.registry'
```


After, you could Run Carioca and discover Builtins Services, you need the write access to config path


```
  $ ruby -e 'require "rubygems"; require "carioca"; reg = Carioca::Services::Registry.init :file => "config/myservices.registry"; reg.discover_builtins; reg.save!'
```


this create you, a New Registry config, with all builtins registered.
Default path :
* config file : ./.config
* log file : /tmp/log.file
Carioca Registry is a Singleton, and services also be unique instance.

Now you could continue coding your bin/myapp

#### Using Configuration Service

```ruby
  require 'rubygems'
  require 'carioca'

  registry = Carioca::Services::Registry.init :file => 'config/myservices.registry'
  config = registry.start_service :name => 'configuration'
  config.setings.db = { :name => 'mydb' }
  config.settings.db.host = "myhost"
  config.settings.db.port = "4545"
  config.settings.email = "my@email.com"
  config.save!
```

#### Using Logger Service

logger is automatically loaded with Carioca, loading registry with :debug => true, let you see the Carioca traces. 

```ruby
  require 'rubygems'
  require 'carioca'

  registry = Carioca::Services::Registry.init :file => 'config/myservices.registry' :debug => true
  log = registry.get_service :name => 'logger'
  log.info('myapp') {'my message' }
```

#### Creating and using your own service

before create your own service :

```
  $ mkdir services
```

Services, must be a class, if not do a wrapper
edit services/myservice.rb

```ruby
  class MyService
      def initialize
      end

      def test(arg = nil)
        return 'OK'
      end
    end
  end
```

You could use the #service_register API (See spec for all details)
but, you could write it directly in YAML in your config/myservices.registry :
add the following lines :

```yaml
  ...
  myservice:
    :type: :file
    :resource: services/myservice.rb
    :description: a test service
    :service: MyServices
  ...

So in your app :

```ruby
  require 'rubygems'
  require 'carioca'

  registry = Carioca::Services::Registry.init :file => 'config/myservices.registry'
  service = registry.start_service :name => 'myservice'
  service.test('titi')
```

#### Using Debug in multiple service instance


in your app, for debug you could use the Proxy Debug (you need to run Carioca Registry in debug mode ) :
(Using "debug_", you create an instance of service debug, so with this syntaxe you could create multiple services instances, with different parameters calling.)

```ruby
  require 'rubygems'
  require 'carioca'

  registry = Carioca::Services::Registry.init :file => 'config/myservices.registry' :debug => true
  proxy1  = registry.get_service :name => 'debug_myservice', :params => {:service => 'myservice'}
  proxy1.test('titi')
```


see the log /tmp/log.file  :

```
    D, [2013-03-23T18:20:39.839826 #76641] DEBUG -- ProxyDebug: BEGIN CALL for mapped service myservice
    D, [2013-03-23T18:20:39.839875 #76641] DEBUG -- ProxyDebug: called: test
    D, [2013-03-23T18:20:39.839920 #76641] DEBUG -- ProxyDebug: args : titi
    D, [2013-03-23T18:20:39.839970 #76641] DEBUG -- ProxyDebug: => returned: OK
    D, [2013-03-23T18:20:39.840014 #76641] DEBUG -- ProxyDebug: END CALL
```

#### Using Gem for a service


For exemple install uuid gem :

```
  $ gem ins uuid
```

add to your YAML config config/myservices.registry :

```yaml
  uuid:
    :type: :gem
    :resource: uuid
    :description: a Rubygems called uuid to build UUID ids.
    :service: UUID  
```

in your app :

```ruby
  require 'rubygems'
  require 'carioca'

  registry = Carioca::Services::Registry.init :file => 'config/myservices.registry' :debug => true
  uuid  = registry.get_service :name => 'uuid'
  uuid.generate
```

== Copyright

<pre>carioca (c) 2012-2013 Romain GEORGES <romain@ultragreen.net> for Ultragreen Software </pre>

