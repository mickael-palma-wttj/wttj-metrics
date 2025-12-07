# frozen_string_literal: true

module WttjMetrics
  module Services
    # Prepares directories for file output
    class DirectoryPreparer
      def self.ensure_exists(file_path)
        dir = File.dirname(file_path)
        FileUtils.mkdir_p(dir) unless current_directory?(dir)
      end

      def self.current_directory?(dir)
        dir == '.'
      end
      private_class_method :current_directory?
    end
  end
end
