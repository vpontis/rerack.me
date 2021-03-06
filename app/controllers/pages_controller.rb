class PagesController < ApplicationController
  def dashboard
    unless current_player
      redirect_to player_session_path
    end

    @games_to_confirm = current_player.games_to_confirm
    @pending_games = current_player.pending_games

    @recent_games = Game.all.where(confirmed: true).order("created_at DESC").limit(20)
  end
end
