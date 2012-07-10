class PsCccPersData < ActiveRecord::Base
  establish_connection :peoplesoft
  set_table_name "SYSADM.PS_CCC_PERS_DATA"
end