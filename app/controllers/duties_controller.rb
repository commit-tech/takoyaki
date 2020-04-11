# frozen_string_literal: true

class DutiesController < ApplicationController
  load_and_authorize_resource only: [:export]
  def index
    @header_iter = generate_header_iter
    set_start_end_dates
    # Eager load all rows in Place
    @places = Place.all.map { |p| p }
    prepare_announcements
  end

  def generate_duties
    set_start_end_dates
    end_date = @start_date + (params[:num_weeks].to_i * 7 - 1).days
    Duty.generate(@start_date, end_date)
    redirect_to duties_path(start_date: @start_date),
                notice: 'Duties successfully generated!'
  end

  def open_drop_modal
    @users = User.where.not(id: current_user.id).order(:username)
    @drop_duty_list = Duty.includes(%i[time_range place])
                          .find(params[:drop_duty_list])
    respond_to do |format|
      format.js
      format.html
    end
  end

  def open_grab_modal
    @grab_duty_list = Duty.includes(%i[time_range place])
                          .find(params[:grab_duty_list])
    respond_to do |format|
      format.js
      format.html
    end
  end

  def grab
    grab_duty_ids = params[:duty_id].present? && params[:duty_id].keys
    if grabable?(grab_duty_ids)
      start_of_week = Duty.find(grab_duty_ids.first)
                          .date.beginning_of_week
      grab_duty(grab_duty_ids, start_of_week)
    elsif can_duty_mc_timeslots?(grab_duty_ids) == false
      flash[:error] = 'You cannot duty MC timeslots'
      redirect_to duties_path, alert: 'Invalid duties to grab'
    elsif Duty.joins(%i[time_range place]).where(
      '(date + time_ranges.start_time) <= ?', Time.zone.now
    )
      flash[:error] = 'You cannot grab a past slot'
      redirect_to duties_path, alert: 'Invalid duties to grab'
    else
      redirect_to duties_path, alert: 'Invalid duties to grab'
    end
  end

  def drop
    if owned_duties?(params[:duty_id], current_user)
      drop_duty_ids = params[:duty_id].keys
      start_of_week = Duty.find(drop_duty_ids.first).date.beginning_of_week
      drop_duties(drop_duty_ids, start_of_week)
    else
      redirect_to duties_path, alert: 'Invalid duties to drop'
    end
  end

  def show_grabable_duties
    @grabable_duties = grabable_duties
  end

  def export
    @header_iter = generate_header_iter
    respond_to do |format|
      format.xlsx do
        header = 'attachment; filename=duties.xlsx'
        response.headers['Content-Disposition'] = header
      end
      format.html { render :export }
    end
  end

  private

  def grabable_duties
    duties = Duty.joins(%i[time_range place])
    duties.where(free: true)
          .or(duties.where(request_user_id: current_user.id))
          .or(duties.where(user_id: current_user.id)
                    .where.not(request_user_id: nil))
          .where('(date + time_ranges.start_time) > ?', Time.zone.now)
  end

  def owned_duties?(duty_id_params, supposed_user)
    duty_id_params.present? &&
      Duty.where('id IN (?) AND user_id = ?',
                 duty_id_params.keys, supposed_user.id)
          .count == duty_id_params.keys.length
  end

  def can_duty_mc_timeslots?(duty_ids)
    return true if current_user.mc

    timeslot_ids = Duty.where(id: duty_ids).pluck(:timeslot_id)
    timeslots = Timeslot.find(timeslot_ids)
    timeslots.all? { |t| !t.mc_only }
  end

  def grabable?(duty_ids)
    return false if duty_ids.blank?
    return false unless can_duty_mc_timeslots?(duty_ids)

    grabable_duties.where(id: duty_ids).size == duty_ids.size
  end

  def can_drop_duties?(drop_duty_ids)
    duties = duties_sorted_by_start_time(drop_duty_ids)
    duty_date = duties.first.date
    duty_start_time = duties.first.time_range.start_time
    duty_datetime = duty_date + duty_start_time.seconds_since_midnight.seconds
    Time.zone.now <= (duty_datetime - 2.hours)
  end

  def drop_duties_to_user(drop_duty_ids, swap_user_id)
    duties = duties_sorted_by_start_time(drop_duty_ids)
    to_all = swap_user_id.to_i.zero?
    Duty.transaction do
      if to_all
        duties.each { |duty| duty.update(free: true) }
      else
        duties.each { |duty| duty.update(request_user_id: swap_user_id) }
      end
    end
    users_to_notify =
      to_all ? User.pluck(:id) - [duties.first.user.id] : swap_user_id
    GenericMailer.drop_duties(duties, users_to_notify).deliver_later
  end

  def duties_sorted_by_start_time(duty_ids)
    Duty.joins(timeslot: :time_range).order('time_ranges.start_time ASC')
        .includes(:time_range).find(duty_ids)
  end

  def generate_header_iter
    time_range = TimeRange.order(:start_time)
    @first_time = time_range.first.start_time
    @last_time = time_range.last.start_time
    @first_time.to_i.step(@last_time.to_i, 1.hour)
  end

  def prepare_announcements
    @announcements = Announcement.order(created_at: :desc).limit(3)
    @new_announcement = Announcement.new
  end

  def grab_duty(grab_duty_ids, start_of_week)
    Duty.transaction do
      Duty.find(grab_duty_ids).each do |duty|
        duty.update!(user: current_user, free: false, request_user: nil)
      end
      redirect_to duties_path(start_date: start_of_week),
                  notice: 'Duty successfully grabbed!'
    end
  rescue ActiveRecord::RecordInvalid
    redirect_to duties_path(start_date: start_of_week),
                alert: 'Error in grabbing duty! Please try again'
  end

  def drop_duties(drop_duty_ids, start_of_week)
    if can_drop_duties?(drop_duty_ids)
      begin
        drop_duties_to_user(drop_duty_ids, params[:user_id])
        redirect_to duties_path(start_date: start_of_week),
                    notice: 'Duty successfully dropped!'
      rescue ActiveRecord::RecordInvalid
        redirect_to duties_path(start_date: start_of_week),
                    alert: 'Error in dropping duty! Please try again later.'
      end
    else
      redirect_to duties_path(start_date: start_of_week),
                  alert: 'Error in dropping duty! ' \
                  'You can only drop your duty at most 2 hours before it starts'
    end
  end
end
