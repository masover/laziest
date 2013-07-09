module Laziest
  module MutexUtil
    # opposite of Mutex#synchronize.
    def self.unsynchronize mutex
      mutex.unlock
      begin
        yield
      ensure
        mutex.lock
      end
    end
  end
end