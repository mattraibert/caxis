$stdout.sync = true

Dir["#{File.dirname(__FILE__)}/cactus*.rb"].each { |f| load(f) }

Cactus.run!
