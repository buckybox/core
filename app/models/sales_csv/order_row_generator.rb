module SalesCsv
  class SalesCsv::OrderRowGenerator < SalesCsv::RowGenerator
    DOES_NOT_EXIST = nil
    FUTURE_STATUS = 'waiting'

  private

    def order
      @order ||= data
    end

    def package
      DOES_NOT_EXIST
    end

    def delivery
      DOES_NOT_EXIST
    end

    def address
      @address ||= order.address
    end

    def archived
      @archived ||= order
    end

    def box_contents_short_description
      box_name          = archived.box_name
      has_exclusions    = archived.has_exclusions?
      has_substitutions = !archived.has_substitutions?
      Order.short_code(box_name, has_exclusions, has_substitutions)
    end

    def box_type
      archived.box_name
    end

    def box_likes
      archived.substitutions_string
    end

    def box_dislikes
      archived.exclusions_string
    end

    def box_extra_line_items
      Order.extras_description(archived.order_extras)
    end

    def bucky_box_transaction_fee
      archived.consumer_delivery_fee
    end

    def delivery_sequence_number
      DOES_NOT_EXIST
    end

    def package_number
      DOES_NOT_EXIST
    end

    def delivery_date
      DOES_NOT_EXIST
    end

    def package_status
      FUTURE_STATUS
    end

    def delivery_status
      FUTURE_STATUS
    end
  end
end
