class PsRespScope < ActiveRecord::Base
  establish_connection :peoplesoft
  set_table_name "SYSADM.PSXLATITEM"
  
  def self.translate_resp_scope(ps_scope)
    @@scopes ||= init_positions
    result = @@scopes[ps_scope]
    result ||= ps_scope
    result
  end
  
  def self.init_positions
    @@scopes = {}
    scopes = PsRespScope.select("fieldvalue, xlatlongname").where("fieldname = 'RESPONS_SCOPE'")
    scopes.each do |scope|
      @@scopes[scope.fieldvalue] = scope.xlatlongname
    end
    @@scopes
  end
end