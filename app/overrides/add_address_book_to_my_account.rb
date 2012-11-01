Deface::Override.new(
  :virtual_path => "spree/users/show",
  :name => "address_book_account_my_orders",
  :insert_top => "[data-hook='account_address_book'], #account_address_book[data-hook]",
  :partial => "spree/users/addresses",
  :disabled => false
)
