class Family < ActiveRecord::Base
  has_many :users, :through => :family_users
  has_many :family_users

  def add_user(user_ids)
    # TODO :need refactoring
    logger.info "aaa"
    user_ids.delete_if{|u| u.blank?} if user_ids
    if user_ids.nil? || user_ids.empty? 
      logger.debug "family users no record"
      errors.add(:base, I18n.t('family.no_select_users'))
      raise 
    end

    #
    user_ids.each do |user_id|
      self.users << User.find(user_id) rescue nil
    end
  end
end
