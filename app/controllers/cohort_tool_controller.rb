class CohortToolController < ApplicationController
  def index
    @location = GlobalProperty.find_by_property("facility.name").property_value rescue ""

    if params[:reportType]
      @reportType = params[:reportType] rescue nil
    else
      @reportType = nil
    end

  end

  def select
    @cohort_quarters  = [""]
    @report_type      = params[:report_type]
    @header 	        = params[:report_type] rescue ""
    @page_destination = ("/" + params[:dashboard].gsub("_", "/")) rescue ""

    if @report_type == "in_arv_number_range"
      @arv_number_start = params[:arv_number_start]
      @arv_number_end   = params[:arv_number_end]
    end

  start_date  = Encounter.initial_encounter.encounter_datetime
  end_date    = Date.today

  @cohort_quarters  += Report.generate_cohort_quarters(start_date, end_date)
  end

  def reports
    session[:list_of_patients] = nil
    if params[:report]
      case  params[:report_type]
        when "visits_by_day"
          redirect_to :action   => "visits_by_day",
                      :name     => params[:report],
                      :pat_name => "Visits by day",
                      :quarter  => params[:report].gsub("_"," ")
        return

        when "non_eligible_patients_in_cohort"
          date = Report.generate_cohort_date_range(params[:quarter])

          redirect_to :action       => "cohort_debugger",
                      :controller   => "reports",
                      :start_date   => date.first.to_s,
                      :end_date     => date.last.to_s,
                      :id           => "start_reason_other",
                      :report_type  => "non_eligible patients in: #{params[:report]}"
        return

        when "out_of_range_arv_number"
          redirect_to :action           => "out_of_range_arv_number",
                      :arv_end_number   => params[:arv_end_number],
                      :arv_start_number => params[:arv_start_number],
                      :quarter          => params[:report].gsub("_"," "),
                      :report_type      => params[:report_type]
        return

        when "data_consistency_check"
          redirect_to :action       => "data_consistency_check",
                      :quarter      => params[:report],
                      :report_type  => params[:report_type]
        return

        when "summary_of_records_that_were_updated"
          redirect_to :action   => "records_that_were_updated",
                      :quarter  => params[:report].gsub("_"," ")
        return

        when "adherence_histogram_for_all_patients_in_the_quarter"
          redirect_to :action   => "adherence",
                      :quarter  => params[:report].gsub("_"," ")
        return

        when "patients_with_adherence_greater_than_hundred"
          redirect_to :action  => "patients_with_adherence_greater_than_hundred",
                      :quater => params[:report].gsub("_"," ")
        return

        when "patients_with_multiple_start_reasons"
          redirect_to :action       => "patients_with_multiple_start_reasons",
                      :quarter      => params[:report],
                      :report_type  => params[:report_type]
        return

        when "dispensations_without_prescriptions"
          redirect_to :action       => "dispensations_without_prescriptions",
                      :quarter      => params[:report],
                      :report_type  => params[:report_type]
        return

        when "prescriptions_without_dispensations"
          redirect_to :action       => "prescriptions_without_dispensations",
                      :quarter      => params[:report],
                      :report_type  => params[:report_type]
        return

        when "drug_stock_report"
          start_date  = "#{params[:start_year]}-#{params[:start_month]}-#{params[:start_day]}"
          end_date    = "#{params[:end_year]}-#{params[:end_month]}-#{params[:end_day]}"

          if end_date.to_date < start_date.to_date
            redirect_to :controller   => "cohort_tool",
                        :action       => "select",
                        :report_type  =>"drug_stock_report" and return
          end rescue nil

          redirect_to :controller => "drug",
                      :action     => "report",
                      :start_date => start_date,
                      :end_date   => end_date,
                      :quarter    => params[:report].gsub("_"," ")
        return
      end
    end
  end

  def records_that_were_updated
    @quarter    = params[:quarter]

    date_range  = Report.generate_cohort_date_range(@quarter)
    @start_date = date_range.first
    @end_date   = date_range.last

    @encounters = CohortTool.records_that_were_updated(@quarter)

    render :layout => false
  end

  def visits_by_day
    @quarter    = params[:quarter]

    date_range          = Report.generate_cohort_date_range(@quarter)
    @start_date         = date_range.first
    @end_date           = date_range.last
    visits              = Encounter.visits_by_day(@start_date.beginning_of_day, @end_date.end_of_day)
    @patients           = CohortTool.visiting_patients_by_day(visits)
    @visits_by_day      = CohortTool.visits_by_week(visits)
    @visits_by_week_day = CohortTool.visits_by_week_day(visits)

    render :layout => false
  end

  def prescriptions_without_dispensations
      include_url_params_for_back_button

      date_range  = Report.generate_cohort_date_range(params[:quarter])
      start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
      end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
      @report     = Order.prescriptions_without_dispensations_data(start_date , end_date)

      render :layout => 'report'
  end
  
  def  dispensations_without_prescriptions
       include_url_params_for_back_button

      date_range  = Report.generate_cohort_date_range(params[:quarter])
      start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
      end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
      @report     = Order.dispensations_without_prescriptions_data(start_date , end_date)

       render :layout => 'report'
  end
  
  def  patients_with_multiple_start_reasons
       include_url_params_for_back_button

      date_range  = Report.generate_cohort_date_range(params[:quarter])
      start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
      end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
      @report     = Observation.patients_with_multiple_start_reasons(start_date , end_date)

      render :layout => 'report'
  end
  
  def out_of_range_arv_number

      include_url_params_for_back_button

      date_range        = Report.generate_cohort_date_range(params[:quarter])
      start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
      end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
      arv_number_range  = [params[:arv_start_number].to_i, params[:arv_end_number].to_i]

      @report = PatientIdentifier.out_of_range_arv_numbers(arv_number_range, start_date, end_date)
