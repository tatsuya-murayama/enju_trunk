class Term < ActiveRecord::Base
  validates_presence_of :display_name, :start_at, :end_at
  before_save :set_end_date

  def set_end_date
    self.end_at = self.end_at.end_of_day
  end
end
