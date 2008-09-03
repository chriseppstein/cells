module Cell
  module Caching
    def self.enabled=(enabled)
      Cell::Base.send(:include, Cell::Caching) if enabled
    end
    
    class NotCacheable < ArgumentException; end
    
    def perform_caching?(state, params={})
      should_cache = self.class.cache_states[state]
      should_cache = should_cache.call(params) if should_cache.is_a? Proc
      return false unless should_cache
      @controller.perform_caching
    end
    
    def render_state_with_caching(state, params={})
      unless perform_caching?(state, params) then return render_state_without_caching(state); end
      begin
         key = cache_key(widget, params)
         cache = @controller.read_fragment(key)
         return cache unless cache.blank?
         @controller.write_fragment(key, render_state_without_caching(state))
       rescue Cell::Caching::NotCacheable
         logger.info("Warning: Can't cache: #{state} with params: #{params.inspect}")
         return render_state_without_caching(state)
       end
    end
    
    alias_method_chain :render_state, :caching
    
    private
    
    # The params can be numbers, strings, symbols, or arrays of active records
    def cache_key(cell, state, params)
      Base64.encode64(MD5.new("#{cell}|#{state}|#{recursive_key(params)}").to_s).strip
    end
    
    def recursive_key(hash_or_array)
      hash_or_array = hash_or_array.safe_sort if hash_or_array.is_a? Hash
      hash_or_array.inject([]) do |mem, var|
        mem << if var.respond_to? :to_cache_key
          var.to_cache_key
        else
          case var
            when String, Symbol, Fixnum, Class, NilClass, TrueClass, FalseClass
              var.to_s
            when Hash, Array, Set
              recursive_key(var)
            when Proc
              # XXX I'm not sure this is right. But it's safe for now...
              begin
                recursive_key(var.call)
              rescue
                ""
              end
            else
              if var.respond_to?(:inject)
                recursive_key(var)
              else
                raise Cell::Caching::NotCacheable.new("Uncacheable parameter #{var.class} #{var}")
              end
          end
        end
        mem
      end.join(";")
    end
  end
end