uninitialized constant CohortToolController
      render :layout => 'report'
  end
  
  def data_consistency_check
      include_url_params_for_back_button
      date_range  = Report.generate_cohort_date_range(params[:quarter])
      start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
      end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")

      @dead_patients_with_visits       = Patient.dead_with_visits(start_date, end_date)
      @males_allegedly_pregnant        = Patient.males_allegedly_pregnant(start_date, end_date)
      @patients_with_wrong_start_dates = Patient.with_drug_start_dates_less_than_program_enrollment_dates(start_date, end_date)
      session[:data_consistency_check] = { :dead_patients_with_visits => @dead_patients_with_visits,
                                           :males_allegedly_pregnant  => @males_allegedly_pregnant,
                                           :patients_with_wrong_start_dates => @patients_with_wrong_start_dates
                                         }
      @checks = [['Dead patients with Visits', @dead_patients_with_visits.length],
                 ['Male patients with a pregnant observation', @males_allegedly_pregnant.length],
                 ['Patients who moved from 2nd to 1st line drugs', 0],
                 ['patients with start dates > first receive drug dates', @patients_with_wrong_start_dates.length]]
      render :layout => 'report'
  end
  
  def list
    @report = []
    include_url_params_for_back_button

    case params[:check_type]
       when 'Dead patients with Visits' then
            @report  =  session[:data_consistency_check][:dead_patients_with_visits]
       when 'Patients who moved from 2nd to 1st line drugs'then

       when 'Male patients with a pregnant observation' then
             @report =  session[:data_consistency_check][:males_allegedly_pregnant]
       when 'patients with start dates > first receive drug dates' then
             @report =  session[:data_consistency_check][:patients_with_wrong_start_dates]
       else

    end

    render :layout => 'report'
  end

  def include_url_params_for_back_button
       @report_quarter = params[:quarter]
       @report_type = params[:report_type]
  end
  
  def cohort
    @quater = params[:quater]
    start_date,end_date = Report.generate_cohort_date_range(@quater)
    cohort = Cohort.new(start_date,end_date)
    @cohort = cohort.report
    @survival_analysis = SurvivalAnalysis.report(cohort)
    
    render :layout => 'cohort'
  end
  
  def maternity_cohort
    @selSelect = params[:selSelect] rescue nil
    @day =  params[:day] rescue nil
    @selYear = params[:selYear] rescue nil
    @selWeek = params[:selWeek] rescue nil
    @selMonth = params[:selMonth] rescue nil
    @selQtr = "#{params[:selQtr].gsub(/&/, "_")}" rescue nil

    @start_date = params[:start_date] rescue nil
    @end_date = params[:end_date] rescue nil

    @reportType = params[:reportType] rescue ""

    render :layout => "menu"
  end

  def cohort_menu
  end

