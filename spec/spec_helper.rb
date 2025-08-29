require 'gem_hadar/simplecov'
GemHadar::SimpleCov.start
require 'rspec'
begin
  require 'debug'
rescue LoadError
end
require 'gem_hadar'
