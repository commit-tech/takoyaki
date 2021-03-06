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

    it do
      should respond_with :ok
      assert_template :index
    end
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
      start_date = duty.date.beginning_of_week
      expect do
        patch :grab, params: { duty_id: { duty.id => duty.id } }
        duty.reload
      end.to change { duty.user }.to(subject.current_user)
      expect(duty.free).to be(false)
      expect(duty.request_user_id).to be(nil)
      should redirect_to duties_path(start_date: start_date)
      expect(flash[:notice]).to be('Duty successfully grabbed!')
    end

    it 'grabs duty given to me' do
      duty = create(:duty, free: false, request_user: subject.current_user)
      start_date = duty.date.beginning_of_week
      expect do
        patch :grab, params: { duty_id: { duty.id => duty.id } }
        duty.reload
      end.to change { duty.user }.to(subject.current_user)
      expect(duty.free).to be(false)
      expect(duty.request_user_id).to be(nil)
      should redirect_to duties_path(start_date: start_date)
      expect(flash[:notice]).to be('Duty successfully grabbed!')
    end

    it 'regrabs duty dropped to someone' do
      duty = create(:duty, user: subject.current_user,
                           request_user: create(:user))
      start_date = duty.date.beginning_of_week

      patch :grab, params: { duty_id: { duty.id => duty.id } }
      duty.reload

      expect(duty.free).to be(false)
      expect(duty.request_user_id).to be(nil)
      should redirect_to duties_path(start_date: start_date)
      expect(flash[:notice]).to be('Duty successfully grabbed!')
    end

    it 'does nothing when no duties are grabbed' do
      patch :grab, params: { duty_id: {} }
      should redirect_to duties_path
      expect(flash[:alert]).to be('Invalid duties to grab')
    end

    it 'does nothing when the duty is not for me' do
      duty = create(:duty, free: false, request_user_id: create(:user))
      patch :grab, params: { duty_id: { duty.id => duty.id } }
      should redirect_to duties_path
      expect(flash[:alert]).to be('Invalid duties to grab')
    end

    it 'does nothing when nil duties are grabbed' do
      patch :grab, params: { duty_id: nil }
      should redirect_to duties_path
      expect(flash[:alert]).to be('Invalid duties to grab')
    end

    it 'does nothing when nonfree are grabbed' do
      duty = create(:duty, free: false)
      patch :grab, params: { duty_id: { duty.id => duty.id } }

      should redirect_to duties_path
      expect(flash[:alert]).to be('Invalid duties to grab')
    end

    it 'does nothing when non-MC user tries to grab MC duties' do
      timeslot = create(:timeslot, mc_only: true)
      duty = create(:duty, timeslot: timeslot)
      patch :grab, params: { duty_id: { duty.id => duty.id } }

      should redirect_to duties_path
      expect(flash[:alert]).to be('Invalid duties to grab')
    end
  end

  describe 'POST duties#drop' do
    before do
      @user = create(:user)
      sign_in @user
    end

    it 'drop a duty to all' do
      duty = create(:duty, user: @user, date: Time.zone.today + 2.weeks)
      start_date = duty.date.beginning_of_week
      expect do
        patch :drop, params: { duty_id: { duty.id => duty.id }, user_id: 0 }
        duty.reload
      end.to change { duty.free }.to(true)
      should redirect_to duties_path(start_date: start_date)
      expect(flash[:notice]).to be('Duty successfully dropped!')
    end

    it 'drop a duty to someone' do
      duty = create(:duty, user: @user, date: Time.zone.today + 2.weeks)
      user = create(:user)
      start_date = duty.date.beginning_of_week
      expect do
        patch :drop, params: { duty_id: { duty.id => duty.id },
                               user_id: user.id }
        duty.reload
      end.to change { duty.request_user_id }.to(user.id)
      should redirect_to duties_path(start_date: start_date)
    end

    it 'does nothing when duties to be dropped exceed the drop time limit' do
      time_range = create(:time_range, start_time: Time.zone.now + 1.hour,
                                       end_time: Time.zone.now + 2.hours)
      timeslot = create(:timeslot, time_range: time_range)
      duty = create(:duty, user: @user, timeslot: timeslot)
      start_date = duty.date.beginning_of_week
      patch :drop, params: { duty_id: { duty.id => duty.id }, user_id: 0 }
      should redirect_to duties_path(start_date: start_date)
      expect(flash[:alert]).to be('Error in dropping duty! ' \
        'You can only drop your duty at most 2 hours before it starts')
    end

    it 'does nothing when no duties are dropped' do
      patch :drop, params: { duty_id: {} }
      should redirect_to duties_path
      expect(flash[:alert]).to be('Invalid duties to drop')
    end

    it 'does nothing when nil duties are dropped' do
      patch :drop, params: { duty_id: nil }
      should redirect_to duties_path
      expect(flash[:alert]).to be('Invalid duties to drop')
    end

    it 'does nothing when nil duty owners are dropped' do
      duty = create(:duty, user: nil)
      patch :drop, params: { duty_id: { duty.id => duty.id } }

      should redirect_to duties_path
      expect(flash[:alert]).to be('Invalid duties to drop')
    end

    it 'does nothing when duty not owned by the user are dropped' do
      duty = create(:duty, user: create(:user))
      patch :drop, params: { duty_id: { duty.id => duty.id } }

      should redirect_to duties_path
      expect(flash[:alert]).to be('Invalid duties to drop')
    end
  end

  describe 'GET duties#show_grabable_duties' do
    before do
      @mock_time = Time.zone.parse("#{Time.zone.today} 10:00")

      allow(Time).to receive(:now).and_return(@mock_time)
    end
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
        assert_template :show_grabable_duties
      end

      it 'shows nothing if all duties are not grabable' do
        user = create(:user)
        start_time = Time.zone.now - 2.hours
        time_range = create(:time_range, start_time: start_time,
                                         end_time: start_time + 1.hour)
        timeslot = create(:timeslot, time_range: time_range)
        date = start_time.to_date
        create(:duty, user: user, timeslot: timeslot, date: date, free: true)
        sign_in user
        get :show_grabable_duties
        expect(assigns(:grabable_duties)).to be_empty
      end

      it 'shows grabable duties' do
        user = create(:user)
        start_time = Time.zone.now + 1.hour
        time_range = create(:time_range, start_time: start_time,
                                         end_time: start_time + 1.hour)
        timeslot = create(:timeslot, time_range: time_range)
        date = start_time.to_date
        create(:duty, user: user, timeslot: timeslot, date: date, free: true)
        sign_in user
        get :show_grabable_duties
        expect(assigns(:grabable_duties)).not_to be_empty
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
        assert_template :open_drop_modal
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
        assert_template :open_grab_modal
      end
    end
  end

  describe 'GET duties #export' do
    before do
      @user = create(:user)
      sign_in @user
      @place = create(:place)

      allow(controller).to receive(:generate_header_iter).and_return([])
    end
    context 'admin' do
      it 'downloads excel' do
        @user.add_role :admin

        get :export, format: :xlsx
        expect(response.header['Content-Type']).to include(
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )
      end
    end

    context 'non-admin' do
      it 'does not download excel and redirect' do
        get :export, format: :xlsx

        should redirect_to root_path
        expect(flash[:alert]).to(
          eq('You are not authorized to access this page.')
        )

        expect(response.header['Content-Type']).not_to include(
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )
      end
    end
  end
end
