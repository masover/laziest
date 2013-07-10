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

      # Implemented mainly in terms of slice_before.
      # It's logically very similar, but has similar amounts of extra sugar.
      def chunk state=nil
        # Handle state, so we can forget about it.
        unless state.nil?
          return chunk {|value| yield value, state}
        end

        # Even though we could probably do everything with the lazy enum
        # chaining -- and we do _almost_ everything that way -- we want
        # to ensure that first_iteration is reset with each run. A brand
        # new enumerator ensures #rewind and friends work correctly.

        enum = Enumerator.new do |yield_array|
          prev = nil
          first_iteration = true

          map {|value|
            [value, (yield value)]
          }.slice_before {|value, result|
            if first_iteration
              first_iteration = false
              # return value doesn't matter
            else
              # start a new group when this one differs from prev, or is
              # specifically requested as 'alone'.
              result != prev || result == :_alone
            end
            prev = result
          }.each do |value, result|
            yield result unless value.nil? || value == :_separator
          end
        end

        enum.lazy
      end

      # Chunk without laziness is actually good enough already for most uses.
      # Generally, you're chunking a huge stream into small, manageable chunks.
      # The standard enumerable will stream well enough there -- each chunk
      # must be evaluated completely, but the entire stream is evaluated
      # only as needed. The use case here is if any particular chunk is _very_
      # large, and maybe infinite, but we actually don't need the entire chunk.
      def slice_before state=nil
        unless block_given?
          # state is a pattern
          return slice_before {|value| state === value}
        end

        unless state.nil?
          # state is state, handle it here
          return slice_before {|value| yield value, state}
        end

        enum = Enumerator.new do |yield_array|
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

        enum.lazy
      end
    end
  end
end