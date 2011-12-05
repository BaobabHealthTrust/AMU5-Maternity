class SessionsController < ApplicationController
  skip_before_filter :login_required, :except => [:location, :update]
  skip_before_filter :location_required

  def new
  end

  def create
    logout_keeping_session!
    user = User.authenticate(params[:login], params[:password])
    if user
      self.current_user = user      
      redirect_to '/clinic'
    else
      note_failed_signin
      @login = params[:login]
      render :action => 'new'
    end
  end

  # Form for entering the location information
  def location
    @location_name = GlobalProperty.find_by_property('facility.name').property_value rescue ""

    @wards = GlobalProperty.find_by_property('facility.login_wards').property_value.split(',') rescue []

    @login_wards = [' ']

    @wards.each{|ward|
      if @location_name.upcase.eql?("KAMUZU CENTRAL HOSPITAL")

        if !ward.upcase.eql?("POST-NATAL WARD (LOW RISK)") && !ward.upcase.eql?("POST-NATAL WARD (HIGH RISK)")
          @login_wards << ward
        end

      elsif @location_name.upcase.eql?("BWAILA MATERNITY UNIT")

        if !ward.upcase.eql?("POST-NATAL WARD") && !ward.upcase.eql?("Gynaecology Ward".upcase)
          @login_wards << ward
        end

      end
    }

    if !@location_name.blank?
      location = Location.find_by_name(@location_name).location_id rescue nil

      if !location.nil?
        @location = location
      else
        @location = ""
      end
    else
      @location = ""
    end
  end

  # Update the session with the location information
  def update    
    # First try by id, then by name
    location = Location.find(params[:location]) rescue nil
    location ||= Location.find_by_name(params[:location]) rescue nil

    valid_location = (generic_locations.include?(location.name)) rescue false

    unless location and valid_location
      flash[:error] = "Invalid workstation location"
      render :action => 'location'
      return    
    end
    self.current_location = location
    if use_user_selected_activities and not location.name.match(/Outpatient/i)
      redirect_to "/user/activities/#{User.current_user.id}"
    else
      redirect_to '/clinic'
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Invalid user name or password"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
end
