class Tabi
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :activity_ids, type: Array, default: []

  validates :title, length: {maximum: 256, allow_blank: false}

  def path
    "/tabi/#{ id }"
  end

  def activity_path(activity)
    "/tabi/#{ id }/activities/#{ activity.id }"
  end

  def edit_path
    "/tabi/#{ id }/edit"
  end

  def append_activity_path
    "/tabi/#{ id }/activities"
  end

  def activities
    ids = { }
    Activity.in(_id: activity_ids).each{|a|
      ids[a.id] = a
    }
    activity_ids.map{|id|
      ids[id]
    }.compact
  end

  def append_activity(title)
    a = Activity.new({
        tabi_id: id,
        title: title,
      })
    a.save
    activity_ids << a.id
    save
    a
  end

  def has_activity?(activity)
    activity_ids.include? activity.id
  end

end
