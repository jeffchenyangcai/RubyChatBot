class User < ApplicationRecord
  has_many :conversations, dependent: :destroy  # 每个用户可以有多个会话
  has_secure_password
  validates :username, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }
end