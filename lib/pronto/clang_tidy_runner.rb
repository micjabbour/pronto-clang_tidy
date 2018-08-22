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
        build_message_for(offence)
        # Header warnings are repeated for every compilation unit that includes
        # them. Use uniq to ignore repeated messages
      end.flatten.compact.uniq
    end

    private

    def no_patches?
      !@patches || @patches.count.zero?
    end

    # creates a new pronto message for offence
    def build_message_for(offence)
      # find the line for the main diag in the current offence
      main_line = find_line_for_diag(offence.main)
      # if the main diagnostic in the offence points to a changed line
      if main_line
        new_message(main_line, offence.main.level, offence.main_message)
      else
        # try to find a note from the offence that belongs to changed a line
        note_line = find_first_line_for_diags(offence.notes)
        new_message(note_line, offence.main.level, offence.note_message)
      end
    end

    # searches through patches for the diagnostic's line and returns it
    # returns nil if the line was not changed
    def find_line_for_diag(diag)
      file_patch = @patches.find do |patch|
        patch.new_file_full_path == Pathname.new(diag.filename)
      end
      return nil if file_patch.nil?
      file_patch.added_lines.find do |added_line|
        added_line.new_lineno == diag.line_no
      end
    end

    # searches through the diags_array to find a diag that points to a changed
    # line and returns that line
    # returns nil when none of the diags point to a changed line
    def find_first_line_for_diags(diags_array)
      diags_array.map { |diag| find_line_for_diag(diag) }
                 .compact.first
    end

    def new_message(line, offence_level, offence_message)
      return nil if line.nil?
      path = line.patch.delta.new_file[:path]
      Message.new(path, line, pronto_level(offence_level),
                  offence_message, nil, self.class)
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
