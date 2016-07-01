class MatchesController < ActionController::Base
  layout 'application'

  before_action :authenticate_user!, except: [:show, :index, :match_info]
  before_action -> { establish_match_entities Match.find(params[:id]) },
                only: [:show, :match_info]

  def index
    matches = Match.all
    @matches = matches.decorate

    respond_to do |format|
      format.html
      format.json { render json: @matches }
    end
  end

  def show
    match = Match.find(params[:id])
    @match = match.decorate

    @match_token = MatchToken.from_user_and_match(current_user, params[:id]) \
    if current_user && current_user.in_match?(@match.id)
    (@rating_change = Team.rating_change(@blue_team_avg, @red_team_avg)) \
    if @match.teams.any?

    respond_to do |format|
      format.html
      format.json { render json: @match }
    end
  end

  def match_info
    match = Match.find(params[:id])
    @match = match.decorate

    @new_players_count = MatchToken.created_recently match

    respond_to do |format|
      format.js { render layout: false }
    end
  end

  def new
    @match = Match.new

    respond_to do |format|
      format.html
    end
  end

  def edit
    @match = Match.find(params[:id])
    if current_user && current_user.match_tokens.exists?(match_id: @match.id)
      @players = @match.users
      @blue_team = @match.teams.first
      @red_team = @match.teams.last
    else
      redirect_to root_path
    end
  end

  def create
    @match = Match.new(match_params)
    @match.creator_id = current_user.id

    respond_to do |format|
      if @match.save
        flash[:success] = 'La partida se creó correctamente.'
        format.html { redirect_to match_path(@match.id) }
      else
        format.html { render 'new' }
      end
    end
  end

  def update
    @match = Match.find(params[:id])

    respond_to do |format|
      if @match.update_attributes(params[:match])
        flash[:success] =  'La partida se guardó correctamente.'
        redirect_to @match
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    @match = Match.find(params[:id])
    @match.match_tokens.destroy_all
    @match.status = 'canceled'
    @match.save

    respond_to do |format|
      format.html { redirect_to matches_url }
    end
  end

  def leave
    match = Match.find(params[:id])
    if match.leavable?
      if current_user && current_user.match_tokens.exists?(match_id: match.id)
        current_user.leave_match(match)
        flash[:success] = 'Usted salió de la partida.'
      else
        flash[:error] = 'Usted no puede salir de esta partida, no está registrado en ella.'
      end
    else
      flash[:error] = 'La partida se está jugando, usted no puede salir de ella.'
    end
    redirect_to match_path(match)
  end

  def join
    @match = Match.find(params[:id])
    redirect_to user_omniauth_authorize_path(:facebook) if current_user.unjoinable?

    if @match.joinable? && current_user.joinable?
      match_token = MatchToken.new(user_id: current_user.id, match_id: params[:id])
    else
      flash[:error] =  'Usted se encuentra en una partida activa (o no ha autenticado con Facebook).'
      redirect_to match_path(@match)
    end

    match_token.save!

    if @match.start
      flash[:success] =  'La partida se completó contigo, suerte!'
    else
      flash[:success] =  'Usted entró a la partida!'
    end
    redirect_to match_path(@match)
  end

  # TODO: @truenito simplify, refactor, DRY up.
  def establish_match_entities(match)
    @creator = User.find(match.creator_id)
    @blue_team = match.teams.first
    @blue_captain_id = @blue_team.captain_id if match.teams.any?
    @red_team = match.teams.last
    @red_captain_id = @red_team.captain_id if match.teams.any?
    players = match.users.order('match_tokens.created_at ASC')
    @players = players.decorate
    frozen_users_and_stats(match) if match.ended? && !match.users_and_stats.nil?

    return true if @blue_team.nil?
    if match.ended? && match.users_and_stats.present?
      @blue_team_avg = Team.rating_average @blue_team, match
      @red_team_avg = Team.rating_average @red_team, match
    else
      @blue_team_avg = (@blue_team.users.sum(:rating) / @blue_team.users.count)
      @red_team_avg = (@red_team.users.sum(:rating) / @red_team.users.count)
    end
  end

  def frozen_users_and_stats(match)
    blue_team_str_ids = @blue_team.users.pluck(:id).map!(&:to_s)
    @blue_team = match.users_and_stats.select { |u| blue_team_str_ids.include? u['id'] }

    red_team_str_ids = @red_team.users.pluck(:id).map!(&:to_s)
    @red_team = match.users_and_stats.select { |u| red_team_str_ids.include? u['id'] }
  end

  private

  def match_params
    params.require(:match).permit(:name, :password)
  end
end
