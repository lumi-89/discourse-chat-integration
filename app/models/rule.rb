class DiscourseChat::Rule < DiscourseChat::PluginModel
  KEY_PREFIX = 'rule:'

  # Setup ActiveRecord::Store to use the JSON field to read/write these values
  store :value, accessors: [ :channel_id, :category_id, :tags, :filter, :error_key ], coder: JSON

  after_initialize :init_filter

  def init_filter
    self.filter  ||= 'watch'
  end

  validates :filter, :inclusion => { :in => %w(watch follow mute),
    :message => "%{value} is not a valid filter" }

  validate :channel_valid?, :category_valid?, :tags_valid?

  def channel_valid?
    # Validate category
    if not (DiscourseChat::Channel.where(id: channel_id).exists?)
      errors.add(:channel_id, "#{channel_id} is not a valid channel id")
    end
  end

  def category_valid?
    # Validate category
    if not (category_id.nil? or Category.where(id: category_id).exists?)
      errors.add(:category_id, "#{category_id} is not a valid category id")
    end
  end

  def tags_valid?
    # Validate tags
    return if tags.nil?
    tags.each do |tag|
      if not Tag.where(name: tag).exists?
        errors.add(:tags, "#{tag} is not a valid tag")
      end
    end
  end

  # We never want an empty array, set it to nil instead
  def tags=(array)
    if array.nil? or array.empty?
      super(nil)
    else
      super(array)
    end
  end

  # Don't want this to end up as anything other than an integer
  def category_id=(val)
    if val.nil? or val.blank?
      super(nil)
    else
      super(val.to_i)
    end
  end

  # Mock foreign key
  # Could raise RecordNotFound
  def channel
    DiscourseChat::Channel.find(channel_id)
  end
  def channel=(val)
    self.channel_id = val.id
  end

  scope :with_channel, ->(channel) { with_channel_id(channel.id) } 
  scope :with_channel_id, ->(channel_id) { where("value::json->>'channel_id'=?", channel_id.to_s)} 

  scope :with_category_id, ->(category_id) { category_id.nil? ? where("(value::json->'category_id') IS NULL OR json_typeof(value::json->'category_id')='null'") : where("value::json->>'category_id'=?", category_id.to_s)}

end