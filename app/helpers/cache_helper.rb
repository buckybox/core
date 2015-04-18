module CacheHelper
  raise "Rails 4?!" if Rails::VERSION::MAJOR > 3

  def cache_if(condition, name = {}, options = nil, &block)
    if condition
      cache(name, options, &block)
    else
      yield
    end

    nil
  end
end
