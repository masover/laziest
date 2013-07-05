require 'promise'

module Laziest
  class ArrayPromise < Promise
    # Allow a partially-evaluated enumerator/array to initialize.
    def initialize enumerator, array=[]
      @array = array
      @enumerator = enumerator
      super() do
        ::Kernel.loop do
          @array << @enumerator.next
        end
        @array
      end
    end

    def each(&block)
      return super unless @result.equal?(NOT_SET) && @error.equal?(NOT_SET)
      return ::Enumerator.new{|y| each {|x| y << x}}.lazy unless ::Kernel.block_given?
      index = 0
      ::Kernel.loop do
        __force_to__ index
        break unless @array.length > index
        yield @array[index]
        index += 1
      end
    end

    # Array-related laziness
    def [] index, length=nil
      if length.nil?
        if index.kind_of? ::Range
          enum = ::Enumerator.new do |y|
            index.each do |i|
              y << self[i]
            end
          end
          ArrayPromise.new enum
        else
          __force_to__ index
          @array[index]
        end
      else
        enum = ::Enumerator.new do |y|
          i = index
          length.times do
            self[i]
            i += 1
          end
        end
        ArrayPromise.new enum
      end
    end

    def __force_to__ index
      begin
        @mutex.synchronize do
          while @array.length <= index
            @array << @enumerator.next
          end
        end
      rescue StopIteration
      end
    end

    # Force all enumerable methods to be defined in terms of laziness.
    %w(
      all? any? chunk collect collect_concat count cycle detect drop
      drop_while each_cons each_entry each_slice each_with_index
      each_with_object entries find find_all find_index first flat_map grep
      group_by include? inject lazy map max max_by member? min min_by minmax
      minmax_by none? one? partition reduce reject reverse_each select
      slice_before sort sort_by take take_while zip
    ).map(&:to_sym).each do |name|
      define_method name do |*args, &block|
        each.lazy.public_send name, *args, &block
      end
    end

    # Except this one, make it a no-op. (Also should prevent infinite recursion.)
    def to_a
      self
    end
  end
end