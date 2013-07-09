module Laziest
  module Extensions
    module LazyEnumerator
      def count
        enum = Enumerator.new do |y|
          each do
            y << 1
          end
        end
        Laziest::Counter.new enum
      end
      def to_a
        Laziest::ArrayPromise.new self 
      end
      def group_by &block
        Laziest::Group.new self, &block
      end
    end
  end
end