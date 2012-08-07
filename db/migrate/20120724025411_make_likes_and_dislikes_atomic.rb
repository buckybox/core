class MakeLikesAndDislikesAtomic < ActiveRecord::Migration
  class Distributor < ActiveRecord::Base; end
  class Box < ActiveRecord::Base; end
  class Order < ActiveRecord::Base; end
  class Account < ActiveRecord::Base; end
  class Customer < ActiveRecord::Base; end
  class LineItem < ActiveRecord::Base; end

  SPLITTING_REGEX = /\s*,\s*|\s+and\s+|\s+or\s+|\s*;\s*|\s*\.\s*|\s*\/\s*/

  def up
    Distributor.reset_column_information
    Box.reset_column_information
    Order.reset_column_information
    Account.reset_column_information
    Customer.reset_column_information
    LineItem.reset_column_information

    Distributor.all.each do |distributor|
      distributor_id = distributor.read_attribute(:id)
      boxes          = Box.find_all_by_distributor_id(distributor_id)
      box_ids        = boxes.map { |b| b.read_attribute(:id) } if boxes
      orders         = Order.find_all_by_box_id(box_ids) if box_ids

      all_likes     = []
      all_dislikes  = []

      if orders
        #---------- Create the line item list ----------
        orders.each do |order|
          dislikes = order.read_attribute(:dislikes)
          all_dislikes += sanitize_items(dislikes) if dislikes

          likes = order.read_attribute(:likes)
          all_likes += sanitize_items(likes) if likes
        end

        all_items = (all_likes + all_dislikes).uniq
        all_items.each { |name| LineItem.create(distributor_id: distributor_id, name: name) }

        #---------- Create the substitutions and exclusions ----------
        orders.each do |order|
          id                = order.read_attribute(:id)
          account_id        = order.read_attribute(:account_id)
          original_likes    = order.read_attribute(:likes)
          original_dislikes = order.read_attribute(:dislikes)

          order_requests = ''

          if original_dislikes
            dislikes = sanitize_items(original_dislikes)

            unless dislikes.empty?
              order_requests += "\nORDER ID#{id} ORIGINAL DISLIKES:\n" + original_dislikes

              dislikes.each do |name|
                line_item = LineItem.find_by_distributor_id_and_name(distributor_id, name)

                if line_item
                  line_item_id = line_item.read_attribute(:id)
                  Exclusion.create(order_id: id, line_item_id: line_item_id)
                end
              end
            end

            # because we don't need substitutions if there are no exclusions
            if original_likes
              likes = sanitize_items(original_likes)

              unless likes.empty?
                likes.each do |name|
                  line_item = LineItem.find_by_distributor_id_and_name(distributor_id, name)

                  if line_item
                    line_item_id = line_item.read_attribute(:id)
                    Substitution.create(order_id: id, line_item_id: line_item_id)
                  end
                end
              end
            end
          end

          if original_likes
            likes = sanitize_items(original_likes)
            order_requests += "\nORDER ID#{id} ORIGINAL LIKES:\n" + original_likes unless likes.empty?
          end

          account      = Account.find_by_id(account_id)
          customer_id  = account.read_attribute(:customer_id)
          customer     = Customer.find_by_id(customer_id)
          current_text = customer.read_attribute(:special_order_preference) || ''

          customer.update_attribute(:special_order_preference, current_text + order_requests)
        end
      end
    end

    remove_column :orders, :likes
    remove_column :orders, :dislikes
  end

  def down
    add_column :orders, :dislikes, :text
    add_column :orders, :likes, :text

    # Data reversal is not going to happen
  end

  def sanitize_items(items)
    items = items.split(SPLITTING_REGEX)
    items = items.map { |s| remove_common_non_item_words_and_format(s) }
    items = items.reject { |s| s.empty? || s.scan(/\w+/).size > 2 }

    return items
  end

  def remove_common_non_item_words_and_format(string)
    string.downcase!

    string.gsub!(/\s*-\s*/, ' ')
    string.gsub!(/\+/, '')
    string.gsub!(/:\)/, '')
    string.gsub!(/\(|\)/, '')
    string.gsub!(/no\s+/, '')
    string.gsub!(/yes\s+/, '')
    string.gsub!(/less\s+/, '')
    string.gsub!(/more\s+/, '')
    string.gsub!(/never\s+/, '')
    string.gsub!(/2\s?x\s+/, '')
    string.gsub!(/.*\s+fruit.*/, '')
    string.gsub!(/.*\s+vegetables.*/, '')
    string.gsub!(/\s+other\s+/, '')
    string.gsub!(/extra:?/, '')
    string.gsub!(/\s+please/, '')
    string.gsub!(/plus\s+/, '')
    string.gsub!(/loads\sof\s/, '')
    string.gsub!(/a\sfew\s/, '')
    string.gsub!(/\sespecially\syellow/, '')
    string.gsub!(/this/, '')
    string.gsub!(/box\sof\s/, '')
    string.gsub!(/28\s/, '')
    string.gsub!(/fruit/, '')
    string.gsub!(/vegetables/, '')
    string.gsub!(/veggies?/, '')
    string.gsub!(/veggeis/, '')
    string.gsub!(/dark/, '')
    string.gsub!(/max/, '')
    string.gsub!(/\sf1/, '')
    string.gsub!(/\sok/, '')
    string.gsub!(/\r\n?|\r?\n/, '')

    string = string.squeeze(' ').strip.singularize.titleize

    return string
  end
end

