class Bucky::Sql
  def self.template(file_name)
      @sql_templates ||= {}
      @sql_templates[file_name] ||= File.read(File.join(Rails.root,"db/templates/#{file_name}"))
      @sql_templates[file_name].clone
  end

  def self.substitute(template_name, args)
    sql_template = template(template_name)
    args.each do |key, value|
      sql_template.gsub!(':' + key.to_s, value.to_s)
    end
    sql_template
  end

  def self.find_schedules(distributor, date)
    sql = substitute('find_schedules.sql', {
      dow: date.strftime('%a').downcase,
      date: date.to_s(:db),
      distributor_id: distributor.id.to_s
    })
  end

  def self.find_schedules_route(distributor, date, route_id)
    sql = substitute('find_schedules_route.sql', {
      dow: date.strftime('%a').downcase,
      date: date.to_s(:db),
      distributor_id: distributor.id.to_s,
      route_id: route_id
    })
  end

  def self.order_count(distributor, date, route_id=nil)
    if route_id
      execute('sum(orders.quantity) as count', find_schedules_route(distributor, date, route_id))[0]['count'].to_i
    else
      execute('sum(orders.quantity) as count', find_schedules(distributor, date))[0]['count'].to_i
    end
  end

  def self.order_ids(distributor, date)
    execute('orders.id as id', find_schedules(distributor, date)).collect{|row| row['id'].to_i}
  end

  def self.execute(select_statement, sql)
    sql.gsub!(':select', select_statement)
    ActiveRecord::Base.connection.execute(sql)
  end
end
