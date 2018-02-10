# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: availabilities
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  day           :integer
#  time_range_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_availabilities_on_time_range_id  (time_range_id)
#  index_availabilities_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (time_range_id => time_ranges.id)
#  fk_rails_...  (user_id => users.id)
#
# rubocop:enable Metrics/LineLength

FactoryBot.define do
  factory :availability do
    user nil
    day 1
    time_range nil
  end
end
