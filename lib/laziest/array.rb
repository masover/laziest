module Laziest
  # This class is a lazily-evaluated array based on an enumerator.
  # A contract: The enumerator is guaranteed to never be rewound.
  class ArrayPromise < Promise
    # Accepts 'array' to allow a partially-evaluated enumerator/array to initialize.
    def initialize enumerator, array=[], nil_on_empty = false
      @array = array
      @enumerator = enumerator
      @nil_on_empty = nil_on_empty
      super() do
        begin
          ::Kernel.loop do
            @array << @enumerator.next
          end
        rescue ::StopIteration
        end
        @enumerator = nil
        # Needed for use in hashes, like group_by
        (nil_on_empty && @array.empty?) ? nil : @array
      end
    end

    def each(&block)
      return super if __forced__?
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
      return super if __forced__?
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
            y << self[i]
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
      rescue ::StopIteration
      end
    end

    def __forced__?
      if @nil_on_empty && @array.empty?
        # Check if we're really empty.
        __force_to__ 1
        # Either we'll be empty (and finalized as nil), so we'll revert to
        # calling super which forwards to nil and so on,
        # or we'll be nonempty (and normal logic proceeds)
      end
      !(@result.equal?(NOT_SET) && @error.equal?(NOT_SET))
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
        return super if __forced__?
        each.lazy.public_send name, *args, &block
      end
    end

    # Except this one, make it a no-op. (Also should prevent infinite recursion.)
    def to_a
      return super if __forced__?
      self
    end
  end
end