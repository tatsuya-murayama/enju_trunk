class StatisticReportsController < ApplicationController
  require 'thinreports'
  before_filter :check_role

  def index
    @year = Time.zone.now.years_ago(1).strftime("%Y")
    @month = Time.zone.now.months_ago(1).strftime("%Y%m")
    @t_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
    @t_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
    @d_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
    @d_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
    @a_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
    @a_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
    @items_year = Time.zone.now.years_ago(1).strftime("%Y")
  end

  # check role
  def check_role
    unless current_user.try(:has_role?, 'Librarian')
      access_denied; return
    end
  end

  def get_monthly_report
    term = params[:term]
    unless term =~ /^\d{4}$/
      flash[:message] = t('statistic_report.invalid_year')
      @year = term
      @month = Time.zone.now.months_ago(1).strftime("%Y%m")
      @t_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @t_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @d_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @d_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @a_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @a_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @items_year = Time.zone.now.years_ago(1).strftime("%Y")
      render :index
      return false
    end
    libraries = Library.all
    checkout_types = CheckoutType.all
    begin 
      report = ThinReports::Report.new :layout => "#{Rails.root.to_s}/app/views/statistic_reports/monthly_report"

      report.events.on :page_create do |e|
        e.page.item(:page).value(e.page.no)
      end
      report.events.on :generate do |e|
        e.pages.each do |page|
          page.item(:total).value(e.report.page_count)
        end
      end

      report.start_new_page
      report.page.item(:date).value(Time.now)       
      report.page.item(:term).value(term)

      # items all libraries
      data_type = 111
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.items'))
        row.item(:library).value(t('statistic_report.all_library'))
        12.times do |t|
          if t < 4 # for Japanese fiscal year
            value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => 0).no_condition.first.value rescue 0
          else
            value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => 0).no_condition.first.value rescue 0
          end
          row.item("value#{t+1}").value(value)
          row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
        end  
      end
      # items each checkout_types
      checkout_types.each do |checkout_type|
        report.page.list(:list).add_row do |row|
          row.item(:option).value(checkout_type.display_name.localize)
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => 0, :checkout_type_id => checkout_type.id).first.value rescue 0
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => 0, :checkout_type_id => checkout_type.id).first.value rescue 0
            end
            row.item("value#{t+1}").value(value)
            row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
          end  
        end
      end
      # items each library
      libraries.each do |library|
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => library.id).no_condition.first.value rescue 0 
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => library.id).no_condition.first.value rescue 0 
            end
            row.item("value#{t+1}").value(value)
            row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
          end  
        end
        # items each checkout_types
        checkout_types.each do |checkout_type|
          report.page.list(:list).add_row do |row|
            row.item(:option).value(checkout_type.display_name.localize)
            12.times do |t|
              if t < 4 # for Japanese fiscal year
                value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => library.id, :checkout_type_id => checkout_type.id).first.value rescue 0
              else
                value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => library.id, :checkout_type_id => checkout_type.id).first.value rescue 0
              end
              row.item("value#{t+1}").value(value)
              row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
            end  
            if library == libraries.last && checkout_type == checkout_types.last
              row.item(:type_line).show
              row.item(:library_line).style(:border_color, '#000000')
              row.item(:library_line).style(:border_width, 1)
              row.item(:option_line).style(:border_color, '#000000')
              row.item(:option_line).style(:border_width, 1)
              row.item(:values_line).style(:border_color, '#000000')
              row.item(:values_line).style(:border_width, 1)
            end  
          end
        end
      end

      # open days of each libraries
      libraries.each do |library|
        report.page.list(:list).add_row do |row|
          row.item(:type).value(t('statistic_report.opens')) if libraries.first == library
          row.item(:library).value(library.display_name)
          sum = 0
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1130, :library_id => library.id).first.value rescue 0 
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1130, :library_id => library.id).first.value rescue 0
            end
            row.item("value#{t+1}").value(value)
            sum += value
          end
          row.item("valueall").value(sum)
          if library == libraries.last
            row.item(:type_line).show
            row.item(:library_line).style(:border_color, '#000000')
            row.item(:library_line).style(:border_width, 1)
            row.item(:option_line).style(:border_color, '#000000')
            row.item(:option_line).style(:border_width, 1)
            row.item(:values_line).style(:border_color, '#000000')
            row.item(:values_line).style(:border_width, 1)
          end  
        end
      end

      # checkout users all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.checkout_users'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        12.times do |t|
          if t < 4 # for Japanese fiscal year
            value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1220, :library_id => 0).first.value rescue 0
          else
            value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1220, :library_id => 0).first.value rescue 0
          end
          row.item("value#{t+1}").value(value)
          sum = sum + value
        end  
        row.item("valueall").value(sum)
      end
      # checkout users each user type[adults, students, children]
      3.times do |i|
        data_type = 122.to_s + (i + 4).to_s
        report.page.list(:list).add_row do |row|
          row.item(:option).value(t("statistic_report.user_type_#{i+1}"))
          sum = 0
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => 0).first.value rescue 0
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => 0).first.value rescue 0
            end
            row.item("value#{t+1}").value(value)
            sum = sum + value
          end  
          row.item("valueall").value(sum)
        end
      end
      # checkout users each library
      libraries.each do |library|
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          sum = 0
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1220, :library_id => library.id).first.value rescue 0 
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1220, :library_id => library.id).first.value rescue 0 
            end
            row.item("value#{t+1}").value(value)
            sum = sum + value
          end  
          row.item("valueall").value(sum)
        end
        # checkout users each user type[adults, students, children]
        3.times do |i|
          data_type = 122.to_s + (i + 4).to_s
          report.page.list(:list).add_row do |row|
            row.item(:option).value(t("statistic_report.user_type_#{i+1}"))
            sum = 0
            12.times do |t|
              if t < 4 # for Japanese fiscal year
                value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => library.id).first.value rescue 0
              else
                value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => library.id).first.value rescue 0
              end
              row.item("value#{t+1}").value(value)
              sum = sum + value
            end  
            row.item("valueall").value(sum)
            if library == libraries.last && i == 2
              row.item(:type_line).show
              row.item(:library_line).style(:border_color, '#000000')
              row.item(:library_line).style(:border_width, 1)
              row.item(:option_line).style(:border_color, '#000000')
              row.item(:option_line).style(:border_width, 1)
              row.item(:values_line).style(:border_color, '#000000')
              row.item(:values_line).style(:border_width, 1)
            end  
          end
        end
      end

      # daily average of checkout users all library
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.average_checkout_users'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        12.times do |t|
          if t < 4 # for Japanese fiscal year
            value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1223, :library_id => 0).first.value rescue 0
          else
            value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1223, :library_id => 0).first.value rescue 0
          end
          row.item("value#{t+1}").value(value)
          sum = sum + value
        end  
        row.item("valueall").value(sum/12)
      end
      # daily average of checkout users each library
      libraries.each do |library|
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          sum = 0
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1223, :library_id => library.id).first.value rescue 0 
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1223, :library_id => library.id).first.value rescue 0 
            end
            row.item("value#{t+1}").value(value)
            sum = sum + value
          end  
          row.item("valueall").value(sum/12)
          if library == libraries.last
            row.item(:type_line).show
            row.item(:library_line).style(:border_color, '#000000')
            row.item(:option_line).style(:border_color, '#000000')
            row.item(:values_line).style(:border_color, '#000000')
          end  
        end
      end

      # checkout items all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.checkout_items'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        12.times do |t|
          if t < 4 # for Japanese fiscal year
            value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1210, :library_id => 0).first.value rescue 0
          else
            value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1210, :library_id => 0).first.value rescue 0
          end
          row.item("value#{t+1}").value(value)
          sum = sum + value
        end  
        row.item("valueall").value(sum)
      end
      3.times do |i|
        report.page.list(:list).add_row do |row|
          row.item(:option).value(t("statistic_report.item_type_#{i+1}"))
          sum = 0
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => "121#{i+7}", :library_id => 0).first.value rescue 0
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => "121#{i+7}", :library_id => 0).first.value rescue 0
            end
            row.item("value#{t+1}").value(value)
            sum = sum + value
          end  
          row.item("valueall").value(sum)
        end
      end
      # checkout items each library
      libraries.each do |library|
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          sum = 0
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1210, :library_id => library.id).first.value rescue 0 
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1210, :library_id => library.id).first.value rescue 0 
            end
            row.item("value#{t+1}").value(value)
            sum = sum + value
          end  
          row.item("valueall").value(sum)
        end
        3.times do |i|
          report.page.list(:list).add_row do |row|
            row.item(:option).value(t("statistic_report.item_type_#{i+1}"))
            sum = 0
            12.times do |t|
              if t < 4 # for Japanese fiscal year
                value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => "121#{i+7}", :library_id => library.id).first.value rescue 0
              else
                value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => "121#{i+7}", :library_id => library.id).first.value rescue 0
              end
              row.item("value#{t+1}").value(value)
              sum = sum + value
            end  
            row.item("valueall").value(sum)
            if library == libraries.last && i == 2
              row.item(:type_line).show
              row.item(:library_line).style(:border_color, '#000000')
              row.item(:library_line).style(:border_width, 1)
              row.item(:option_line).style(:border_color, '#000000')
              row.item(:option_line).style(:border_width, 1)
              row.item(:values_line).style(:border_color, '#000000')
              row.item(:values_line).style(:border_width, 1)
            end  
          end
        end
      end

      # daily average of checkout items all library
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.average_checkout_items'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        12.times do |t|
          if t < 4 # for Japanese fiscal year
            value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1213, :library_id => 0).first.value rescue 0
          else
            value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1213, :library_id => 0).first.value rescue 0
          end
          row.item("value#{t+1}").value(value)
          sum = sum + value
        end  
        row.item("valueall").value(sum/12)
      end
      # daily average of checkout items each library
      libraries.each do |library|
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          sum = 0
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1213, :library_id => library.id).first.value rescue 0 
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1213, :library_id => library.id).first.value rescue 0 
            end
            row.item("value#{t+1}").value(value)
            sum = sum + value
          end  
          row.item("valueall").value(sum/12)
          if library == libraries.last
            row.item(:type_line).show
            row.item(:library_line).style(:border_color, '#000000')
            row.item(:library_line).style(:border_width, 1)
            row.item(:option_line).style(:border_color, '#000000')
            row.item(:option_line).style(:border_width, 1)
            row.item(:values_line).style(:border_color, '#000000')
            row.item(:values_line).style(:border_width, 1)
          end  
        end
      end

      # all users all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.users'))
        row.item(:library).value(t('statistic_report.all_library'))
        row.item(:option).value(t('statistic_report.all_users'))
        12.times do |t|
          if t < 4 # for Japanese fiscal year
            value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1120, :library_id => 0).first.value rescue 0
          else
            value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1120, :library_id => 0).first.value rescue 0
          end
          row.item("value#{t+1}").value(value)
          row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
        end  
      end
      # users each user type[adults, students, children]
      3.times do |i|
        data_type = 112.to_s + (i + 4).to_s
        report.page.list(:list).add_row do |row|
          row.item(:option).value(t("statistic_report.user_type_#{i+1}"))
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => 0).first.value rescue 0
            else	
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => 0).first.value rescue 0
            end
            row.item("value#{t+1}").value(value)
            row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
          end
        end  
      end
      # unlocked users all libraries
      report.page.list(:list).add_row do |row|
        row.item(:option).value(t('statistic_report.unlocked_users'))
        12.times do |t|
          if t < 4 # for Japanese fiscal year
            value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1121, :library_id => 0).first.value rescue 0
          else
            value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1121, :library_id => 0).first.value rescue 0
          end
          row.item("value#{t+1}").value(value)
          row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
        end  
      end
      # locked users all libraries
      report.page.list(:list).add_row do |row|
        row.item(:option).value(t('statistic_report.locked_users'))
        12.times do |t|
          if t < 4 # for Japanese fiscal year
            value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1122, :library_id => 0).first.value rescue 0
          else
            value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1122, :library_id => 0).first.value rescue 0
          end
          row.item("value#{t+1}").value(value)
          row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
        end  
      end

      # users each library
      libraries.each do |library|
        # all users
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          row.item(:option).value(t('statistic_report.all_users'))
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1120, :library_id => library.id).first.value rescue 0 
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1120, :library_id => library.id).first.value rescue 0 
            end
            row.item("value#{t+1}").value(value)
            row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
          end  
        end
        # users each user type[adults, students, children]
        3.times do |i|
          data_type = 112.to_s + (i + 4).to_s
          report.page.list(:list).add_row do |row|
            row.item(:option).value(t("statistic_report.user_type_#{i+1}"))
            12.times do |t|
              if t < 4 # for Japanese fiscal year
                value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => library.id).first.value rescue 0 
              else
                value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => library.id).first.value rescue 0 
              end
              row.item("value#{t+1}").value(value)
              row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
            end
          end  
        end
        # unlocked users
        report.page.list(:list).add_row do |row|
          row.item(:option).value(t('statistic_report.unlocked_users'))
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1121, :library_id => library.id).first.value rescue 0 
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1121, :library_id => library.id).first.value rescue 0 
            end
            row.item("value#{t+1}").value(value)
            row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
          end  
        end
        # locked users
        report.page.list(:list).add_row do |row|
          row.item(:option).value(t('statistic_report.locked_users'))
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1122, :library_id => library.id).first.value rescue 0 
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1122, :library_id => library.id).first.value rescue 0 
            end
            row.item("value#{t+1}").value(value)
            row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
          end  
          if library == libraries.last
            row.item(:type_line).show
            row.item(:library_line).style(:border_color, '#000000')
            row.item(:library_line).style(:border_width, 1)
            row.item(:option_line).style(:border_color, '#000000')
            row.item(:option_line).style(:border_width, 1)
            row.item(:values_line).style(:border_color, '#000000')
            row.item(:values_line).style(:border_width, 1)
          end  
        end
      end

      # reserves all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.reserves'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        12.times do |t|
          if t < 4 # for Japanese fiscal year
            value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1330, :library_id => 0).first.value rescue 0
          else
            value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1330, :library_id => 0).first.value rescue 0
          end
          row.item("value#{t+1}").value(value)
          sum = sum + value
        end  
        row.item("valueall").value(sum)
      end
      # reserves each library
      libraries.each do |library|
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          sum = 0
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1330, :library_id => library.id).first.value rescue 0 
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1330, :library_id => library.id).first.value rescue 0 
            end
            row.item("value#{t+1}").value(value)
            sum = sum + value
          end  
          row.item("valueall").value(sum)
          if library == libraries.last
            row.item(:type_line).show
            row.item(:library_line).style(:border_color, '#000000')
            row.item(:library_line).style(:border_width, 1)
            row.item(:option_line).style(:border_color, '#000000')
            row.item(:option_line).style(:border_width, 1)
            row.item(:values_line).style(:border_color, '#000000')
            row.item(:values_line).style(:border_width, 1)
          end  
        end
      end

      # questions all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.questions'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        12.times do |t|
          if t < 4 # for Japanese fiscal year
            value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1430, :library_id => 0).first.value rescue 0
          else
            value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1430, :library_id => 0).first.value rescue 0
          end
          row.item("value#{t+1}").value(value)
          sum = sum + value
        end  
        row.item("valueall").value(sum)
      end
      # questions each library
      libraries.each do |library|
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          sum = 0
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => 1430, :library_id => library.id).first.value rescue 0 
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => 1430, :library_id => library.id).first.value rescue 0 
            end
            row.item("value#{t+1}").value(value)
            sum = sum + value
          end  
          row.item("valueall").value(sum)
          if library == libraries.last
            row.item(:type_line).show
            row.item(:library_line).style(:border_color, '#000000')
            row.item(:library_line).style(:border_width, 1)
            row.item(:option_line).style(:border_color, '#000000')
            row.item(:option_line).style(:border_width, 1)
            row.item(:values_line).style(:border_color, '#000000')
            row.item(:values_line).style(:border_width, 1)
          end  
        end
      end


      send_data report.generate, :filename => "#{term}_#{configatron.statistic_report.monthly}", :type => 'application/pdf', :disposition => 'attachment'
      return true
    rescue Exception => e
      logger.error "failed #{e}"
      return false
    end	
  end

  def get_daily_report
    term = params[:term]
    unless term =~ /^\d{6}$/ && month_term?(term)
      flash[:message] = t('statistic_report.invalid_month')
      @year = Time.zone.now.years_ago(1).strftime("%Y")
      @month = term
      @t_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @t_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @d_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @d_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @a_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @a_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @items_year = Time.zone.now.years_ago(1).strftime("%Y")
      render :index
      return false
    end
    libraries = Library.all
    logger.error "create daily statistic report: #{term}"

    begin
      report = ThinReports::Report.new :layout => "#{Rails.root.to_s}/app/views/statistic_reports/daily_report"
      report.events.on :page_create do |e|
        e.page.item(:page).value(e.page.no)
      end
      report.events.on :generate do |e|
        e.pages.each do |page|
          page.item(:total).value(e.report.page_count)
        end
      end

      [1,14,27].each do |start_date| # for 3 pages
        report.start_new_page
        report.page.item(:date).value(Time.now)
        report.page.item(:year).value(term[0,4])
        report.page.item(:month).value(term[4,6])        
        # header
        if start_date != 27
          13.times do |t|
            report.page.list(:list).header.item("column##{t+1}").value("#{t+start_date}#{t('statistic_report.date')}")
          end
        else
          5.times do |t|
            report.page.list(:list).header.item("column##{t+1}").value("#{t+start_date}#{t('statistic_report.date')}")
          end
          report.page.list(:list).header.item("column#13").value(t('statistic_report.sum'))
        end
        # checkout users all libraries
        report.page.list(:list).add_row do |row|
          row.item(:type).value(t('statistic_report.checkout_users'))
          row.item(:library).value(t('statistic_report.all_library'))
          if start_date != 27
            13.times do |t|
              value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2220, :library_id => 0).first.value rescue 0
              row.item("value##{t+1}").value(value)
            end
          else
            5.times do |t|
              value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2220, :library_id => 0).first.value rescue 0
              row.item("value##{t+1}").value(value)
            end
            sum = 0
            datas = Statistic.where(:yyyymm => term, :data_type => 2220, :library_id => 0)
            datas.each do |data|
              sum = sum + data.value
            end
            row.item("value#13").value(sum)
          end
        end
        # each user type[all_user, adults, students, children]
        3.times do |type|
          data_type = 222.to_s + (type + 4).to_s
          report.page.list(:list).add_row do |row|
            row.item(:option).value(t("statistic_report.user_type_#{type+1}"))
            if start_date != 27
              13.times do |t|
                value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => data_type, :library_id => 0).first.value rescue 0
                row.item("value##{t+1}").value(value)
              end
            else
              5.times do |t|
                value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => data_type, :library_id => 0).first.value rescue 0
                row.item("value##{t+1}").value(value)
              end
              sum = 0
              datas = Statistic.where(:yyyymm => term, :data_type => data_type, :library_id => 0)
              datas.each do |data|
                sum = sum + data.value
              end
              row.item("value#13").value(sum)
            end
          end
        end
        # checkout users each libraries
        libraries.each do |library|
          report.page.list(:list).add_row do |row|
            row.item(:library).value(library.display_name)
            if start_date != 27
              13.times do |t|
                value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2220, :library_id => library.id).first.value rescue 0
                row.item("value##{t+1}").value(value)
              end
            else
              5.times do |t|
                value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2220, :library_id => 0).first.value rescue 0
                row.item("value##{t+1}").value(value)
              end
              sum = 0
              datas = Statistic.where(:yyyymm => term, :data_type => 2220, :library_id => library.id)
              datas.each do |data|
                sum = sum + data.value
              end
              row.item("value#13").value(sum)
            end
          end
          # each user type[all_user, adults, students, children]
          3.times do |type|
            data_type = 222.to_s + (type+4).to_s
            report.page.list(:list).add_row do |row|
              row.item(:option).value(t("statistic_report.user_type_#{type+1}"))
              if start_date != 27
                13.times do |t|
                  value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => data_type, :library_id => library.id).first.value rescue 0
                  row.item("value##{t+1}").value(value)
                end
              else
                5.times do |t|
                  value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => data_type, :library_id => 0).first.value rescue 0
                  row.item("value##{t+1}").value(value)
                end
                sum = 0
                datas = Statistic.where(:yyyymm => term, :data_type => data_type, :library_id => library.id)
                datas.each do |data|
                  sum = sum + data.value
                end
                row.item("value#13").value(sum)
              end
              if library == libraries.last && type == 2
                row.item(:type_line).show
                row.item(:library_line).style(:border_color, '#000000')
                row.item(:library_line).style(:border_width, 1)
                row.item(:option_line).style(:border_color, '#000000')
                row.item(:option_line).style(:border_width, 1)
                row.item(:values_line).style(:border_color, '#000000')
                row.item(:values_line).style(:border_width, 1)
              end  
            end
          end
        end

        # checkout items all libraries
        report.page.list(:list).add_row do |row|
          row.item(:type).value(t('statistic_report.checkout_items'))
          row.item(:library).value(t('statistic_report.all_library'))
          if start_date != 27
            13.times do |t|
              value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2210, :library_id => 0).first.value rescue 0
              row.item("value##{t+1}").value(value)
            end
          else
            5.times do |t|
              value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2210, :library_id => 0).first.value rescue 0
              row.item("value##{t+1}").value(value)
            end
            sum = 0
            datas = Statistic.where(:yyyymm => term, :data_type => 2210, :library_id => 0)
            datas.each do |data|
              sum = sum + data.value
            end
            row.item("value#13").value(sum)
          end
        end
        3.times do |i|
          report.page.list(:list).add_row do |row|
            row.item(:option).value(t("statistic_report.item_type_#{i+1}"))
            if start_date != 27
              13.times do |t|
                value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => "221#{i+7}", :library_id => 0).first.value rescue 0
                row.item("value##{t+1}").value(value)
              end
            else
              5.times do |t|
                value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => "221#{i+7}", :library_id => 0).first.value rescue 0
                row.item("value##{t+1}").value(value)
              end
              sum = 0
              datas = Statistic.where(:yyyymm => term, :data_type => "221#{i+7}", :library_id => 0)
              datas.each do |data|
                sum = sum + data.value
              end
              row.item("value#13").value(sum)
            end
          end
        end
        
        # checkout items each libraries
        libraries.each do |library|
          report.page.list(:list).add_row do |row|
            row.item(:library).value(library.display_name)
            if start_date != 27
              13.times do |t|
                value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2210, :library_id => library.id).first.value rescue 0
                row.item("value##{t+1}").value(value)
              end
            else
              5.times do |t|
                value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2210, :library_id => library.id).first.value rescue 0
                row.item("value##{t+1}").value(value)
              end
              sum = 0
              datas = Statistic.where(:yyyymm => term, :data_type => 2210, :library_id => library.id)
              datas.each do |data|
                sum = sum + data.value
              end
              row.item("value#13").value(sum)
            end
          end
          3.times do |i|
            report.page.list(:list).add_row do |row|
              row.item(:option).value(t("statistic_report.item_type_#{i+1}"))
              if start_date != 27
                13.times do |t|
                  value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => "221#{i+7}", :library_id => library.id).first.value rescue 0
                  row.item("value##{t+1}").value(value)
                end
              else
                5.times do |t|
                  value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => "221#{i+7}", :library_id => library.id).first.value rescue 0
                  row.item("value##{t+1}").value(value)
                end
                sum = 0
                datas = Statistic.where(:yyyymm => term, :data_type => "221#{i+7}", :library_id => library.id)
                datas.each do |data|
                  sum = sum + data.value
                end
                row.item("value#13").value(sum)
              end
              if library == libraries.last && i == 2
                row.item(:type_line).show
                row.item(:library_line).style(:border_color, '#000000')
                row.item(:library_line).style(:border_width, 1)
                row.item(:option_line).style(:border_color, '#000000')
                row.item(:option_line).style(:border_width, 1)
                row.item(:values_line).style(:border_color, '#000000')
                row.item(:values_line).style(:border_width, 1)
              end  
            end
          end
        end
        # reserves all libraries
        report.page.list(:list).add_row do |row|
          row.item(:type).value(t('statistic_report.reserves'))
          row.item(:library).value(t('statistic_report.all_library'))
          if start_date != 27
            13.times do |t|
              value = Statistic.where(:yyyymm => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2330, :library_id => 0).first.value rescue 0
              row.item("value##{t+1}").value(value)
            end
          else  
            5.times do |t|
              value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2330, :library_id => 0).first.value rescue 0
              row.item("value##{t+1}").value(value)
            end
            sum = 0
            datas = Statistic.where(:yyyymm => term, :data_type => 2330, :library_id => 0)
            datas.each do |data|
              sum = sum + data.value
            end
            row.item("value#13").value(sum)
          end
        end
        # reserves each library
        libraries.each do |library|
          report.page.list(:list).add_row do |row|
            row.item(:library).value(library.display_name)
            if start_date != 27
              13.times do |t|
                value = Statistic.where(:yyyymm => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2330, :library_id => library.id).first.value rescue 0
                row.item("value##{t+1}").value(value)
              end
            else  
              5.times do |t|
                value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2330, :library_id => library.id).first.value rescue 0
                row.item("value##{t+1}").value(value)
              end
              sum = 0
              datas = Statistic.where(:yyyymm => term, :data_type => 2330, :library_id => library.id)
              datas.each do |data|
                sum = sum + data.value
              end
              row.item("value#13").value(sum)
            end
            if library == libraries.last
              row.item(:type_line).show
              row.item(:library_line).style(:border_color, '#000000')
              row.item(:library_line).style(:border_width, 1)
              row.item(:option_line).style(:border_color, '#000000')
              row.item(:option_line).style(:border_width, 1)
              row.item(:values_line).style(:border_color, '#000000')
              row.item(:values_line).style(:border_width, 1)
            end  
          end
        end
        # questions all libraries
        report.page.list(:list).add_row do |row|
          row.item(:type).value(t('statistic_report.questions'))
          row.item(:library).value(t('statistic_report.all_library'))
          if start_date != 27
            13.times do |t|
              value = Statistic.where(:yyyymm => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2430, :library_id => 0).first.value rescue 0
              row.item("value##{t+1}").value(value)
            end  
          else
            5.times do |t|
              value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2430, :library_id => 0).first.value rescue 0
              row.item("value##{t+1}").value(value)
            end
            sum = 0              
            datas = Statistic.where(:yyyymm => term, :data_type => 2430, :library_id => 0)
            datas.each do |data|
              sum = sum + data.value 
            end
            row.item("value#13").value(sum)
          end
        end
        # questions each library
        libraries.each do |library|
          report.page.list(:list).add_row do |row|
            row.item(:library).value(library.display_name)
            if start_date != 27
              13.times do |t|
                value = Statistic.where(:yyyymm => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2430, :library_id => library.id).first.value rescue 0
                row.item("value##{t+1}").value(value)
              end  
            else
              5.times do |t|
                value = Statistic.where(:yyyymmdd => "#{term.to_i}#{"%02d" % (t + start_date)}", :data_type => 2430, :library_id => library.id).first.value rescue 0
                row.item("value##{t+1}").value(value)
              end
              sum = 0
              datas = Statistic.where(:yyyymm => term, :data_type => 2430, :library_id => library.id)
              datas.each do |data|
                sum = sum + data.value
              end
              row.item("value#13").value(sum)
            end
            if library == libraries.last
              row.item(:type_line).show
              row.item(:library_line).style(:border_color, '#000000')
              row.item(:library_line).style(:border_width, 1)
              row.item(:option_line).style(:border_color, '#000000')
              row.item(:option_line).style(:border_width, 1)
              row.item(:values_line).style(:border_color, '#000000')
              row.item(:values_line).style(:border_width, 1)
            end  
          end
        end
      end
      send_data report.generate, :filename => "#{term}_#{configatron.statistic_report.daily}", :type => 'application/pdf', :disposition => 'attachment'
      return true
    rescue Exception => e
      logger.error "failed #{e}"
      return false
    end
  end

  def get_timezone_report
    #default setting 9 - 20
    open = configatron.statistic_report.open
    hours = configatron.statistic_report.hours

    start_at = params[:start_at]
    end_at = params[:end_at]
    end_at = start_at if end_at.empty?
    unless (start_at =~ /^\d{6}$/ && end_at =~ /^\d{6}$/) && start_at.to_i <= end_at.to_i && month_term?(start_at) && month_term?(end_at)
      flash[:message] = t('statistic_report.invalid_month')
      @year = Time.zone.now.months_ago(1).strftime("%Y")
      @month = Time.zone.now.months_ago(1).strftime("%Y%m")
      @t_start_at = start_at
      @t_end_at = end_at
      @d_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @d_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @a_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @a_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @items_year = Time.zone.now.years_ago(1).strftime("%Y")
      render :index
      return false
    end
    libraries = Library.all
    logger.error "create daily timezone report: #{start_at} - #{end_at}"

    begin
      report = ThinReports::Report.new :layout => "#{Rails.root.to_s}/app/views/statistic_reports/timezone_report"
      report.events.on :page_create do |e|
        e.page.item(:page).value(e.page.no)
      end
      report.events.on :generate do |e|
        e.pages.each do |page|
          page.item(:total).value(e.report.page_count)
        end
      end

      report.start_new_page
      report.page.item(:date).value(Time.now)
      report.page.item(:year).value(start_at[0,4])
      report.page.item(:year_start_at).value(start_at[0,4])
      report.page.item(:month_start_at).value(start_at[4,6])
      report.page.item(:year_end_at).value(end_at[0,4])
      report.page.item(:month_end_at).value(end_at[4,6])

      # header 
      12.times do |t|
        report.page.list(:list).header.item("column##{t+1}").value("#{t+open}#{t('statistic_report.hour')}")
      end
      report.page.list(:list).header.item("column#13").value(t('statistic_report.sum'))

      # checkout users all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.checkout_users'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        hours.times do |t|
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 3220 AND library_id = ? AND hour = ?", 0, t+open])
          datas.each do |data|
            value = value + data.value
          end
          sum = sum + value
          row.item("value##{t+1}").value(value)
        end
        row.item("value#13").value(sum)  
      end
      # each user type[all_user, adults, students, children]
      3.times do |type|
        data_type = 322.to_s + (type+4).to_s
        report.page.list(:list).add_row do |row|
          row.item(:option).value(t("statistic_report.user_type_#{type+1}"))
          sum = 0
          hours.times do |t|
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ? AND hour = ?", data_type, 0, t+open])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value##{t+1}").value(value)
          end
          row.item("value#13").value(sum)  
        end
      end
      # checkout users each libraries
      libraries.each do |library|
        sum = 0
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          hours.times do |t|
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 3220 AND library_id = ? AND hour = ?", library.id, t+open])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value##{t+1}").value(value)
          end
          row.item("value#13").value(sum)
        end
        # each user type[all_user, adults, students, children]
        3.times do |type|
          sum = 0
          data_type = 322.to_s + (type+4).to_s
          report.page.list(:list).add_row do |row|
            row.item(:option).value(t("statistic_report.user_type_#{type+1}"))
            hours.times do |t|
              value = 0
              datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ? AND hour = ?", data_type, library.id, t+open])
              datas.each do |data|
                value = value + data.value
              end
              sum = sum + value
              row.item("value##{t+1}").value(value)
            end
            row.item("value#13").value(sum)

            if library == libraries.last && type == 2
              row.item(:type_line).show
              row.item(:library_line).style(:border_color, '#000000')
              row.item(:library_line).style(:border_width, 1)
              row.item(:option_line).style(:border_color, '#000000')
              row.item(:option_line).style(:border_width, 1)
              row.item(:values_line).style(:border_color, '#000000')
              row.item(:values_line).style(:border_width, 1)
            end  
          end
        end
      end

      # checkout items all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.checkout_items'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        hours.times do |t|
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 3210 AND library_id = ? AND hour = ?", 0, t+open])
          datas.each do |data|
            value = value + data.value
          end
          sum = sum + value
          row.item("value##{t+1}").value(value)
        end
        row.item("value#13").value(sum)  
      end
      3.times do |i|
        report.page.list(:list).add_row do |row|
          row.item(:option).value(t("statistic_report.item_type_#{i+1}"))
          sum = 0
          hours.times do |t|
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ? AND hour = ?", "321#{i+7}", 0, t+open])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value##{t+1}").value(value)
          end
          row.item("value#13").value(sum)  
        end
      end
      # checkout items each libraries
      libraries.each do |library|
        sum = 0
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          hours.times do |t|
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 3210 AND library_id = ? AND hour = ?", library.id, t+open])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value##{t+1}").value(value)
          end
          row.item("value#13").value(sum)
        end
        3.times do |i|
          report.page.list(:list).add_row do |row|
            row.item(:option).value(t("statistic_report.item_type_#{i+1}"))
            sum = 0
            hours.times do |t|
              value = 0
              datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ? AND hour = ?", "321#{i+7}", library.id, t+open])
              datas.each do |data|
                value = value + data.value
              end
              sum = sum + value
              row.item("value##{t+1}").value(value)
            end
            row.item("value#13").value(sum)
            if library == libraries.last && i == 2
              row.item(:type_line).show
              row.item(:library_line).style(:border_color, '#000000')
              row.item(:library_line).style(:border_width, 1)
              row.item(:option_line).style(:border_color, '#000000')
              row.item(:option_line).style(:border_width, 1)
              row.item(:values_line).style(:border_color, '#000000')
              row.item(:values_line).style(:border_width, 1)
            end  
          end
        end
      end

      # reserves all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.reserves'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        hours.times do |t|
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 3330 AND library_id = ? AND hour = ?", 0, t+open])
          datas.each do |data|
            value = value + data.value
          end
          sum = sum + value
          row.item("value##{t+1}").value(value)
        end
        row.item("value#13").value(sum)  
      end
      # reserves each libraries
      libraries.each do |library|
        sum = 0
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          hours.times do |t|
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 3330 AND library_id = ? AND hour = ?", library.id, t+open])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value##{t+1}").value(value)
          end
          row.item("value#13").value(sum)
          if library == libraries.last
            row.item(:type_line).show
            row.item(:library_line).style(:border_color, '#000000')
            row.item(:library_line).style(:border_width, 1)
            row.item(:option_line).style(:border_color, '#000000')
            row.item(:option_line).style(:border_width, 1)
            row.item(:values_line).style(:border_color, '#000000')
            row.item(:values_line).style(:border_width, 1)
          end  
        end
      end

      # questions all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.questions'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        hours.times do |t|
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 3430 AND library_id = ? AND hour = ?", 0, t+open])
          datas.each do |data|
            value = value + data.value
          end
          sum = sum + value
          row.item("value##{t+1}").value(value)
        end
        row.item("value#13").value(sum)  
      end
      # reserves each libraries
      libraries.each do |library|
        sum = 0
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          hours.times do |t|
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 3430 AND library_id = ? AND hour = ?", library.id, t+open])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value##{t+1}").value(value)
          end
          row.item("value#13").value(sum)
          if library == libraries.last
            row.item(:type_line).show
            row.item(:library_line).style(:border_color, '#000000')
            row.item(:library_line).style(:border_width, 1)
            row.item(:option_line).style(:border_color, '#000000')
            row.item(:option_line).style(:border_width, 1)
            row.item(:values_line).style(:border_color, '#000000')
            row.item(:values_line).style(:border_width, 1)
          end  
        end
      end

      send_data report.generate, :filename => "#{start_at}_#{end_at}__#{configatron.statistic_report.timezone}", :type => 'application/pdf', :disposition => 'attachment'
      return true
    rescue Exception => e
      logger.error "failed #{e}"
      return false
    end
  end

  def get_day_report
    start_at = params[:start_at]
    end_at = params[:end_at]
    end_at = start_at if end_at.empty?
    unless (start_at =~ /^\d{6}$/ && end_at =~ /^\d{6}$/) && start_at.to_i <= end_at.to_i && month_term?(start_at) && month_term?(end_at)
      flash[:message] = t('statistic_report.invalid_month')
      @year = Time.zone.now.months_ago(1).strftime("%Y")
      @month = Time.zone.now.months_ago(1).strftime("%Y%m")
      @t_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @t_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @d_start_at = start_at
      @d_end_at = end_at
      @a_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @a_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @items_year = Time.zone.now.years_ago(1).strftime("%Y")
      render :index
      return false
    end
    libraries = Library.all
    logger.error "create day statistic report: #{start_at} - #{end_at}"

    begin
      report = ThinReports::Report.new :layout => "#{Rails.root.to_s}/app/views/statistic_reports/day_report"
      report.events.on :page_create do |e|
        e.page.item(:page).value(e.page.no)
      end
      report.events.on :generate do |e|
        e.pages.each do |page|
          page.item(:total).value(e.report.page_count)
        end
      end

      report.start_new_page
      report.page.item(:date).value(Time.now)
      report.page.item(:year).value(start_at[0,4])
      report.page.item(:year_start_at).value(start_at[0,4])
      report.page.item(:month_start_at).value(start_at[4,6])
      report.page.item(:year_end_at).value(end_at[0,4])
      report.page.item(:month_end_at).value(end_at[4,6])

      # checkout users all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.checkout_users'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        7.times do |t|
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 2220 AND library_id = ? AND day = ?", 0, t])
          datas.each do |data|
            value = value + data.value
          end
          sum = sum + value
          row.item("value#{t}").value(value)
        end
        row.item("valueall").value(sum)  
      end
      # each user type[all_user, adults, students, children]
      3.times do |type|
        data_type = 222.to_s + (type + 4).to_s
        report.page.list(:list).add_row do |row|
          row.item(:option).value(t("statistic_report.user_type_#{type+1}"))
          sum = 0
          7.times do |t|
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ? AND day = ?", data_type, 0, t])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value#{t}").value(value)
          end
          row.item("valueall").value(sum)  
        end
      end

      # checkout users each libraries
      libraries.each do |library|
        sum = 0
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          7.times do |t|
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 2220 AND library_id = ? AND day = ?", library.id, t])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value#{t}").value(value)
          end
          row.item("valueall").value(sum)
        end
        # each user type[all_user, adults, students, children]
        3.times do |type|
          sum = 0
          data_type = 222.to_s + (type + 4).to_s
          report.page.list(:list).add_row do |row|
            row.item(:option).value(t("statistic_report.user_type_#{type+1}"))
            7.times do |t|
              value = 0
              datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ? AND day = ?", data_type, library.id, t])
              datas.each do |data|
                value = value + data.value
              end
              sum = sum + value
              row.item("value#{t}").value(value)
            end
            row.item("valueall").value(sum)

            if library == libraries.last && type == 2
              row.item(:type_line).show
              row.item(:library_line).style(:border_color, '#000000')
              row.item(:library_line).style(:border_width, 1)
              row.item(:option_line).style(:border_color, '#000000')
              row.item(:option_line).style(:border_width, 1)
              row.item(:values_line).style(:border_color, '#000000')
              row.item(:values_line).style(:border_width, 1)
            end  
          end
        end
      end

      # checkout items all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.checkout_items'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        7.times do |t|
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 2210 AND library_id = ? AND day = ?", 0, t])
          datas.each do |data|
            value = value + data.value
          end
          sum = sum + value
          row.item("value#{t}").value(value)
        end
        row.item("valueall").value(sum)  
      end
      3.times do |i|
        report.page.list(:list).add_row do |row|
          row.item(:option).value(t("statistic_report.item_type_#{i+1}"))
          sum = 0
          7.times do |t|
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ? AND day = ?", "221#{i+7}", 0, t])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value#{t}").value(value)
          end
          row.item("valueall").value(sum)  
        end
      end
      # checkout items each libraries
      libraries.each do |library|
        sum = 0
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          7.times do |t|
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 2210 AND library_id = ? AND day = ?", library.id, t])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value#{t}").value(value)
          end
          row.item("valueall").value(sum)
        end
        3.times do |i|
          report.page.list(:list).add_row do |row|
            row.item(:option).value(t("statistic_report.item_type_#{i+1}"))
            sum = 0
            7.times do |t|
              value = 0
              datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ? AND day = ?", "221#{i+7}", library.id, t])
              datas.each do |data|
                value = value + data.value
              end
              sum = sum + value
              row.item("value#{t}").value(value)
            end
            row.item("valueall").value(sum)
            if library == libraries.last && i == 2
              row.item(:type_line).show
              row.item(:library_line).style(:border_color, '#000000')
              row.item(:library_line).style(:border_width, 1)
              row.item(:option_line).style(:border_color, '#000000')
              row.item(:option_line).style(:border_width, 1)
              row.item(:values_line).style(:border_color, '#000000')
              row.item(:values_line).style(:border_width, 1)
            end  
          end
        end
      end

      # reserves all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.reserves'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        7.times do |t|
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 2330 AND library_id = ? AND day = ?", 0, t])
          datas.each do |data|
            value = value + data.value
          end
          sum = sum + value
          row.item("value#{t}").value(value)
        end
        row.item("valueall").value(sum)  
      end
      # reserves each libraries
      libraries.each do |library|
        sum = 0
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          7.times do |t|
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 2330 AND library_id = ? AND day = ?", library.id, t])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value#{t}").value(value)
          end
          row.item("valueall").value(sum)
          if library == libraries.last
            row.item(:type_line).show
            row.item(:library_line).style(:border_color, '#000000')
            row.item(:library_line).style(:border_width, 1)
            row.item(:option_line).style(:border_color, '#000000')
            row.item(:option_line).style(:border_width, 1)
            row.item(:values_line).style(:border_color, '#000000')
            row.item(:values_line).style(:border_width, 1)
          end  
        end
      end

      # questions all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.questions'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        7.times do |t|
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 2430 AND library_id = ? AND day = ?", 0, t])
          datas.each do |data|
            value = value + data.value
          end
          sum = sum + value
          row.item("value#{t}").value(value)
        end
        row.item("valueall").value(sum)  
      end
      # questions each libraries
      libraries.each do |library|
        sum = 0
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          7.times do |t|
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = 2430 AND library_id = ? AND day = ?", library.id, t])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value#{t}").value(value)
          end
          row.item("valueall").value(sum)
          if library == libraries.last
            row.item(:type_line).show
            row.item(:library_line).style(:border_color, '#000000')
            row.item(:library_line).style(:border_width, 1)
            row.item(:option_line).style(:border_color, '#000000')
            row.item(:option_line).style(:border_width, 1)
            row.item(:values_line).style(:border_color, '#000000')
            row.item(:values_line).style(:border_width, 1)
          end  
        end
      end


      send_data report.generate, :filename => "#{start_at}_#{end_at}_#{configatron.statistic_report.day}", :type => 'application/pdf', :disposition => 'attachment'
      return true
    rescue Exception => e
      logger.error "failed #{e}"
      return false
    end
  end

  def get_age_report
    start_at = params[:start_at]
    end_at = params[:end_at]
    end_at = start_at if end_at.empty?
    unless (start_at =~ /^\d{6}$/ && end_at =~ /^\d{6}$/) && start_at.to_i <= end_at.to_i && month_term?(start_at) && month_term?(end_at)
      flash[:message] = t('statistic_report.invalid_month')
      @year = Time.zone.now.months_ago(1).strftime("%Y")
      @month = Time.zone.now.months_ago(1).strftime("%Y%m")
      @t_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @t_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @d_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @d_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @a_start_at = start_at
      @a_end_at = end_at
      @items_year = Time.zone.now.years_ago(1).strftime("%Y")
      render :index
      return false
    end
    libraries = Library.all
    logger.error "create day statistic report: #{start_at} - #{end_at}"

    begin
      report = ThinReports::Report.new :layout => "#{Rails.root.to_s}/app/views/statistic_reports/age_report"
      report.events.on :page_create do |e|
        e.page.item(:page).value(e.page.no)
      end
      report.events.on :generate do |e|
        e.pages.each do |page|
          page.item(:total).value(e.report.page_count)
        end
      end

      report.start_new_page
      report.page.item(:date).value(Time.now)
      report.page.item(:year).value(start_at[0,4])
      report.page.item(:year_start_at).value(start_at[0,4])
      report.page.item(:month_start_at).value(start_at[4,6])
      report.page.item(:year_end_at).value(end_at[0,4])
      report.page.item(:month_end_at).value(end_at[4,6])

      # checkout users all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.checkout_users'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        8.times do |t|
          data_type = 1220.to_s + t.to_s
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, 0])
          datas.each do |data|
            value = value + data.value
          end
          sum = sum + value
          row.item("value#{t}").value(value)
        end
        row.item("valueall").value(sum)  
      end
      # checkout users each libraries
      libraries.each do |library|
        sum = 0
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          8.times do |t|
            data_type = 1220.to_s + t.to_s
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, library.id])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value#{t}").value(value)
          end
          row.item("valueall").value(sum)
          if library == libraries.last
            row.item(:type_line).show
            row.item(:library_line).style(:border_color, '#000000')
            row.item(:library_line).style(:border_width, 1)
            row.item(:option_line).style(:border_color, '#000000')
            row.item(:option_line).style(:border_width, 1)
            row.item(:values_line).style(:border_color, '#000000')
            row.item(:values_line).style(:border_width, 1)
          end  
        end
      end

      # checkout items all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.checkout_items'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        8.times do |t|
          data_type = 1210.to_s + t.to_s
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, 0])
          datas.each do |data|
            value = value + data.value
          end
          sum = sum + value
          row.item("value#{t}").value(value)
        end
        row.item("valueall").value(sum)  
      end
      3.times do |i|
        report.page.list(:list).add_row do |row|
          row.item(:option).value(t("statistic_report.item_type_#{i+1}"))
          sum = 0
          8.times do |t|
            data_type = 121.to_s + (i+7).to_s + t.to_s
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, 0])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value#{t}").value(value)
          end
          row.item("valueall").value(sum)  
        end
      end
      # checkout items each libraries
      libraries.each do |library|
        sum = 0
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          8.times do |t|
            data_type = 1210.to_s + t.to_s
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, library.id])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value#{t}").value(value)
          end
          row.item("valueall").value(sum)
        end
        3.times do |i|
          report.page.list(:list).add_row do |row|
            row.item(:option).value(t("statistic_report.item_type_#{i+1}"))
            sum = 0
            8.times do |t|
              data_type = 121.to_s + (i+7).to_s + t.to_s
              value = 0
              datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, library.id])
              datas.each do |data|
                value = value + data.value
              end
              sum = sum + value
              row.item("value#{t}").value(value)
            end
            row.item("valueall").value(sum)
            if library == libraries.last && i == 2
              row.item(:type_line).show
              row.item(:library_line).style(:border_color, '#000000')
              row.item(:library_line).style(:border_width, 1)
              row.item(:option_line).style(:border_color, '#000000')
              row.item(:option_line).style(:border_width, 1)
              row.item(:values_line).style(:border_color, '#000000')
              row.item(:values_line).style(:border_width, 1)
            end
          end  
        end
      end

      # all users all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.users'))
        row.item(:library).value(t('statistic_report.all_library'))
        row.item(:option).value(t('statistic_report.all_users'))
        sum = 0
        8.times do |t|
          data_type = 1120.to_s + t.to_s
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, 0])
          datas.each do |data|
            value = value + data.value
          end
          sum = sum + value
          row.item("value#{t}").value(value)
        end  
        row.item("valueall").value(sum)
      end
      # unlocked users all libraries
      report.page.list(:list).add_row do |row|
        row.item(:option).value(t('statistic_report.unlocked_users'))
        sum = 0
        8.times do |t|
          data_type = 1121.to_s + t.to_s
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, 0])
          datas.each do |data|
            value =value + data.value
          end
          sum = sum + value
          row.item("value#{t}").value(value)
        end  
        row.item("valueall").value(sum)
      end
      # locked users all libraries
      report.page.list(:list).add_row do |row|
        row.item(:option).value(t('statistic_report.locked_users'))
        sum = 0
        8.times do |t|
          data_type = 1122.to_s + t.to_s
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, 0])
          datas.each do |data|
            value =value + data.value
          end
          sum = sum + value
          row.item("value#{t}").value(value)
        end  
        row.item("valueall").value(sum)
      end
      # users each libraries
      libraries.each do |library|
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name.localize)
          sum = 0
          8.times do |t|
            data_type = 1120.to_s + t.to_s
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, library.id])
            datas.each do |data|
              value =value + data.value
            end
            sum = sum + value
            row.item("value#{t}").value(value)
          end  
          row.item("valueall").value(sum)
        end
        # unlocked users each libraries
        report.page.list(:list).add_row do |row|
          row.item(:option).value(t('statistic_report.unlocked_users'))
          sum = 0
          8.times do |t|
            data_type = 1121.to_s + t.to_s
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, library.id])
            datas.each do |data|
              value =value + data.value
            end
            sum = sum + value
            row.item("value#{t}").value(value)
          end    
          row.item("valueall").value(sum)
        end
        # locked users each libraries
        report.page.list(:list).add_row do |row|
          row.item(:option).value(t('statistic_report.locked_users'))
          sum = 0
          8.times do |t|
            data_type = 1122.to_s + t.to_s
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, library.id])
            datas.each do |data|
              value =value + data.value
            end
            sum = sum + value
            row.item("value#{t}").value(value)
          end  
          row.item("valueall").value(sum)
          if library == libraries.last
            row.item(:type_line).show
            row.item(:library_line).style(:border_color, '#000000')
            row.item(:library_line).style(:border_width, 1)
            row.item(:option_line).style(:border_color, '#000000')
            row.item(:option_line).style(:border_width, 1)
            row.item(:values_line).style(:border_color, '#000000')
            row.item(:values_line).style(:border_width, 1)
          end  
        end
      end

      # reserves all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.reserves'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        8.times do |t|
          data_type = 1330.to_s + t.to_s
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, 0])
          datas.each do |data|
            value = value + data.value
          end
          sum = sum + value
          row.item("value#{t}").value(value)
        end
        row.item("valueall").value(sum)  
      end
      # reserves each libraries
      libraries.each do |library|
        sum = 0
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          8.times do |t|
            data_type = 1330.to_s + t.to_s
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, library.id])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value#{t}").value(value)
          end
          row.item("valueall").value(sum)
          if library == libraries.last
            row.item(:type_line).show
            row.item(:library_line).style(:border_color, '#000000')
            row.item(:library_line).style(:border_width, 1)
            row.item(:option_line).style(:border_color, '#000000')
            row.item(:option_line).style(:border_width, 1)
            row.item(:values_line).style(:border_color, '#000000')
            row.item(:values_line).style(:border_width, 1)
          end  
        end
      end

      # questions all libraries
      report.page.list(:list).add_row do |row|
        row.item(:type).value(t('statistic_report.questions'))
        row.item(:library).value(t('statistic_report.all_library'))
        sum = 0
        8.times do |t|
          data_type = 1430.to_s + t.to_s
          value = 0
          datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, 0])
          datas.each do |data|
            value = value + data.value
          end
          sum = sum + value
          row.item("value#{t}").value(value)
        end
        row.item("valueall").value(sum)  
      end
      # questions each libraries
      libraries.each do |library|
        sum = 0
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          8.times do |t|
            data_type = 1430.to_s + t.to_s
            value = 0
            datas = Statistic.where(["yyyymm >= #{start_at} AND yyyymm <= #{end_at} AND data_type = ? AND library_id = ?", data_type, library.id])
            datas.each do |data|
              value = value + data.value
            end
            sum = sum + value
            row.item("value#{t}").value(value)
          end
          row.item("valueall").value(sum)
          if library == libraries.last
            row.item(:type_line).show
            row.item(:library_line).style(:border_color, '#000000')
            row.item(:library_line).style(:border_width, 1)
            row.item(:option_line).style(:border_color, '#000000')
            row.item(:option_line).style(:border_width, 1)
            row.item(:values_line).style(:border_color, '#000000')
            row.item(:values_line).style(:border_width, 1)
          end  
        end
      end

      send_data report.generate, :filename => "#{start_at}_#{end_at}_#{configatron.statistic_report.age}", :type => 'application/pdf', :disposition => 'attachment'
      return true
    rescue Exception => e
      logger.error "failed #{e}"
      return false
    end
  end

  def get_items_report
    term = params[:term]
    unless term =~ /^\d{4}$/
      flash[:message] = t('statistic_report.invalid_year')
      @year = term
      @month = Time.zone.now.months_ago(1).strftime("%Y%m")
      @t_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @t_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @d_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @d_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @a_start_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @a_end_at = Time.zone.now.months_ago(1).strftime("%Y%m")
      @items_year = term
      render :index
      return false
    end
    libraries = Library.all
    checkout_types = CheckoutType.all
    call_numbers = Statistic.call_numbers
    begin 
      report = ThinReports::Report.new :layout => "#{Rails.root.to_s}/app/views/statistic_reports/items_report"

      report.events.on :page_create do |e|
        e.page.item(:page).value(e.page.no)
      end
      report.events.on :generate do |e|
        e.pages.each do |page|
          page.item(:total).value(e.report.page_count)
        end
      end

      report.start_new_page
      report.page.item(:date).value(Time.now)       
      report.page.item(:term).value(term)

      # items all libraries
      data_type = 111
      report.page.list(:list).add_row do |row|
        row.item(:library).value(t('statistic_report.all_library'))
        12.times do |t|
          if t < 4 # for Japanese fiscal year
            value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => 0).no_condition.first.value rescue 0
          else
            value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => 0).no_condition.first.value rescue 0
          end
          row.item("value#{t+1}").value(value)
          row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
          row.item("condition_line").show
        end  
      end
      # items each call_numbers
      call_numbers.each do |num|
        report.page.list(:list).add_row do |row|
          row.item(:condition).value(t('activerecord.attributes.item.call_number')) if num == call_numbers.first 
          row.item(:option).value(num)
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => 0, :call_number => num).first.value rescue 0
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => 0, :call_number => num).first.value rescue 0
            end
            row.item("value#{t+1}").value(value)
            row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
            row.item("condition_line").show if num == call_numbers.last
          end  
        end
      end
      # items each checkout_types
      checkout_types.each do |checkout_type|
        report.page.list(:list).add_row do |row|
          row.item(:condition).value(t('activerecord.models.checkout_type')) if checkout_type == checkout_types.first 
          row.item(:option).value(checkout_type.display_name.localize)
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => 0, :checkout_type_id => checkout_type.id).first.value rescue 0
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => 0, :checkout_type_id => checkout_type.id).first.value rescue 0
            end
            row.item("value#{t+1}").value(value)
            row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
            line_for_items(row) if checkout_type == checkout_types.last
          end  
        end
      end
      # items each library
      libraries.each do |library|
        report.page.list(:list).add_row do |row|
          row.item(:library).value(library.display_name)
          12.times do |t|
            if t < 4 # for Japanese fiscal year
              value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => library.id).no_condition.first.value rescue 0 
            else
              value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => library.id).no_condition.first.value rescue 0 
            end
            row.item("value#{t+1}").value(value)
            row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
            row.item("condition_line").show
          end  
        end
        # items each call_numbers
        call_numbers.each do |num|
          report.page.list(:list).add_row do |row|
            row.item(:condition).value(t('activerecord.attributes.item.call_number')) if num == call_numbers.first 
            row.item(:option).value(num)
            12.times do |t|
              if t < 4 # for Japanese fiscal year
                value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => library.id, :call_number => num).first.value rescue 0
              else
                value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => library.id, :call_number => num).first.value rescue 0
              end
              row.item("value#{t+1}").value(value)
              row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
              row.item("condition_line").show if num == call_numbers.last
            end
          end
        end
        # items each checkout_types
        checkout_types.each do |checkout_type|
          report.page.list(:list).add_row do |row|
            row.item(:condition).value(t('activerecord.models.checkout_type')) if checkout_type == checkout_types.first 
            row.item(:option).value(checkout_type.display_name.localize)
            12.times do |t|
              if t < 4 # for Japanese fiscal year
                value = Statistic.where(:yyyymm => "#{term.to_i + 1}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => library.id, :checkout_type_id => checkout_type.id).first.value rescue 0
              else
                value = Statistic.where(:yyyymm => "#{term}#{"%02d" % (t + 1)}", :data_type => data_type, :library_id => library.id, :checkout_type_id => checkout_type.id).first.value rescue 0
              end
              row.item("value#{t+1}").value(value)
              row.item("valueall").value(value) if t == 2 # March(end of fiscal year)
              line_for_items(row) if checkout_type == checkout_types.last
            end
          end
        end
      end

      send_data report.generate, :filename => "#{term}_#{configatron.statistic_report.items}", :type => 'application/pdf', :disposition => 'attachment'
      return true
    rescue Exception => e
      logger.error "failed #{e}"
      return false
    end

  end

private
  def line_for_items(row)
    row.item(:library_line).show
    row.item(:condition_line).show
    row.item(:condition_line).style(:border_color, '#000000')
    row.item(:condition_line).style(:border_width, 1)
    row.item(:option_line).style(:border_color, '#000000')
    row.item(:option_line).style(:border_width, 1)
    row.item(:values_line).style(:border_color, '#000000')
    row.item(:values_line).style(:border_width, 1)
  end

  def month_term?(term)
    begin 
      Time.parse("#{term}01")
      return true
    rescue ArgumentError
      return false
    end
  end
end