def adherence
    adherences = CohortTool.adherence(params[:quarter])
    @quater = params[:quarter]
    type = "patients_with_adherence_greater_than_hundred"
    @report_type = "Adherence Histogram for all patients"
    @adherence_summary = "&nbsp;&nbsp;<button onclick='adhSummary();'>Summary</button>" unless adherences.blank?
    @adherence_summary+="<input class='test_name' type=\"button\" onmousedown=\"document.location='/cohort_tool/reports?report=#{@quater}&report_type=#{type}';\" value=\"Over 100% Adherence\"/>"  unless adherences.blank?
    @adherence_summary_hash = Hash.new(0)
    adherences.each{|adherence,value|
      adh_value = value.to_i
      current_adh = adherence.to_i
      if current_adh <= 94
        @adherence_summary_hash["0 - 94"]+= adh_value
      elsif current_adh >= 95 and current_adh <= 100
        @adherence_summary_hash["95 - 100"]+= adh_value
      else current_adh > 100
        @adherence_summary_hash["> 100"]+= adh_value
      end
    }
    @adherence_summary_hash['missing'] = CohortTool.missing_adherence(@quater).length rescue 0
    @adherence_summary_hash.values.each{|n|@adherence_summary_hash["total"]+=n}

    data = ""
    adherences.each{|x,y|data+="#{x}:#{y}:"}
    @id = data[0..-2] || ''

    @results = @id
    @results = @results.split(':').enum_slice(2).map
    @results = @results.each {|result| result[0] = result[0]}.sort_by{|result| result[0]}
    @results.each{|result| @graph_max = result[1].to_f if result[1].to_f > (@graph_max || 0)}
    @graph_max ||= 0
    render :layout => false
  end

  def patients_with_adherence_greater_than_hundred

      min_range = params[:min_range]
      max_range = params[:max_range]
      missing_adherence = false
      missing_adherence = true if params[:show_missing_adherence] == "yes"
      session[:list_of_patients] = nil

      @patients = CohortTool.adherence_over_hundred(params[:quater],min_range,max_range,missing_adherence)

      @quater = params[:quater] + ": (#{@patients.length})" rescue  params[:quater]
      if missing_adherence
        @report_type = "Patient(s) with missing adherence"
      elsif max_range.blank? and min_range.blank?
        @report_type = "Patient(s) with adherence greater than 100%"
      else
        @report_type = "Patient(s) with adherence starting from  #{min_range}% to #{max_range}%"
      end
      render :layout => 'report'
      return
  end

  def maternity_cohort_print
    # raise params.to_yaml
    @location_name = GlobalProperty.find_by_property('facility.name').property_value rescue ""

    @reportType = params[:reportType] rescue ""

    @start_date = nil
    @end_date = nil

    case params[:selSelect]
    when "day"
      @start_date = params[:day]
      @end_date = params[:day]

    when "week"

      @start_date = (("#{params[:selYear]}-01-01".to_date) + (params[:selWeek].to_i * 7)) -
        ("#{params[:selYear]}-01-01".to_date.strftime("%w").to_i)

      @end_date = (("#{params[:selYear]}-01-01".to_date) + (params[:selWeek].to_i * 7)) +
        6 - ("#{params[:selYear]}-01-01".to_date.strftime("%w").to_i)

    when "month"
      @start_date = ("#{params[:selYear]}-#{params[:selMonth]}-01").to_date.strftime("%Y-%m-%d")
      @end_date = ("#{params[:selYear]}-#{params[:selMonth]}-#{ (params[:selMonth].to_i != 12 ?
        ("2010-#{params[:selMonth].to_i + 1}-01".to_date - 1).strftime("%d") : 31) }").to_date.strftime("%Y-%m-%d")

    when "year"
      @start_date = ("#{params[:selYear]}-01-01").to_date.strftime("%Y-%m-%d")
      @end_date = ("#{params[:selYear]}-12-31").to_date.strftime("%Y-%m-%d")

    when "quarter"
      day = params[:selQtr].to_s.match(/^min=(.+)_max=(.+)$/)

      @start_date = (day ? day[1] : Date.today.strftime("%Y-%m-%d"))
      @end_date = (day ? day[2] : Date.today.strftime("%Y-%m-%d"))

    when "range"
      @start_date = params[:start_date]
      @end_date = params[:end_date]

    end

    @section = nil

    case @reportType.to_i
    when 2:
        @section = Location.find_by_name("Labour Ward").location_id rescue nil
    when 3:
        @section = Location.find_by_name("Ante-Natal Ward").location_id rescue nil
    when 4:
        @section = Location.find_by_name("Post-Natal Ward").location_id rescue nil
    when 5:
        @section = Location.find_by_name("Gynaecology Ward").location_id rescue nil
    when 6:
        @section = Location.find_by_name("Post-Natal Ward (High Risk)").location_id rescue nil
    when 7:
        @section = Location.find_by_name("Post-Natal Ward (Low Risk)").location_id rescue nil
    end

    report = Reports::Cohort.new(@start_date, @end_date, @section)

    # @fields = [
    #   [
    #     "Field Label",
    #     "0730_1630 Value",
    #     "1630_0730 Value"
    #   ]
    # ]
    @fields = [
      ["Admissions", report.admissions0730_1630, report.admissions1630_0730],
      ["Discharges", report.discharged0730_1630, report.discharged1630_0730],
      ["Referrals (Out)", report.referralsOut0730_1630, report.referralsOut1630_0730],
      ["Referrals (In)", report.referrals0730_1630, report.referrals1630_0730],
      ["Maternal Deaths", report.maternal_deaths0730_1630, report.maternal_deaths1630_0730],
      ["C/Section", report.cesarean0730_1630, report.cesarean1630_0730],
      ["SVDs", report.svds0730_1630, report.svds1630_0730],
      ["Vacuum Extraction", report.vacuum0730_1630, report.vacuum1630_0730],
      ["Breech Delivery", report.breech0730_1630, report.breech1630_0730],
      ["Ruptured Uterus", report.ruptured_uterus0730_1630, report.ruptured_uterus1630_0730],
      ["Triplets", report.triplets0730_1630, report.triplets1630_0730],
      ["Twins", report.twins0730_1630, report.twins1630_0730],
      ["BBA", report.bba0730_1630, report.bba1630_0730],
      # ["Antenatal Mothers", "", ""],
      # ["Postnatal Mothers", "", ""],
      ["Macerated Still Births", report.macerated0730_1630, report.macerated1630_0730],
      ["Fresh Still Births", report.fresh0730_1630, report.fresh1630_0730],
      ["Waiting Mothers", report.waiting_bd_ante_w0730_1630, report.waiting_bd_ante_w1630_0730],
      ["Continued Care", report.labour_to_ante_w0730_1630, report.labour_to_ante_w1630_0730],
      ["Total Clients", report.total_patients0730_1630, report.total_patients1630_0730],
      ["Total Mothers", report.total_patients0730_1630, report.total_patients1630_0730],
      ["Total Babies", report.babies0730_1630, report.babies1630_0730],
      ["Transfer (Ante-Natal - Labour)",
        report.source_to_destination_ward0730_1630("ANTE-NATAL WARD", "LABOUR WARD"),
        report.source_to_destination_ward1630_0730("ANTE-NATAL WARD", "LABOUR WARD")],
      ["Transfer (Labour - Ante-Natal)",
        report.source_to_destination_ward0730_1630("LABOUR WARD", "ANTENATAL WARD"),
        report.source_to_destination_ward1630_0730("LABOUR WARD", "ANTENATAL WARD")],
      ["Transfer (PostNatal - Labour)",
        report.source_to_destination_ward0730_1630("POST-NATAL WARD", "LABOUR WARD"),
        report.source_to_destination_ward1630_0730("POST-NATAL WARD", "LABOUR WARD")],
      ["Transfer (Labour - Post-Natal)",
        report.source_to_destination_ward0730_1630("LABOUR WARD", "POSTNATAL WARD"),
        report.source_to_destination_ward1630_0730("LABOUR WARD", "POSTNATAL WARD")],
      ["Transfer (Post-Natal Ward (Low Risk) - Labour)",
        report.source_to_destination_ward0730_1630("Post-Natal Ward (Low Risk)", "LABOUR WARD"),
        report.source_to_destination_ward1630_0730("Post-Natal Ward (Low Risk)", "LABOUR WARD")],
      ["Transfer (Labour - Post-Natal Ward (Low Risk))",
        report.source_to_destination_ward0730_1630("LABOUR WARD", "Post-Natal Ward (Low Risk)"),
        report.source_to_destination_ward1630_0730("LABOUR WARD", "Post-Natal Ward (Low Risk)")],
      ["Transfer (Post-Natal Ward (High Risk) - Labour)",
        report.source_to_destination_ward0730_1630("Post-Natal Ward (High Risk)", "LABOUR WARD"),
        report.source_to_destination_ward1630_0730("Post-Natal Ward (High Risk)", "LABOUR WARD")],
      ["Transfer (Labour - Post-Natal Ward (High Risk))",
        report.source_to_destination_ward0730_1630("LABOUR WARD", "Post-Natal Ward (High Risk)"),
        report.source_to_destination_ward1630_0730("LABOUR WARD", "Post-Natal Ward (High Risk)")],
      ["Transfer (Post-Natal Ward (High Risk) - Post-Natal Ward (Low Risk))",
        report.source_to_destination_ward0730_1630("Post-Natal Ward (High Risk)", "Post-Natal Ward (Low Risk)"),
        report.source_to_destination_ward1630_0730("Post-Natal Ward (High Risk)", "Post-Natal Ward (Low Risk)")],
      ["Transfer (Post-Natal Ward (Low Risk) - Post-Natal Ward (High Risk))",
        report.source_to_destination_ward0730_1630("Post-Natal Ward (Low Risk)", "Post-Natal Ward (High Risk)"),
        report.source_to_destination_ward1630_0730("Post-Natal Ward (Low Risk)", "Post-Natal Ward (High Risk)")],
      ["Transfer (Gynaecology Ward - Labour)",
        report.source_to_destination_ward0730_1630("Gynaecology Ward", "LABOUR WARD"),
        report.source_to_destination_ward1630_0730("Gynaecology Ward", "LABOUR WARD")],
      ["Transfer (Labour - Gynaecology Ward)",
        report.source_to_destination_ward0730_1630("LABOUR WARD", "Gynaecology Ward"),
        report.source_to_destination_ward1630_0730("LABOUR WARD", "Gynaecology Ward")],
      ["Transfer (Gynaecology Ward - Post-Natal Ward (High Risk))",
        report.source_to_destination_ward0730_1630("Gynaecology Ward", "Post-Natal Ward (High Risk)"),
        report.source_to_destination_ward1630_0730("Gynaecology Ward", "Post-Natal Ward (High Risk)")],
      ["Transfer (Post-Natal Ward (High Risk) - Gynaecology Ward)",
        report.source_to_destination_ward0730_1630("Post-Natal Ward (High Risk)", "Gynaecology Ward"),
        report.source_to_destination_ward1630_0730("Post-Natal Ward (High Risk)", "Gynaecology Ward")],
      ["Transfer (Gynaecology Ward - Post-Natal Ward (Low Risk))",
        report.source_to_destination_ward0730_1630("Gynaecology Ward", "Post-Natal Ward (Low Risk)"),
        report.source_to_destination_ward1630_0730("Gynaecology Ward", "Post-Natal Ward (Low Risk)")],
      ["Transfer (Post-Natal Ward (Low Risk) - Gynaecology Ward)",
        report.source_to_destination_ward0730_1630("Post-Natal Ward (Low Risk)", "Gynaecology Ward"),
        report.source_to_destination_ward1630_0730("Post-Natal Ward (Low Risk)", "Gynaecology Ward")],
      ["Fistula", report.fistula0730_1630, report.fistula1630_0730],
      ["Post Partum Haemorrhage", report.postpartum0730_1630, report.postpartum1630_0730],
      ["Ante Partum Haemorrhage", report.antepartum0730_1630, report.antepartum1630_0730],
      ["Eclampsia", report.eclampsia0730_1630, report.eclampsia1630_0730],
      ["Pre-Eclampsia", report.pre_eclampsia0730_1630, report.pre_eclampsia1630_0730],
      ["Anaemia", report.anaemia0730_1630, report.anaemia1630_0730],
      ["Malaria", report.malaria0730_1630, report.malaria1630_0730],
      ["Pre-Mature Labour", report.pre_mature_labour0730_1630, report.pre_mature_labour1630_0730],
      ["Pre-Mature Membrane Rapture", report.pre_mature_rapture0730_1630, report.pre_mature_rapture1630_0730],
      ["Abscondees", report.absconded0730_1630, report.absconded1630_0730],
      ["Abortions", report.abortion0730_1630, report.abortion1630_0730],
      ["Cancer of Cervix", report.cancer0730_1630, report.cancer1630_0730],
      ["Fibroids", report.fibroids0730_1630, report.fibroids1630_0730],
      ["Molar Pregnancy", report.molar0730_1630, report.molar1630_0730],
      ["Pelvic Inflamatory Disease", report.pelvic0730_1630, report.pelvic1630_0730],
      ["Ectopic Pregnancy", report.ectopic0730_1630, report.ectopic1630_0730]
    ]

    @specified_period = report.specified_period

