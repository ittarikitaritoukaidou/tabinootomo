class Activity
  include Mongoid::Document
  include Mongoid::Timestamps

  field :tabi_id, type: BSON::ObjectId

  field :title, type: String

  validates :title, length: {maximum: 256, allow_blank: false}

  def path
    "/tabi/#{ tabi_id }/activities/#{ id }"
  end

  def edit_path
    "/tabi/#{ tabi_id }/activities/#{ id }/edit"
  end

  def delete_path
    "/tabi/#{ tabi_id }/activities/#{ id }/delete"
  end

  def has_any_detail?
    false
  end

  def tabi
    Tabi.find(tabi_id)
  end
end
