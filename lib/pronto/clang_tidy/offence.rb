require_relative 'diagnostic'

module Pronto
  module ClangTidy
    # a class that groups multiple related diagnostics together
    #
    # Clang uses NOTE-level diagnostics to staple more information onto
    # previous diagnostics. The Offence class groups a diagnostic along with
    # all subsequent NOTE-level diagnostics into a single entity.
    class Offence
      attr_reader :main, :notes
      def initialize(main_diagnostic)
        @main = main_diagnostic
        @notes = []
      end

      def <<(note_diagnostic)
        @notes << note_diagnostic
      end

      # the message to be attached to the main diagnostic's line
      def main_message
        result = "#{main.message}\n"
        notes.each do |note|
          result << note.format_diagnostic
        end
        result
      end

      # the message to be attached to any of the notes' lines
      #
      # this is used only when the main diagnostic's line is not changed
      def note_message
        result = main.format_diagnostic
        notes.each do |note|
          result << note.format_diagnostic
        end
        result
      end
    end
  end
end
