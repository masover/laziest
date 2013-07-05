module Laziest
  module Extensions
    module LazyEnumerator
      def count
        Laziest::Counter.new self
      end
      def to_a
        Laziest::ArrayPromise.new self 
      end
    end
  end
end