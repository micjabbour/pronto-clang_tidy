require_relative 'clang_tidy/version'
require 'pronto'

module Pronto
  class ClangTidyRunner < Runner
    def run
      offences = read_clang_tidy_output
      return [] if no_patches? || offences.length.zero?
      # loop through all offences in clang-tidy output
      offences.map do |offence|
        # find the patch that corresponds to the current offence
        patch = patch_for(offence.file)
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
        added_line.new_lineno == offence.lineno
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
      Message.new(path, line, :warning, offence.msg, nil, self.class)
    end

    # reads clang-tidy output file and returns an array of offences
    def read_clang_tidy_output
      unless FileTest.file? clang_tidy_output_file
        puts 'WARN: pronto-clang_tidy: clang-tidy output file not found'
        return []
      end
      clang_tidy_output = File.read clang_tidy_output_file
      clang_tidy_output.each_line.select { |line| line_is_offence? line }
                       .map do |offence|
        properties = offence.split(':').map(&:strip)
        OpenStruct.new(file: properties[0], lineno: properties[1].to_i,
                       level: properties[3], msg: properties[4])
      end
    end

    def line_is_offence?(line)
      line.start_with?('/') && /:\d+:\d+:/.match(line) && /\[\S+\]/.match(line)
    end

    def clang_tidy_output_file
      ENV['PRONTO_CLANG_TIDY_OUTFILE'] || 'clang-tidy.out'
    end
  end
end
