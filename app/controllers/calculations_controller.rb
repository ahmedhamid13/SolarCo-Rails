class CalculationsController < ApplicationController
  before_action :set_calculation, only: [:show, :update, :destroy]

  # GET /calculations
  def index
    @calculation = Calculation.ApplicationController

    render json: @calculations
  end

  # GET /calculations/1
  def show
    render json: @calculation
  end

  # POST /calculations
  def create
    # puts params[:_json]
    consumption = params[:consump];

    if params[:lat] && params[:long]
      res_loc = (Geocoder.search([params[:lat].to_f, params[:long].to_f])[0].data).to_hash
      lat = params[:lat].to_f
      long = params[:long].to_f
      @system = System.create(latitude: lat, longitude: long, consumption: consumption, city: res_loc['region'],country: res_loc['country'],road: res_loc['address']['road'], neighbourhood: res_loc['address']['neighbourhood'], hamlet: res_loc['address']['hamlet'], user_id: 1)
    else
      res_ip = (Geocoder.search(params[:ip])[0].data).to_hash
      loc = res_ip['loc'].split(',') unless res_ip['loc'].nil?
      lat = loc[0].to_f
      long = loc[1].to_f
      @system = System.create(latitude: lat, longitude: long, consumption: consumption, city: res_ip['region'],country: res_ip['country'], user_id: 1)
    end

    @calculation = Calculation.new()
    panel = @calculation.panel_Calculate(consumption, lat)
    battery = @calculation.battery_Calculate(panel['wh_per_day'], lat)
    componets = @calculation.inverter_mppt_Calculate()
    position = @calculation.position_Calculate(lat, long)
    
    @calculation = Calculation.create(system_id: @system.id, system_circuits: componets['inverters_num'], panels_num: panel['panels_num'], panel_watt: panel['panel_watt'], battery_Ah: battery['battery_Ah'], batteries_num: battery['batteries_num'], inverter_watt: componets['inverter_watt'], mppt_amp: componets['mppt_amp'])
    
    cables_protections = @calculation.cables_protections_Calculate(@calculation)

    @cal = {"res" => {"panel" => panel, "battery" => battery, "componets" => componets, "cables_protections" => cables_protections, "Installations" => position}, "sys" => @system, "calc" => @calculation}

    render json: @cal 
  end

  # PATCH/PUT /calculations/1
  def update
    if @calculation.update(calculation_params)
      render json: @calculation
    else
      render json: @calculation.errors, status: :unprocessable_entity
    end
  end

  # DELETE /calculations/1
  def destroy
    @calculation.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_calculation
      @calculation = Calculation.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def calculation_params
      params.fetch(:ip, :lat, :long, :consump)
    end

end
