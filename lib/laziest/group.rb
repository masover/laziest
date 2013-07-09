require 'set'

module Laziest
  class Group < Promise
    def initialize enumerator, &block
      @hash = {}
      @lazy_arrays = {}
      @buffers = ::Hash.new{|h,k|h[k]=[]}
      @enumerator = enumerator
      @group_block = block
      @enum_mutex = ::Mutex.new
      super() do
        # Any existing lazy arrays can simply be forced, since
        # they're on a different mutex now:
        @lazy_arrays.each do |arr|
          arr.__force__
        end
        # And just in case there aren't any lazy arrays:
        begin
          ::Kernel.loop do
            val = enumerator.next
            key = yield val
            (@hash[key] ||= []) << val
          end
        rescue ::StopIteration
        end
        # Strip out anything that turned out to be empty.
        @hash.delete_if {|k,v| v.empty?}
        # clear potentially-expensive GC-able stuff.
        @lazy_arrays = nil
        @buffers = nil
        @group_block = nil
        # safe because we already forced all existing lazy arrays, and we're
        # holding the global mutex which prevents any new ones from being built
        @enum_mutex = nil
        @hash
      end
    end

    def [] key
      return super unless @result.equal?(NOT_SET) && @error.equal?(NOT_SET)
      @mutex.synchronize do
        @enum_mutex.synchronize do
          # for good measure -- for once, we really _don't_ want to do _any_ of
          # this once the hash's promise resolves.
          return super unless @result.equal?(NOT_SET) && @error.equal?(NOT_SET)
          if @lazy_arrays.has_key?(key)
            @lazy_arrays[key]
          else
            # Note: This enumerator is only ever passed to ArrayPromise.
            # It is not actually a valid enumerator, as it entirely lacks
            # support for rewinding.
            enum = ::Enumerator.new do |yielder|
              @enum_mutex.synchronize do
                buffer = @buffers[key]
                ::Kernel.loop do
                  if buffer.empty?
                    # At this point, @enumerator.next may throw StopIteration.
                    # Which will break the loop, which will end our iteration,
                    # which is fine. (A call to our enumerator.each would also
                    # result in a StopIteration.)
                    v = @enumerator.next
                    k = @group_block.call v
                    if k == key
                      # We shouldn't hold the lock when we yield.
                      ::Laziest::MutexUtil.unsynchronize @enum_mutex do
                        yielder << v
                      end
                    elsif @hash.has_key? k
                      # Buffer data for the lazy array to read later
                      if @lazy_arrays.has_key? k
                        @buffers[k] << v
                      else
                        @hash[k] << v
                      end
                    else
                      # We know a lazy array doesn't exist unless the hash exists
                      @hash[k] = [v]
                    end
                  else
                    v = buffer.shift
                    ::Laziest::MutexUtil.unsynchronize @enum_mutex do
                      yielder << v
                    end
                  end
                end
              end
            end
            @hash[key] = [] unless @hash.has_key? key
            @lazy_arrays[key] = ArrayPromise.new enum, @hash[key], true
          end
        end
      end
    end
  end
end