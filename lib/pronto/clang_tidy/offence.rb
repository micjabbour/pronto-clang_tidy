require_relative 'diagnostic'

# TODO: design class interface

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
    end
  end
end
