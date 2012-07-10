class PsCccStatusTbl < ActiveRecord::Base
  establish_connection :peoplesoft
  set_table_name "SYSADM.PS_CCC_STATUS_TBL"
  
  def self.translate_status(ps_status)
    @@statuses ||= init_statuses
    result = @@statuses[ps_status]
    result ||= ps_status
    result
  end
  
  def self.init_statuses
    @@statuses = {}
    statuses = PsCccStatusTbl.select("status_code, descr")
    statuses.each do |status|
      @@statuses[status.status_code] = status.descr
    end
    @@statuses
  end
end