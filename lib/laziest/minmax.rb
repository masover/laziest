module Laziest
  # Base class. Conceptually a max, but we can override it
  # with min/max classes... but only for naturally-ordered elements!
  # If we allow arbitrary comparators, we have no way of optimizing
  # attempted comparisons against the max value itself.
  class MinMax < Promise
    def initialize enumerator, gtop
      @enumerator = enumerator
      # "Greater-Than" operation
      @gtop = gtop
      begin
        @max = @enumerator.next
      rescue ::StopIteration
        @is_nil = true
      end

      super() do
        ::Kernel.loop do
          value = @enumerator.next
          if value.public_send @gtop, @max
            @max = value
          end
        end
        @max
      end
    end

    def __force_until__
      if @result.equal?(NOT_SET) && @error.equal?(NOT_SET)
        @mutex.synchronize do
          if @result.equal?(NOT_SET) && @error.equal?(NOT_SET) 
            unless yield
              ::Kernel.loop do
                # StopIteration can stop the loop here
                value = @enumerator.next
                if value.public_send @gtop, @max
                  @max = value
                  break if yield
                end
              end
            end
          end
        end
      end
      ::Kernel.raise(@error) unless @error.equal?(NOT_SET)
    end

    %w(== eql? equal?).map(&:to_sym).each do |name|
      define_method name do |value|
        # If it's _equal_ to our value, it can't be _greater_ than our value.
        # So this can lazily return _false_ if the max is _greater_ than
        # our value. Otherwise, we have to evaluate the whole sequence.
        __force_until__ { @max.public_send @gtop, value }
        @max.public_send name, value
      end
    end

    # The individual Min and Max classes provide additional optimizations for
    # naturally-ordered elements.
    class Max < MinMax
      def initialize enumerator
        super(enumerator, :>)
      end

      %w(< >=).map(&:to_sym).each do |name|
        define_method name do |value|
          # If we find a max at least as large as value, then < is false,
          # and >= is true. (Otherwise, we must enumerate everything.)
          __force_until__ { @max >= value }
          @max.public_send name, value
        end
      end

      %w(<= <=> >).map(&:to_sym).each do |name|
        define_method name do |value|
          # If we find a max _larger_ than a value, then <= is false,
          # > is true, and <=> can be evaluated directly.
          __force_until__ { @max > value }
          @max.public_send name, value
        end
      end
    end

    # Inverse of above.
    class Min < MinMax
      def initialize enumerator
        super(enumerator, :<)
      end

      %w(> <=).map(&:to_sym).each do |name|
        define_method name do |value|
          __force_until__ { @max <= value }
          @max.public_send name, value
        end
      end

      %w(>= <=> <).map(&:to_sym).each do |name|
        define_method name do |value|
          __force_until__ { @max < value }
          @max.public_send name, value
        end
      end
    end
  end
end