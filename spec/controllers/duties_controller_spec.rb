# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DutiesController, type: :controller do
  describe 'GET #index' do
    before do
      sign_in create(:user)
      create_list(:time_range, 10)
      create(:timeslot)
      Duty.generate(Time.zone.today.beginning_of_week, Time.zone.today + 7)
      get :index
    end

    it { should respond_with :ok }
  end

  describe 'POST duties#generate_duties' do
    before do
      sign_in create(:user)
      create_list(:time_range, 10)
      @timeslot = create(:timeslot, day: 'Tuesday')
    end

    it 'should generate duties without start time given' do
      post :generate_duties, params: { num_weeks: 2 }
      first_date = Time.zone.today.beginning_of_week + 1.day

      expect(Duty.count).to be(2)
      expect(Duty.where(timeslot: @timeslot).count).to be(2)
      expect(Duty.order(:date).first.date).to eq(first_date)
      expect(Duty.order(:date).second.date).to eq(first_date + 1.week)

      should redirect_to duties_path(
        start_date: Time.zone.today.beginning_of_week
      )
      expect(flash[:notice]).to be('Duties successfully generated!')
    end

    it 'should generate duties with start time given' do
      start_date = Time.zone.today.beginning_of_week + 1.week
      first_date = start_date + 1.day

      post :generate_duties, params: { num_weeks: 2, start_date: start_date }

      expect(Duty.count).to be(2)
      expect(Duty.where(timeslot: @timeslot).count).to be(2)
      expect(Duty.order(:date).first.date).to eq(first_date)
      expect(Duty.order(:date).second.date).to eq(first_date + 1.week)

      should redirect_to duties_path(start_date: start_date)
      expect(flash[:notice]).to be('Duties successfully generated!')
    end
  end

  describe 'POST duties#grab' do
    before do
      sign_in create(:user)
    end

    it 'grab a duty' do
      duty = create(:duty, free: true)
      expect do
        patch :grab, params: { duty_id: { duty.id => duty.id } }
        duty.reload
      end.to change { duty.user }.to(subject.current_user)
      expect(duty.free).to be(false)
      expect(duty.request_user_id).to be(nil)
      should redirect_to duties_path
      expect(flash[:notice]).to be('Duty successfully grabbed!')
    end

    it 'grabs duty given to me' do
      duty = create(:duty, free: false, request_user: subject.current_user)
      expect do
        patch :grab, params: { duty_id: { duty.id => duty.id } }
        duty.reload
      end.to change { duty.user }.to(subject.current_user)
      expect(duty.free).to be(false)
      expect(duty.request_user_id).to be(nil)
      should redirect_to duties_path
      expect(flash[:notice]).to be('Duty successfully grabbed!')
    end

    it 'regrabs duty dropped to someone' do
      duty = create(:duty, user: subject.current_user,
                           request_user: create(:user))

      patch :grab, params: { duty_id: { duty.id => duty.id } }
      duty.reload

      expect(duty.free).to be(false)
      expect(duty.request_user_id).to be(nil)
      should redirect_to duties_path
      expect(flash[:notice]).to be('Duty successfully grabbed!')
    end

    it 'does nothing when no duties are grabbed' do
      patch :grab, params: { duty_id: {} }
      should redirect_to duties_path
      expect(flash[:alert]).to be('Error in grabbing duty! Please try again.')
    end

    it 'does nothing when the duty is not for me' do
      duty = create(:duty, free: false, request_user_id: create(:user))
      patch :grab, params: { duty_id: { duty.id => duty.id } }
      should redirect_to duties_path
      expect(flash[:alert]).to be('Error in grabbing duty! Please try again.')
    end

    it 'does nothing when nil duties are grabbed' do
      patch :grab, params: { duty_id: nil }
      should redirect_to duties_path
      expect(flash[:alert]).to be('Error in grabbing duty! Please try again.')
    end

    it 'does nothing when nonfree are grabbed' do
      duty = create(:duty, free: false)
      patch :grab, params: { duty_id: { duty.id => duty.id } }

      should redirect_to duties_path
      expect(flash[:alert]).to be('Error in grabbing duty! Please try again.')
    end
  end

  describe 'POST duties#drop' do
    before do
      @user = create(:user)
      sign_in @user
    end

    it 'drop a duty to all' do
      duty = create(:duty, user: @user)
      expect do
        patch :drop, params: { duty_id: { duty.id => duty.id }, user_id: 0 }
        duty.reload
      end.to change { duty.free }.to(true)
      should redirect_to duties_path
      expect(flash[:notice]).to be('Duty successfully dropped!')
    end

    it 'drop a duty to someone' do
      duty = create(:duty, user: @user)
      user = create(:user)
      expect do
        patch :drop, params: { duty_id: { duty.id => duty.id },
                               user_id: user.id }
        duty.reload
      end.to change { duty.request_user_id }.to(user.id)
      should redirect_to duties_path
    end

    it 'does nothing when no duties are dropped' do
      patch :drop, params: { duty_id: {} }
      should redirect_to duties_path
      expect(flash[:alert]).to be('Error in dropping duty! Please try again.')
    end

    it 'does nothing when nil duties are dropped' do
      patch :drop, params: { duty_id: nil }
      should redirect_to duties_path
      expect(flash[:alert]).to be('Error in dropping duty! Please try again.')
    end

    it 'does nothing when nil duty owners are dropped' do
      duty = create(:duty, user: nil)
      patch :drop, params: { duty_id: { duty.id => duty.id } }

      should redirect_to duties_path
      expect(flash[:alert]).to be('Error in dropping duty! Please try again.')
    end

    it 'does nothing when duty not owned by the user are dropped' do
      duty = create(:duty, user: create(:user))
      patch :drop, params: { duty_id: { duty.id => duty.id } }

      should redirect_to duties_path
      expect(flash[:alert]).to be('Error in dropping duty! Please try again.')
    end
  end

  describe 'GET duties#show_grabable_duties' do
    context 'unauthenticated' do
      it do
        get(:show_grabable_duties)
        should redirect_to new_user_session_path
      end
    end
    context 'authenticated' do
      it do
        sign_in create(:user)
        get :show_grabable_duties
        should respond_with :ok
      end
    end
  end

  describe 'POST duties#open_drop_modal' do
    context 'unauthenticated' do
      it do
        post :open_drop_modal, params: { 'drop_duty_list' => ['1'] }
        should redirect_to new_user_session_path
      end
    end
    context 'authenticated' do
      it do
        user = create(:user)
        sign_in user
        duties = create_list(:duty, 3, user: user)
        params = { 'drop_duty_list' => duties.map(&:id).map(&:to_s) }
        post :open_drop_modal, params: params, xhr: true
        should respond_with :ok
      end
    end
  end

  describe 'POST duties #open_grab_modal' do
    context 'unauthenticated' do
      it do
        post :open_grab_modal, params: { 'drop_duty_list' => ['1'] }
        should redirect_to new_user_session_path
      end
    end

    context 'authenticated' do
      it do
        user = create(:user)
        sign_in user
        duties = create_list(:duty, 3, user: user)
        params = { 'grab_duty_list' => duties.map(&:id).map(&:to_s) }
        post :open_grab_modal, params: params, xhr: true
        should respond_with :ok
      end
    end
  end
end
