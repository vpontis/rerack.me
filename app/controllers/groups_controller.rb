class GroupsController < ApplicationController
  before_filter :set_group, only: [:show, :update, :edit, :add_player, :destroy]
  authorize_resource

  def index
    @groups = Group.accessible_by(current_ability)
    @player = current_player
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    @group.admin = current_player
    @group.players << current_player

    respond_to do |format|
      if @group.save
        format.html { redirect_to group_path(@group) }
        format.json { render action: 'show', status: :created, location: @group }
      else
        format.html { render action: 'new' }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  def add_player
    username = params[:username]

    respond_to do |format|
      if @group.add_player_by_username(username)
        format.html { redirect_to @group, notice: 'Player successfully added to group.' }
        format.json { head :no_content }
      else
        format.html { redirect_to @group, notice: @group.errors.full_messages.first }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @group.update(group_params)
      redirect_to group_path(@group), notice: 'Group was successfully updated.'  
    else
      render action: 'edit' 
    end
  end

  def show
    @players = @group.ranked_players
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group.destroy
    respond_to do |format|
      format.html { redirect_to :root }
      format.json { head :no_content }
    end
  end

  private
    def group_params
      params.require(:group).permit(:name, :image)
    end

    def set_group
      @group = Group.find(params[:id])
    end
end 
