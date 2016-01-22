class KeyValue < ActiveRecord::Base
  self.table_name = 'key_value'
  self.primary_key = 'key'
end
