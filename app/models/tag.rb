class Tag < ActiveRecord::Base
  has_many :taggings, :dependent => :destroy, :class_name => 'ActsAsTaggableOn::Tagging'
  after_save :save_taggings
  after_destroy :save_taggings

  has_friendly_id :name

  searchable do
    text :name
    string :name
    time :created_at
    time :updated_at
    integer :bookmark_ids, :multiple => true do
      tagged(Bookmark).collect(&:id)
    end
    integer :taggings_count do
      taggings.size
    end
  end

  paginates_per 10

  def self.bookmarked(bookmark_ids, options = {})
    count = Tag.count
    count = Tag.default_per_page if count == 0
    unless bookmark_ids.empty?
      search = Tag.search do
        with(:bookmark_ids).any_of bookmark_ids
        order_by :taggings_count, :desc
        paginate(:page => 1, :per_page => count)
      end
      Tag.where(:id => search.execute.raw_results.collect(&:primary_key))
    end
  end

  def save_taggings
    self.taggings.collect(&:taggable).each do |t| t.save end
  end

  def tagged(taggable_type)
    self.taggings.where(:taggable_type => taggable_type.to_s).includes(:taggable).collect(&:taggable)
  end
end
