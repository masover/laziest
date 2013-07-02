module Laziest
  module Extensions
    module LazyEnumerator
      def count
        Laziest::Counter.new each
      end
    end
  end
end