module Pronto
  module ClangTidy
    # a class that provides functions to parse a clang-tidy output file and
    # returns an array of Offence objects
    class Parser
      def initialize(output_filename)
        @output_filename = output_filename
      end

      # reads clang-tidy output file and returns an array of offences
      def read_clang_tidy_output
        unless FileTest.file? @output_filename
          puts 'WARN: pronto-clang_tidy: clang-tidy output file not found'
          return []
        end
        parse_clang_tidy_output File.read(@output_filename)
      end

      private

      # parses clang-tidy output and returns a list of offences
      def parse_clang_tidy_output(output)
        # a regular expression that matches diagnostics' headers
        header_regexp = Regexp.new '(?<filename>^/[^:]+):(?<line_no>\d+):' \
                                   '(?<col_no>\d+): (?<level>[^:]+): ' \
                                   '(?<message>.+$)'
        diagnostics = []
        output.each_line do |line|
          if (match_data = header_regexp.match(line))
            diagnostics << Diagnostic.new(*match_data.captures)
          else
            diagnostics.last.hints << line unless diagnostics.empty?
          end
        end
        group_diagnostics(diagnostics)
      end

      # turns an array of diagnostics into an array of offences by grouping
      # note-level diagnostics with their corresponding diagnostic
      def group_diagnostics(diags)
        offences = []
        diags.each do |diag|
          if diag.level != :note
            offences << Offence.new(diag)
          else
            offences.last << diag unless offences.empty?
          end
        end
        offences
      end
    end
  end
end
