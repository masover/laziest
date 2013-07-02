require 'promise'

module Laziest
  class Counter < Promise
    def initialize enumerator
      @count = 0
      @enumerator = enumerator
      super() do
        begin
          ::Kernel.loop do
            @count += enumerator.next
          end
        rescue ::StopIteration
        end
        @count
      end
    end

    def __force_to__ value
      if @result.equal?(NOT_SET) && @error.equal?(NOT_SET)
        @mutex.synchronize do
          if @result.equal?(NOT_SET) && @error.equal?(NOT_SET)
            begin
              while @count < value
                @count += @enumerator.next
              end
            rescue ::StopIteration
            end
          end
        end
      end
      ::Kernel.raise(@error) unless @error.equal?(NOT_SET)
    end

    %w(== eql? equal? <= > <=>).map(&:to_sym).each do |op|
      define_method op do |value|
        __force_to__ value+1
        @count.public_send op, value
      end
    end

    %w(< >=).map(&:to_sym).each do |op|
      define_method op do |value|
        __force_to__ value
        @count.public_send op, value
      end
    end
  end
end