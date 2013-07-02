module LazyCount
  module Extensions
    module LazyEnumerator
      def count
        LazyCount::Counter.new each
      end
    end
  end
end