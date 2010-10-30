module Golem
  module Actions
    class Survey < Action

      attr_reader :blueprint

      def setup(blueprint_file, center)
        @center = center
        @blueprint = Blueprint.new(blueprint_file, center)

        puts "survey of #{blueprint_file} centered at #{center.inspect}:"
        blueprint.survey(map).each do |change|
          puts "  #{change.inspect}"
        end

      rescue Errno::ENOENT => e
        puts "#{e.message}"
      end

      def done?
        true
      end
    end
  end
end
