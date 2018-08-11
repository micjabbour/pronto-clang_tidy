require 'pronto'
require_relative 'clang_tidy/diagnostic'
require_relative 'clang_tidy/offence'

Diagnostic = ::Pronto::ClangTidy::Diagnostic
Offence = ::Pronto::ClangTidy::Offence

module Pronto
  class ClangTidyRunner < Runner
    def run
      offences = read_clang_tidy_output
      return [] if no_patches? || offences.length.zero?
      # loop through all offences in clang-tidy output
      offences.map do |offence|
        # find the patch that corresponds to the current offence
        patch = patch_for(offence.main.filename)
        next if patch.nil?
        # generate a message for the corresponding added_line in the patch
        message_for(patch, offence)
        # Header warnings are repeated for every compilation unit that includes
        # them. Use uniq to ignore repeated messages
      end.flatten.compact.uniq
    end

    private

    def message_for(patch, offence)
      line = patch.added_lines.find do |added_line|
        added_line.new_lineno == offence.main.line_no
      end
      new_message(offence, line) unless line.nil?
    end

    def no_patches?
      !@patches || @patches.count.zero?
    end

    def patch_for(filename)
      @patches.find do |p|
        p.new_file_full_path == Pathname.new(filename)
      end
    end

    def new_message(offence, line)
      path = line.patch.delta.new_file[:path]
      Message.new(path, line, pronto_level(offence.main.level),
                  offence.main.message, nil, self.class)
    end

    def pronto_level(clang_level)
      case clang_level
      when :warning
        :warning
      when :error
        :error
      when :fatal
        :fatal
      else
        :info
      end
    end

    # reads clang-tidy output file and returns an array of offences
    def read_clang_tidy_output
      unless FileTest.file? clang_tidy_output_file
        puts 'WARN: pronto-clang_tidy: clang-tidy output file not found'
        return []
      end
      parse_clang_tidy_output File.read(clang_tidy_output_file)
    end

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

    def clang_tidy_output_file
      ENV['PRONTO_CLANG_TIDY_OUTFILE'] || 'clang-tidy.out'
    end
  end
end
