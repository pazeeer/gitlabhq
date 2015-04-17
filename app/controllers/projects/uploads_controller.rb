class Projects::UploadsController < Projects::ApplicationController
  layout 'project'

  skip_before_filter :authenticate_user!, :reject_blocked!, :project, :repository, only: [:show]
  before_filter :authenticate_user!, :reject_blocked!, :project, :repository, only: [:show], unless: :image?

  def create
    link_to_file = ::Projects::UploadService.new(project, params[:file]).
      execute

    respond_to do |format|
      if link_to_file
        format.json do
          render json: { link: link_to_file }
        end
      else
        format.json do
          render json: 'Invalid file.', status: :unprocessable_entity
        end
      end
    end
  end

  def show
    return not_found! if uploader.nil? || !uploader.file.exists?

    disposition = uploader.image? ? 'inline' : 'attachment'
    send_file uploader.file.path, disposition: disposition
  end

  def uploader
    return @uploader if defined?(@uploader)

    namespace = params[:namespace_id]
    id = params[:project_id]

    file_project = Project.find_with_namespace("#{namespace}/#{id}")

    if file_project.nil?
      @uploader = nil 
      return
    end

    @uploader = FileUploader.new(file_project, params[:secret])
    @uploader.retrieve_from_store!(params[:filename])

    @uploader
  end

  def image?
    uploader && uploader.file.exists? && uploader.image?
  end
end
