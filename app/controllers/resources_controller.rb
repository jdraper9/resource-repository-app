class ResourcesController < ApplicationController

  include SessionsHelper

  def index
    if current_user.role == 'teacher'
      @resources = Resource.joins("LEFT JOIN favorites ON resources.id = favorites.resource_id").group("resources.id").order("count(favorites.resource_id) desc")
    else
      @resources = Resource.joins("LEFT JOIN favorites ON resources.id = favorites.resource_id").group("resources.id").order("count(favorites.resource_id) desc").to_a.reject do |resource| 
        resource.tags.select{|tag| tag.name == 'teacher only'}.length > 0
      end
    end
  end

  def create
    @resource = Resource.new(resource_params)
    @resource.creator_id = current_user.id

    respond_to do |format|
     if @resource.save
        # tags
        if params[:resource][:tags]
          input_tags = params[:resource][:tags].split(',')
          input_tags.each do |input_tag|
            input_tag.downcase!
            input_tag.strip!
            # create tag if not found in database
            Tag.create(name: input_tag) if !Tag.find_by(name: input_tag)

            #create resource_tag object in db for every tag associated with resource
            tag_obj = Tag.find_by(name: input_tag)
            ResourceTag.create(resource_id: @resource.id, tag_id: tag_obj.id) if !ResourceTag.find_by(resource_id: @resource.id, tag_id: tag_obj.id)
          end
        end

       format.html { redirect_to @resource, notice: 'Resource was successfully created.' }
       format.json { render :show, status: :created, location: @resource }
     else
       format.html { render :new }
       format.json { render json: @resource.errors, status: :unprocessable_entity }
     end
   end
  end

  def new
    @resource = Resource.new
  end

  def show
    @resource = Resource.find(params[:id])
    @tags = @resource.tags
    p @tags
  end

  def search
    @resources = Resource.all
    @tags = Tag.all
    @q = params[:q]

    @tag = @tags.include?(@q)

    render :index
  end

  private
  def resource_params
    params.require(:resource).permit(:title, :url)
  end
end
