class LocalesController < ActionController::Base
  prepend_view_path(File.join(File.dirname(__FILE__), "..", "views"))
  # GET /locales
  # GET /locales.xml
  def index
    @locales = I18n::Backend::Locale.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @locales }
    end
  end

  # GET /locales/1
  # GET /locales/1.xml
  def show
    @locale = I18n::Backend::Locale.find_by_code(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @locale }
    end
  end

  # GET /locales/new
  # GET /locales/new.xml
  def new
    @locale = I18n::Backend::Locale.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @locale }
    end
  end

  # GET /locales/1/edit
  def edit
    @locale = I18n::Backend::Locale.find_by_code(params[:id])
  end

  # POST /locales
  # POST /locales.xml
  def create
    @locale = I18n::Backend::Locale.new(params[:locale])
    respond_to do |format|
      if @locale.save
        flash[:notice] = 'Locale was successfully created.'
        format.html { redirect_to(@locale) }
        format.xml  { render :xml => @locale, :status => :created, :location => @locale }
      else
        flash[:error] = @locale.errors.to_a
        format.html { render :action => "new" }
        format.xml  { render :xml => @locale.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /locales/1
  # PUT /locales/1.xml
  def update
    @locale = I18n::Backend::Locale.find_by_code(params[:id])
    respond_to do |format|
      if @locale.update_attributes(params[:locale])
        flash[:notice] = 'Locale was successfully updated.'
        format.html { redirect_to(@locale) }
        format.xml  { head :ok }
      else
        flash[:error] = @locale.errors.to_a
        format.html { render :action => "edit" }
        format.xml  { render :xml => @locale.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /locales/1
  # DELETE /locales/1.xml
  def destroy
    @locale = I18n::Backend::Locale.find_by_code(params[:id])
    @locale.destroy
    respond_to do |format|
      format.html { redirect_to(locales_url) }
      format.xml  { head :ok }
    end
  end
end
