require 'spec_helper'

describe "Address selection during checkout" do
  include_context "store products"
  let(:state) { Spree::State.find_by_name('Arkansas') }

  describe "as guest user" do
    include_context "checkout with product"
    before(:each) do
      click_link "Checkout"
      fill_in "order_email", :with => "guest@example.com"
      click_button "Continue"
    end

    it "should only see billing address form" do
      within("#billing") do
        should_have_address_fields
        page.should_not have_selector(".select_address")
      end
    end

    it "should only see shipping address form" do
      within("#shipping") do
        should_have_address_fields
        page.should_not have_selector(".select_address")
      end
    end
  end

  describe "as authenticated user with saved addresses", :js => true do
    include_context "checkout with product"
    let(:billing) { Factory.build(:address, :state => state) }
    let(:shipping) do
      Factory.build(:address, :address1 => Faker::Address.street_address,
        :state => state)
    end
    let(:user) do
      u = Factory(:user)
      u.addresses << Factory(:address,
        :address1 => Faker::Address.street_address,
        :state => state)
      u.save
      u
    end
    before(:each) { click_link "Checkout"; sign_in!(user); }

    it "should not see billing or shipping address form" do
      find("#billing .inner").should_not be_visible
      find("#shipping .inner").should_not be_visible
    end

    it "should list saved addresses for billing and shipping" do
      within("#billing .select_address") do
        user.addresses.each do |a|
          page.should have_field("order_bill_address_id_#{a.id}")
        end
      end
      within("#shipping .select_address") do
        user.addresses.each do |a|
          page.should have_field("order_ship_address_id_#{a.id}")
        end
      end
    end

    it "should save 2 addresses for user if they are different" do
      expect do
        within("#billing") do
          choose "Other Address"
          fill_in_address(billing)
        end
        within("#shipping") do
          choose "Other Address"
          fill_in_address(shipping, :ship)
        end
        complete_checkout
      end.should change { user.addresses.count }.by(2)
    end

    it "should save 1 address for user if they are the same" do
      expect do
        within("#billing") do
          choose "Other Address"
          fill_in_address(billing)
        end
        within("#shipping") do
          choose "Other Address"
          fill_in_address(billing, :ship)
        end
        complete_checkout
      end.should change { user.addresses.count }.by(1)
    end

    describe "when invalid address is entered", :js => true do
      let(:address) do
        Factory.build(:address, :firstname => nil, :state => state)
      end

      it "should show address form with error" do
        within("#billing") do
          choose "Other Address"
          fill_in_address(address)
        end
        within("#shipping") do
          choose "Other Address"
          fill_in_address(address, :ship)
        end
        click_button "Save and Continue"
        within("#bfirstname") do
          page.should have_content("field is required")
        end
        within("#sfirstname") do
          page.should have_content("field is required")
        end
      end
    end

    describe "entering 2 new addresses", :js => true do
      it "should assign 2 new addresses to order" do
        within("#billing") do
          choose "Other Address"
          fill_in_address(billing)
        end
        within("#shipping") do
          choose "Other Address"
          fill_in_address(shipping, :ship)
        end
        complete_checkout
        page.should have_content("processed successfully")
        within("#order > div.row.steps-data > div:nth-child(2)") do
          page.should have_content("Billing Address")
          page.should have_content(expected_address_format(billing))
        end
        within("#order > div.row.steps-data > div:nth-child(1)") do
          page.should have_content("Shipping Address")
          page.should have_content(expected_address_format(shipping))
        end
      end
    end

    describe "using saved address for bill and new ship address", :js => true do
      let(:shipping) do
        Factory.build(:address, :address1 => Faker::Address.street_address,
          :state => state)
      end

      it "should save 1 new address for user" do
        expect do
          address = user.addresses.first
          choose "order_bill_address_id_#{address.id}"
          within("#shipping") do
            choose "Other Address"
            fill_in_address(shipping, :ship)
          end
          complete_checkout
        end.should change{ user.addresses.count }.by(1)
      end

      it "should assign addresses to orders" do
        address = user.addresses.first
        choose "order_bill_address_id_#{address.id}"
        within("#shipping") do
          choose "Other Address"
          fill_in_address(shipping, :ship)
        end
        complete_checkout
        page.should have_content("processed successfully")
        within("#order > div.row.steps-data > div:nth-child(2)") do
          page.should have_content("Billing Address")
          page.should have_content(expected_address_format(address))
        end
        within("#order > div.row.steps-data > div:nth-child(1)") do
          page.should have_content("Shipping Address")
          page.should have_content(expected_address_format(shipping))
        end
      end

      it "should see form when new shipping address invalid" do
        address = user.addresses.first
        shipping = Factory.build(:address, :address1 => nil, :state => state)
        choose "order_bill_address_id_#{address.id}"
        within("#shipping") do
          choose "Other Address"
          fill_in_address(shipping, :ship)
        end
        click_button "Save and Continue"
        within("#saddress1") do
          page.should have_content("field is required")
        end
        within("#billing") do
          find("#order_bill_address_id_#{address.id}").should be_checked
        end
      end
    end

    describe "using saved address for billing and shipping", :js => true do
      it "should addresses to order" do
        address = user.addresses.first
        choose "order_bill_address_id_#{address.id}"
        check "Use Billing Address"
        complete_checkout
        within("#order > div.row.steps-data > div:nth-child(2)") do
          page.should have_content("Billing Address")
          page.should have_content(expected_address_format(address))
        end
        within("#order > div.row.steps-data > div:nth-child(1)") do
          page.should have_content("Shipping Address")
          page.should have_content(expected_address_format(address))
        end
      end

      it "should not add addresses to user" do
        expect do
          address = user.addresses.first
          choose "order_bill_address_id_#{address.id}"
          check "Use Billing Address"
          complete_checkout
        end.should_not change{ user.addresses.count }
      end
    end

    describe "using saved address for ship and new bill address", :js => true do
      let(:billing) do
        Factory.build(:address, :address1 => Faker::Address.street_address,
          :state => state)
      end

      it "should save 1 new address for user" do
        expect do
          address = user.addresses.first
          choose "order_ship_address_id_#{address.id}"
          within("#billing") do
            choose "Other Address"
            fill_in_address(billing)
          end
          complete_checkout
        end.should change{ user.addresses.count }.by(1)
      end

      it "should assign addresses to orders" do
        address = user.addresses.first
        choose "order_ship_address_id_#{address.id}"
        within("#billing") do
          choose "Other Address"
          fill_in_address(billing)
        end
        complete_checkout
        page.should have_content("processed successfully")
        within("#order > div.row.steps-data > div:nth-child(2)") do
          page.should have_content("Billing Address")
          page.should have_content(expected_address_format(billing))
        end
        within("#order > div.row.steps-data > div:nth-child(1)") do
          page.should have_content("Shipping Address")
          page.should have_content(expected_address_format(address))
        end
      end

      it "should see form when new billing address invalid" do
        address = user.addresses.first
        billing = Factory.build(:address, :address1 => nil, :state => state)
        choose "order_ship_address_id_#{address.id}"
        within("#billing") do
          choose "Other Address"
          fill_in_address(billing)
        end
        click_button "Save and Continue"
        within("#baddress1") do
          page.should have_content("field is required")
        end
        within("#shipping") do
          find("#order_ship_address_id_#{address.id}").should be_checked
        end
      end
    end

    describe "entering address that is already saved", :js => true do
      it "should not save address for user" do
        expect do
          address = user.addresses.first
          choose "order_ship_address_id_#{address.id}"
          within("#billing") do
            choose "Other Address"
            fill_in_address(address)
          end
          complete_checkout
        end.should_not change{ user.addresses.count }
      end
    end
  end
end
