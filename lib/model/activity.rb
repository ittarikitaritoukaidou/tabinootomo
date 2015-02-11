class Activity
  include Mongoid::Document
  include Mongoid::Timestamps

  field :tabi_id, type: BSON::ObjectId

  field :title, type: String

  validates :title, length: {maximum: 256, allow_blank: false}

  def path
    "/tabi/#{ tabi_id }/activity/#{ id }"
  end

  def path
    "/tabi/#{ tabi_id }/activity/#{ id }/edit"
  end

  def tabi
    Tabi.find(tabi_id)
  end
end
