class Tabi
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String

  validates :title, length: {maximum: 256, allow_blank: false}

  def path
    "/tabi/#{ id }"
  end
end
