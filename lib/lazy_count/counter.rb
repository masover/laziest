require 'promise'

module LazyCount
  class Counter < Promise
    def initialize enumerator
      @count = 0
      @enumerator = enumerator
      super do
        @mutex.synchronize do
          begin
            loop do
              @count += enumerator.next
            end
          rescue StopIteration
          end
        end
      end
    end

    def __force_to__ value
      @mutex.synchronize do
        begin
          while @count < value
            @count += enumerator.next
          end
        rescue StopIteration
        end
      end
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