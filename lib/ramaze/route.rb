#          Copyright (c) 2008 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

# Ramaze support simple routing using string, regex and lambda based routers.
# Route are stored in a dictionary, which supports hash-like access but
# preserves order, so routes are evaluated in the order they are added.
#
# String routers are the simplest way to route in Ramaze. One path is
# translated into another:
#
#   Ramaze::Route[ '/foo' ] = '/bar'
#     '/foo'  =>  '/bar'
#
# Regex routers allow matching against paths using regex. Matches within
# your regex using () are substituted in the new path using printf-like
# syntax.
#
#   Ramaze::Route[ %r!^/(\d+)\.te?xt$! ] = "/text/%d"
#     '/123.txt'  =>  '/text/123'
#     '/789.text' =>  '/text/789'
#
# For more complex routing, lambda routers can be used. Lambda routers are
# passed in the current path and request object, and must return either a new
# path string, or nil.
#
#   Ramaze::Route[ 'name of route' ] = lambda{ |path, request|
#     '/bar' if path == '/foo' and request[:bar] == '1'
#   }
#     '/foo'        =>  '/foo'
#     '/foo?bar=1'  =>  '/bar'
#
# Lambda routers can also use this alternative syntax:
#
#   Ramaze::Route('name of route') do |path, request|
#     '/bar' if path == '/foo' and request[:bar] == '1'
#   end

module Ramaze
  class Route
    trait :routes => Dictionary.new

    class << self
      def [](key)
        trait[:routes][key]
      end

      def []=(key, value)
        trait[:routes][key] = value
      end
    end
  end

  def self.Route(name, &block)
    Route[name] = block
  end
end