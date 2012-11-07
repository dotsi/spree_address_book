class Spree::AddressesController < Spree::BaseController
  rescue_from ActiveRecord::RecordNotFound, :with => :render_404
  load_and_authorize_resource
  def edit
    session["user_return_to"] = request.env['HTTP_REFERER']
  end

  def update
    if @address.editable?
      if @address.update_attributes(params[:address])
        flash[:notice] = t(:successfully_updated, :resource => t(:address))
      end
    else
      new_address = @address.clone
      new_address.attributes = params[:address]
      @address.update_attribute(:deleted_at, Time.now)
      if new_address.save
        flash[:notice] = t(:successfully_updated, :resource =>t(:address))
      end
    end
    
    redirect_back_or_default(account_path + "#addressbook")
    
  end

  def destroy
    @address.destroy
    flash[:notice] = t(:successfully_removed, :resource => t(:address))
    redirect_to(account_path + "#addressbook")
    #redirect_to(request.env['HTTP_REFERER'] || account_path + "#addressbook") unless request.xhr?
  end

  def create
    @address = Spree::Address.new(params[:address])
    if @address.save
      @address.update_attribute(:user_id, current_user.try(:id))
      flash[:notice] = t(:successfully_created, :resource => t(:address))
      redirect_to(account_path + "#addressbook")
    else 
      flash[:error] = t('error.messages.not_saved.one', :resource => t(:address))
      redirect_back_or_default(account_path + "#addressbook")
    end
  end
  
end
