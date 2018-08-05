module Pronto
  module ClangTidy
    # a class that represents a single diagnostic emitted by clang-tidy
    class Diagnostic
      attr_reader :filename, :line_no, :col_no, :level, :message, :hints
      def initialize(filename, line_no, col_no, level, message)
        @filename = filename
        @line_no = line_no.to_i
        @col_no = col_no.to_i
        @level = level.to_sym
        @message = message
        @hints = ''
      end
    end
  end
end
