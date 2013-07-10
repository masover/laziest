module Laziest
  module Extensions
    module LazyEnumerator
      def count
        enum = Enumerator.new do |y|
          each do |value|
            if (!block_given?) || (yield value)
              y << 1
            end
          end
        end
        Counter.new enum
      end

      def entries
        ArrayPromise.new enum_for :each
      end
      alias_method :to_a, :entries

      def group_by &block
        return enum_for :group_by unless block_given?
        Group.new enum_for(:each), &block
      end

      %w(min max).map(&:to_sym).each do |name|
        klass = MinMax.const_get name.capitalize
        define_method name do
          if block_given?
            # can't handle unnatural ordering
            super
          else
            klass.new enum_for(&:each)
          end
        end
      end

      # Perfectly functional.
      # TODO: Optimize by sharing an enumerator. As it stands,
      # in the worst case, we enumerate everything twice, defeating the
      # entire point of having a separate 'minmax' method.
      def minmax
        if block_given?
          super
        else
          [min, max]
        end
      end

      # Another functional-but-stub.
      # TODO: Optimize away the hash, maybe?
      def partition
        return enum_for :partition unless block_given?
        # Negate, forcing these to actual true/false values
        groups = group_by{|*args| ! yield *args}
        # No need to double-negate, the following is just inverted.
        [groups[false], groups[true]]
      end

      # Chunk on lazy is actually good enough already for most uses.
      # Generally, you're chunking a huge stream into small, manageable chunks.
      # But in that case, you also don't necessarily nead laziness, as chunk
      # already streams in a standard Enumerable.
      # The use case here is if any particular chunk is _very_ large, and
      # maybe infinite, but we actually don't need the entire chunk, and
      # will actually break our iteration there.
      def chunk state=nil
        unless state.nil?
          return chunk {|value| yield value, state}
        end
        Enumerator.new do |yield_array|
          # Should give us a new, rewound copy.
          # ec = enum copy
          ec = enum_for(:each)
          array = nil
          current_result = nil
          lazy_array = nil

          # first iteration, to set things up.
          begin
            value = nil
            while current_result.nil? || current_result == :_separator
              value = ec.next
              current_result = yield value
            end
            array = [value]
          rescue StopIteration
            array = nil
          end

          loop do
            break if array.nil? # either we're empty at start or we're done.

            # An enumerator that returns all following values of this array.
            array_promise_enum = Enumerator.new do |yield_element|
              loop do
                value = nil
                begin
                  value = ec.next
                  result = yield value
                  # is this a new value?
                  if result != current_result || result == :_alone
                    current_result = result
                    while current_result.nil? || current_result == :_separator
                      value = ec.next
                      current_result = yield value
                    end
                    array = [value]
                    break
                  end
                rescue StopIteration
                  # We're done. Clean up.
                  array = nil
                  current_result = nil
                  lazy_array = nil
                  break
                end
                yield_element << value
              end
            end

            # nil_on_empty is false, because we will _always_ have elements.
            lazy_array = ArrayPromise.new array_promise_enum, array

            yield_array << [current_result, lazy_array]

            # Now we have control back. Before we loop again, finish the previous array.
            lazy_array.__force__
          end
        end
      end

      # Like above, but should be much simpler.
      def slice_before state=nil
        unless block_given?
          # state is a pattern
          return slice_before {|value| state === value}
        end

        unless state.nil?
          # state is state, handle it here
          return slice_before {|value| yield value, state}
        end

        Enumerator.new do |yield_array|
          ec = enum_for(:each)
          array = nil
          lazy_array = nil

          begin
            array = [ec.next]
          rescue StopIteration
            array = nil
          end

          loop do
            break if array.nil?

            array_promise_enum = Enumerator.new do |yield_element|
              loop do
                value = nil
                begin
                  value = ec.next
                  if yield value
                    array = [value]
                    break
                  end
                rescue StopIteration
                  array = nil
                  lazy_array = nil
                  break
                end
                yield_element << value
              end
            end

            lazy_array = ArrayPromise.new array_promise_enum, array

            yield_array << lazy_array

            lazy_array.__force__
          end
        end
      end
    end
  end
end