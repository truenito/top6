class MatchTokensController < ActionController::Base
  layout 'application'
  before_action :authenticate_user!

  def edit
    @match_token = MatchToken.find params[:id]
    match = Match.find @match_token.match_id

    if current_user.in_match? match.id
      @match = match.decorate
      establish_match_entities @match
    else
      flash[:error] = 'Usted no está jugando esta partida.'
      redirect_to home_path
    end
  end

  def update
    if MatchToken.exists?(id: params[:id])
      @match_token = MatchToken.find params[:id]
      @match = @match_token.match
      respond_to do |format|
        if @match.status == 'playing'
          if @match_token.update_attributes match_token_params
            @match.commit
            flash[:success] = 'Su voto fué procesado.'
            format.html { redirect_to edit_match_token_path @match_token }
          else
            flash[:error] = 'Hubo un error procesando su voto, contacte administración.'
            format.html { redirect_to edit_match_token_path @match_token }
          end
        else
          flash[:success] = 'La partida ya tiene los votos suficientes, gracias!'
          format.html { redirect_to matches_path }
        end
      end
    else
      flash[:error] = 'Este match ya fué cancelado.'
      redirect_to root_path
    end
  end

  def establish_match_entities(match)
    @players = match.users.decorate
    @blue_team = match.teams.first
    @red_team = match.teams.last
    @blue_teamvg = @blue_team.users.sum(:rating) / 5
    @red_teamvg = @red_team.users.sum(:rating) / 5
  end

  private

  def match_token_params
    params.require(:match_token).permit(:result)
  end
end
