module Cell
  module Caching
    
    def self.enabled=(enabled)
      Cell::Base.send(:include, Cell::Caching) if enabled
      Cell::Base.class_eval do
        alias_method_chain :render_state, :caching
      end
    end

    class NotCacheable < ArgumentError; end

    def render_state_with_caching(state)
      unless perform_caching?(state, params.merge(:state => state)) then return render_state_without_caching(state); end
      begin
        key = cache_key(self.class.name, state, params)
        
        cache = @controller.read_fragment(key)        
        return cache unless cache.blank?
        
        @controller.write_fragment(key, render_state_without_caching(state), self.class.cache_options)
        return @controller.read_fragment(key)
        
      rescue Cell::Caching::NotCacheable        
        Rails.logger.info("Warning: Can't cache: #{state} with params: #{params.inspect}")
        return render_state_without_caching(state)
      end
    end

    private
    
    def perform_caching?(state, params={})
      return false        if perform_caching_for_state?(:none, params)
      return false    unless perform_caching_for_state?(state, params) || perform_caching_for_state?(:all, params)
      @controller.perform_caching
    end
    
    def perform_caching_for_state?(state, params)
      should_cache = self.class.cache_states && self.class.cache_states[state]
      should_cache.is_a?(Proc) ? should_cache.call(params) : should_cache
    end

    # The params can be numbers, strings, symbols, or arrays of active records
    def cache_key(cell, state, params)
      "#{cell}|#{state}|"+Base64.encode64(MD5.new(recursive_key(params)).to_s).strip
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