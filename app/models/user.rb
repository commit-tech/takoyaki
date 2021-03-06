# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint(8)        not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  username               :string
#  matric_num             :string
#  contact_num            :string
#  cell                   :integer          not null
#  mc                     :boolean          default(FALSE), not null
#  receive_email          :boolean          default(TRUE), not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_username              (username) UNIQUE
#

class User < ApplicationRecord
  CELLS = %i[marketing presidential publicity technical training welfare]
          .freeze

  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :duties, dependent: :nullify
  has_many :timeslots, foreign_key: :default_user_id, inverse_of: :default_user,
                       dependent: :nullify

  has_many :reported_problem_reports, class_name: 'ProblemReport',
                                      foreign_key: 'reporter_user_id',
                                      inverse_of: :reporter_user,
                                      dependent: :nullify
  has_many :last_updated_problem_reports, class_name: 'ProblemReport',
                                          foreign_key: 'last_update_user_id',
                                          inverse_of: :last_update_user,
                                          dependent: :nullify
  has_many :availabilities, dependent: :destroy
  validates :cell, presence: true
  validates :email, presence: true, uniqueness: true
  validates :username, uniqueness: true
  enum cell: CELLS
end