=begin
    # raise @specified_period.to_yaml

    @admissions0730_1630 = report.admissions0730_1630

    @admissions1630_0730 = report.admissions1630_0730

    @discharged0730_1630 = report.discharged0730_1630

    @discharged1630_0730 = report.discharged1630_0730

    @referrals0730_1630 = report.referrals0730_1630

    @referrals1630_0730 = report.referrals1630_0730

    @deaths0730_1630 = report.deaths0730_1630

    @deaths1630_0730 = report.deaths1630_0730

    @cesarean0730_1630 = report.cesarean0730_1630

    @cesarean1630_0730 = report.cesarean1630_0730

    @svds0730_1630 = report.svds0730_1630

    @svds1630_0730 = report.svds1630_0730

    @vacuum0730_1630 = report.vacuum0730_1630

    @vacuum1630_0730 = report.vacuum1630_0730

    @breech0730_1630 = report.breech0730_1630

    @breech1630_0730 = report.breech1630_0730

    @ruptured0730_1630 = report.ruptured0730_1630

    @ruptured1630_0730 = report.ruptured1630_0730

    @bba0730_1630 = report.bba0730_1630

    @bba1630_0730 = report.bba1630_0730

    @triplets0730_1630 = report.triplets0730_1630

    @triplets1630_0730 = report.triplets1630_0730

    @twins0730_1630 = report.twins0730_1630

    @twins1630_0730 = report.twins1630_0730
