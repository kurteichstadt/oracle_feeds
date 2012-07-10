class PsTaxLocation < ActiveRecord::Base
  establish_connection :peoplesoft
  set_table_name "SYSADM.PS_TAX_LOCATION1"
  set_primary_key "tax_location_cd"
end