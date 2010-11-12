module Golem
  module Actions
    class Survey < Action

      attr_reader :blueprint

      def setup(blueprint_file, center)
        @center = center
        @blueprint = Blueprint.new(blueprint_file, center)

        log "survey of #{blueprint_file} centered at #{center.inspect} -- #{blueprint.range.inspect}"
        survey = blueprint.survey_coords(map)
        log "#{survey.size} changes"
        survey.each do |location, change|
          change = change.map {|c| BLOCKS[c] }
          log "  #{location.inspect}: #{change.inspect}"
        end

      rescue Errno::ENOENT => e
        log "#{e.message}"
      end

      def done?
        true
      end
    end
  end
end
