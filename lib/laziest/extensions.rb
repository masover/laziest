module Laziest
  module Extensions
    module LazyEnumerator
      def count
        enum = Enumerator.new do |y|
          each do
            y << 1
          end
        end
        Counter.new enum
      end
      def to_a
        ArrayPromise.new self 
      end
      def group_by &block
        Group.new self, &block
      end

      def chunk state=nil
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
              current_result = state.nil? ? (yield value) : (yield value, state)
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
                  result = state.nil? ? (yield value) : (yield value, state)
                  # is this a new value?
                  if result != current_result || result == :_alone
                    current_result = result
                    while current_result.nil? || current_result == :_separator
                      value = ec.next
                      current_result = state.nil? ? (yield value) : (yield value, state)
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
    end
  end
end