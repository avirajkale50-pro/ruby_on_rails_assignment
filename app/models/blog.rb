class Blog < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  
  validates :user, presence: true

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }

  validates :title, presence: true, length: { minimum: 5 }
  validates :body, presence: true
end