=end

    render :layout => false
  end

  def print_cohort
    # raise request.env["HTTP_HOST"].to_yaml

    @selSelect = params[:selSelect] rescue ""
    @day =  params[:day] rescue ""
    @selYear = params[:selYear] rescue ""
    @selWeek = params[:selWeek] rescue ""
    @selMonth = params[:selMonth] rescue ""
    @selQtr = params[:selQtr] rescue ""
    @start_date = params[:start_date] rescue ""
    @end_date = params[:end_date] rescue ""

    @reportType = params[:reportType] rescue ""

    if params
      link = ""
      case @selSelect
      when "week"

        link = "/cohort_tool/maternity_cohort_print?selSelect=#{@selSelect}&selYear=#{@selYear}&selWeek=#{@selWeek}&reportType=#{@reportType}"

      when "month"

        link = "/cohort_tool/maternity_cohort_print?selSelect=#{@selSelect}&selYear=#{@selYear}&selMonth=#{@selMonth}&reportType=#{@reportType}"

      when "year"

        link = "/cohort_tool/maternity_cohort_print?selSelect=#{@selSelect}&selYear=#{@selYear}&reportType=#{@reportType}"

      when "quarter"

        link = "/cohort_tool/maternity_cohort_print?selSelect=#{@selSelect}&selQtr=#{@selQtr}&reportType=#{@reportType}"

      when "range"

        link = "/cohort_tool/maternity_cohort_print?selSelect=#{@selSelect}&start_date=#{@start_date}&end_date=#{@end_date}&reportType=#{@reportType}"

      when "day"

        link = "/cohort_tool/maternity_cohort_print?selSelect=#{@selSelect}&day=#{@day}&reportType=#{@reportType}"

      end

      t1 = Thread.new{
        Kernel.system "htmldoc --webpage -f /tmp/output-" + session[:user_id].to_s + ".pdf \"http://" +
          request.env["HTTP_HOST"] + link + "\"\n"
      }

      t2 = Thread.new{
        sleep(5)
        Kernel.system "lpr /tmp/output-" + session[:user_id].to_s + ".pdf\n"
      }

      t3 = Thread.new{
        sleep(10)
        Kernel.system "rm /tmp/output-" + session[:user_id].to_s + ".pdf\n"
      }

    end

    redirect_to "/cohort/cohort?selSelect=#{ @selSelect }&day=#{ @day }" +
      "&selYear=#{ @selYear }&selWeek=#{ @selWeek }&selMonth=#{ @selMonth }&selQtr=#{ @selQtr }" +
      "&start_date=#{ @start_date }&end_date=#{ @end_date }&reportType=#{@reportType}" and return
  end

end

