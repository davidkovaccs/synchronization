require 'refinerycms-core'

module Refinery
  autoload :SynchronizationsGenerator, 'generators/refinery/synchronizations_generator'

  module Synchronizations
    require 'refinery/synchronizations/engine'
    require 'refinery/synchronizations/basic_auth'
    require 'refinery/synchronizations/exceptions'

    class << self
      attr_writer :root

      def root
        @root ||= Pathname.new(File.expand_path('../../../', __FILE__))
      end

      def factory_paths
        @factory_paths ||= [ root.join('spec', 'factories').to_s ]
      end
    end
  end
end
