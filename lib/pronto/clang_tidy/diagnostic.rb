require 'pathname'

module Pronto
  module ClangTidy
    # a class that represents a single diagnostic emitted by clang-tidy
    class Diagnostic
      attr_reader :filename, :line_no, :col_no, :level, :message, :hints
      def initialize(filename, line_no, col_no, level, message)
        @filename = abs(filename)
        @line_no = line_no.to_i
        @col_no = col_no.to_i
        @level = level.to_sym
        @message = message
        @hints = ''
      end

      def formatted_filename
        # output a relative path when filename is inside working directory
        if filename.to_s.start_with?(abs(Pathname.pwd).to_s)
          filename.relative_path_from(Pathname.pwd)
        else
          filename.to_s # absolute otherwise
        end
      end

      def format_diagnostic
        "#{formatted_filename}:#{line_no}:#{col_no}: #{level}: #{message}\n" \
        "```\n#{hints}```\n"
      end

      private

      # converts the given String or Pathname to an absolute Pathname
      def abs(pathname)
        Pathname.new File.absolute_path Pathname.new pathname
      end
    end
  end
end
