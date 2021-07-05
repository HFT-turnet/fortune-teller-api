class ValueflowSerializer < ActiveModel::Serializer
  attributes :r

  has_many :tvs
end