module LazyCount
  module Extensions
    module LazyEnumerable
      def count
        enum = each
        lenum = lazy_enum do
          enum.next
          1
        end
        LazyCount::Counter.new Enumerator::Lazy.new
      end
    end
  end
end