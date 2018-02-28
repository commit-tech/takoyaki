# frozen_string_literal: true
# == Schema Information
#
# Table name: timeslots
#
#  id            :integer          not null, primary key
#  mc_only       :boolean
#  day           :date
#  user_id       :integer
#  time_range_id :integer
#  place_id      :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_timeslots_on_place_id       (place_id)
#  index_timeslots_on_time_range_id  (time_range_id)
#  index_timeslots_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (place_id => places.id)
#  fk_rails_...  (time_range_id => time_ranges.id)
#  fk_rails_...  (user_id => users.id)
#

FactoryBot.define do
  factory :timeslot do
    mc_only false
    day '2018-01-31'
    user nil
    time_range nil
    place nil
  end
end
