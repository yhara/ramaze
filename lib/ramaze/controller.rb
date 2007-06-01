#          Copyright (c) 2006 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

require 'ramaze/helper'
require 'ramaze/template'
require 'ramaze/action'

require 'ramaze/controller/resolve'
require 'ramaze/controller/render'
require 'ramaze/controller/error'

module Ramaze

  # The Controller is responsible for combining and rendering actions.

  class Controller
    include Ramaze::Helper
    extend Ramaze::Helper

    helper :redirect, :link, :file, :flash, :cgi

    # Place register_engine puts the class and extensions for templating engines

    TEMPLATE_ENGINES = [] unless defined?(TEMPLATE_ENGINES)

    # Whether or not to map this controller on startup automatically

    trait[:automap] ||= true

    # Place to map the Controller to, this is something like '/' or '/foo'

    trait[:map] ||= nil

    # Modules that are excluded from the Action lookup

    trait :exclude_action_modules => [Kernel, Object, PP::ObjectMixin]

    # Caches patterns for the given path.

    trait :pattern_cache => Hash.new{|h,k| h[k] = Controller.pattern_for(k) }

    class << self
      include Ramaze::Helper
      extend Ramaze::Helper

      # When Controller is subclassed the resulting class is placed in
      # Global.controllers and a new trait :actions_cached is set on it.

      def inherited controller
        controller.trait :actions_cached => Set.new
        Global.controllers << controller
      end

      # called from Ramaze.startup, adds Cache.actions and Cache.patterns, walks
      # all controllers subclassed so far and adds them to the Global.mapping if
      # they are not assigned yet.

      def startup options = {}
        Inform.debug("found Controllers: #{Global.controllers.inspect}")

        Cache.add :actions, :patterns

        Global.controllers.each do |controller|
          if map = controller.mapping
            Inform.debug("mapping #{map} => #{controller}")
            Global.mapping[map] ||= controller
          end
        end

        Inform.debug("mapped Controllers: #{Global.mapping.inspect}")
      end

      # checks paths for existance and logs a warning if it doesn't exist yet.

      def check_path(path, message)
        Inform.warn(message) unless File.directory?(path)
      end

      # if trait[:automap] is set and controller is not in Global.mapping yet
      # this will build a new default mapping-point, (Main|Base|Index)* are put
      # at '/' by default.

      def mapping
        global_mapping = Global.mapping.invert[self]
        return global_mapping if global_mapping
        if ancestral_trait[:automap]
          name = self.to_s.gsub('Controller', '').split('::').last
          %w[Main Base Index].include?(name) ? '/' : "/#{name.snake_case}"
        end
      end

      # Map Controller to the given syms or strings.

      def map(*syms)
        syms.each do |sym|
          Global.mapping[sym.to_s] = self
        end
      end

      # Define a template_root for Controller, returns the current template_root
      # if no argument is given.
      # Runs every given path through Controller::check_path

      def template_root path = nil
        if path
          message = "#{self}.template_root is #{path} which does not exist"
          check_path(path, message)
          @template_root = path
        else
          @template_root
        end
      end

      # This is used for template rerouting, takes action, optionally a
      # controller and action to route to.
      #
      # Usage:
      #   class MainController
      #     template :index, OtherController, :list
      #     template :foo, :bar
      #
      #     def index
      #       'will use template from OtherController#list'
      #     end
      #
      #     def foo
      #       'will use template from self#bar'
      #     end
      #   end

      def template(this, from, that = nil)
        from, that = self, from unless that
        trait "#{this}_template" => [from, that.to_s]
      end

      # Return Controller of current Action

      def current
        Thread.current[:controller]
      end

      # Entering point for Dispatcher, first Controller::resolve(path) and then
      # renders the resulting Action.

      def handle path
        controller, action = *resolve(path)
        controller.render(action)
      end
    end

    private

    # Simplistic render, rerouting to Controller.handle(*args)

    def render *args
      self.class.handle(*args)
    end
  end
end
