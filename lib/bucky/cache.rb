class Bucky::Cache

  def self.hit_cache(k)
    @hit ||= 0
    @hit += 1
  end

  def self.miss_cache(k)
    @miss ||= 0
    @miss += 1
  end

  def self.output_log
    puts "CACHE RATIO: HIT:#{@hit} MISS: #{@miss}"
  end

  def self.fetch(*args)
    k = key(args)
    miss = false
    result = Rails.cache.fetch(k) do
      #puts "CACHE MISS: '#{k}'"
      miss_cache(k)
      miss = true
      yield
    end
    #puts "CACHE HIT: '#{k}'" unless miss
    hit_cache(k) unless miss
    result
  end

  def self.key(arg)
    if arg.is_a?(Array)
      arg.collect{|a| key(a)}.join('/')
    elsif arg.respond_to?(:cache_key)
      arg.cache_key
    elsif arg.is_a?(ActiveRecord)
      "#{arg.id}/#{arg.updated_at}"
    else
      arg.to_s
    end
  end

  def self.delete(*args)
    Rails.cache.delete(key(args))
  end
end
