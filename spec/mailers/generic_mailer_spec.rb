# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenericMailer, type: :mailer do
  describe '#drop_duty' do
    let(:mail) do
      user = create(:user)
      timeslot = create(:timeslot)
      @duty = create(:duty, user: user, timeslot: timeslot)
      GenericMailer.drop_duty(@duty, User.pluck(:id))
    end

    it 'renders the header' do
      expect(mail.subject).to eq(
        'DUTY DUTY DUTY ' \
        "#{@duty.time_range.start_time.strftime('%H%M')}-" \
        "#{@duty.time_range.end_time.strftime('%H%M')} on " \
        "#{@duty.date.strftime('%a, %d %b %Y')} at " \
        "#{@duty.place.name}"
      )
      expect(mail.to).to eq(User.pluck(:email))
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('grab')
    end
  end

  describe '#drop_duties' do
    let(:mail) do
      user = create(:user)
      @duties = create_list(:duty, 5, user: user)
      GenericMailer.drop_duties(@duties, User.pluck(:id))
    end

    it 'renders the header' do
      expect(mail.subject).to eq(
        'DUTY DUTY DUTY ' \
        "#{@duties.first.time_range.start_time.strftime('%H%M')}-" \
        "#{@duties.last.time_range.end_time.strftime('%H%M')} on " \
        "#{@duties.first.date.strftime('%a, %d %b %Y')} at " \
        "#{@duties.first.place.name}"
      )
      expect(mail.to).to eq(User.pluck(:email))
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('grab')
    end
  end

  describe '#problem_report' do
    let(:mail) do
      @user = create(:user, cell: 'technical')
      @problem = create(:problem_report, reporter_user: @user)
      GenericMailer.problem_report(@problem)
    end
    it 'renders the header' do
      expect(mail.subject).to eq('New computer problem')
      expect(mail.to).to eq(User.where(cell: 'technical').pluck(:email))
    end
    it 'renders the body' do
      expect(mail.body.encoded).to match('problem')
    end
  end
end
