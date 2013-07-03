class Bucky::Sql
  FLUX_PATH = File.join(Rails.root,"db/flux_cap")
  PATH = File.join(Rails.root, "db")

  def self.template(file_name, path=PATH)
      @sql_templates ||= {}
      @sql_templates[file_name] ||= File.read(File.join(path,"/templates/#{file_name}" + ".sql")).gsub(/\s+/, ' ')
      @sql_templates[file_name].clone
  end

  def self.flux_template(file_name)
    template(file_name, FLUX_PATH)
  end

  def self.flux_substitute(template_name, args)
    sql_template = flux_template(template_name)
    args.each do |key, value|
      sql_template.gsub!(':' + key.to_s, value.to_s)
    end
    sql_template
  end

  def self.substitute(template_name, args)
    sql_template = template(template_name)
    args.each do |key, value|
      sql_template.gsub!(':' + key.to_s, value.to_s)
    end
    sql_template
  end

  def self.find_schedules(distributor, date)
    flux_substitute('find_schedules', {
      dow: date.strftime('%a').downcase,
      date: date.to_s(:db),
      distributor_id: distributor.id.to_s
    })
  end

  def self.find_schedules_route(distributor, date, route_id)
    flux_substitute('find_schedules_route', {
      dow: date.strftime('%a').downcase,
      date: date.to_s(:db),
      distributor_id: distributor.id.to_s,
      route_id: route_id
    })
  end

  def self.order_count(distributor, date, route_id=nil)
    if route_id
      select_execute('sum(orders.quantity) as count', find_schedules_route(distributor, date, route_id))[0]['count'].to_i
    else
      select_execute('sum(orders.quantity) as count', find_schedules(distributor, date))[0]['count'].to_i
    end
  end

  def self.transactional_customer_count(distributor)
    execute(substitute('customer_transaction_count', {distributor_id: distributor.id}))[0]["count"].to_i
  end

  def self.order_ids(distributor, date)
    select_execute('orders.id as id', find_schedules(distributor, date)).collect{|row| row['id'].to_i}
  end

  def self.update_next_occurrence_caches(distributor, date=nil)
    date ||= Time.current.to_date
    execute(flux_substitute('update_next_occurrence_caches', {id: distributor.id, date: date.to_s(:db)}))
  end

  def self.select_execute(select_statement, sql)
    sql.gsub!(':select', select_statement)
    execute(sql)
  end

  def self.execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end
end
