Spree::Address.class_eval do
  belongs_to :user

  def self.required_fields
    validator = Spree::Address.validators.find{|v| v.kind_of?(ActiveModel::Validations::PresenceValidator)}
    validator ? validator.attributes : []
  end
  
  # added by matmon
  # # override same as to ignore new user_id.  workaround for spec
  # # failure for bad controller filter.
  # # i don't like overriding same_as? to make controller filter work.
  # # refactor this.
  # def same_as?(other)
  #   return false if other.nil?
  #   attributes.except('id', 'updated_at', 'created_at', 'user_id') ==  other.attributes.except('id', 'updated_at', 'created_at', 'user_id')
  # end

  # can modify an address if it's not been used in an order
  def editable?
    new_record? || (shipments.empty? && (Spree::Order.where("bill_address_id = ?", self.id).count + Spree::Order.where("bill_address_id = ?", self.id).count <= 1) && Spree::Order.complete.where("bill_address_id = ? OR ship_address_id = ?", self.id, self.id).count == 0)
  end

  def can_be_deleted?
    shipments.empty? && Spree::Order.where("bill_address_id = ? OR ship_address_id = ?", self.id, self.id).count == 0
  end

  def to_s
    "#{firstname} #{lastname}<br/>#{address1} #{address2}<br/>#{city}, #{state || state_name} #{zipcode}<br/>#{country}".html_safe
  end

  def destroy_with_saving_used
    if can_be_deleted?
      destroy_without_saving_used
    else
      update_attribute(:deleted_at, Time.now)
    end
  end
  alias_method_chain :destroy, :saving_used

end
