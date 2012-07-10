class PsDeptTbl < ActiveRecord::Base
  establish_connection :peoplesoft
  set_table_name "SYSADM.PS_DEPT_TBL"
  
  def self.translate_ministry(ps_ministry)
    @@ministries ||= init_ministries
    result = @@ministries[ps_ministry]
    result ||= ps_ministry
    result
  end
  
  def self.init_ministries
    @@ministries = {}
    ministries = PsDeptTbl.select("deptid, descr").joins("INNER JOIN SYSADM.PS_CCC_MINISTRIES ON SYSADM.PS_CCC_MINISTRIES.CCC_MINISTRY = SYSADM.PS_DEPT_TBL.DEPTID")
    ministries.each do |ministry|
      @@ministries[ministry.deptid] = ministry.descr
    end
    @@ministries["CM"] = "Campus Ministry" # Override what's in PS - "The Campus Ministry"
    @@ministries
  end
end
