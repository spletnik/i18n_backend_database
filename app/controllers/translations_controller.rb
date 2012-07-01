class TranslationsController < ActionController::Base

  layout 'translations'
  before_filter :find_locale

  helper_method :translation_stats,:check_for_missing_params

  ## FIXME:  you'll probably want add authorization to this controller!

  # GET /translations
  # GET /translations.xml
  def index
    @translations = @locale.translations.find(:all, :order => "raw_key, pluralization_index")
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @translations }
    end
  end

  # GET /translations
  # GET /translations.xml
  def translations
    session[:translation_option] = params[:translation_option] if params[:translation_option]
    session[:show_keys] = params[:show_keys] if params[:show_keys]
    @translation_option = TranslationOption.find(session[:translation_option])
    case @translation_option
      when TranslationOption.translated
        @translations = @locale.translations.translated
      when TranslationOption.unsourced
        @translations = @locale.translations.unsourced
      else
        @translations = @locale.translations.untranslated
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @translations }
    end
  end

  # GET /asset_translations
  # GET /asset_translations.xml
  def asset_translations
    @locale ||= I18n::Backend::Locale.default_locale
    @translation_option = TranslationOption.find(params[:translation_option])
    @asset_translations  = I18n.asset_translations
    @untranslated_assets = I18n.untranslated_assets(@locale.code)
    @percentage_translated = (((@asset_translations.size - @untranslated_assets.size).to_f / @asset_translations.size.to_f * 100).round) rescue 0
    case @translation_option
      when TranslationOption.translated
        @asset_translations = @asset_translations.reject{|e| @untranslated_assets.include?(e)}
      else
        @asset_translations = @untranslated_assets
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @untranslated_assets }
    end
  end

  # GET /translations/1
  # GET /translations/1.xml
  def show
    @translation = @locale.translations.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @translation }
    end
  end

  # GET /translations/new
  # GET /translations/new.xml
  def new
    @translation = Translation.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @translation }
    end
  end

  # GET /translations/1/edit
  def edit
    @translation = @locale.translations.find(params[:id])
  end

  # POST /translations
  # POST /translations.xml
  def create
    @translation = @locale.translations.build(params[:translation])

    respond_to do |format|
      if @translation.save
        flash[:notice] = 'Translation was successfully created.'
        format.html { redirect_to locale_translation_path(@locale, @translation) }
        format.xml  { render :xml => @translation, :status => :created, :location => @translation }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @translation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /translations/1
  # PUT /translations/1.xml
  def update
    @translation  = @locale.translations.find(params[:id])
    @first_time_translating = @translation.value.nil?
    respond_to do |format|
      params[:translation] ||= {}
      params[:translation][:source_id] = nil
      params[:translation][:value] = nil if params[:translation][:value].blank?
      if @translation.update_attributes(params[:translation])
        format.html do
          flash[:notice] = 'Translation was successfully updated.'
          redirect_to :back
        end
        format.xml  { head :ok }
        format.js   {}
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @translation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /translations/1
  # DELETE /translations/1.xml
  def destroy
    @translation = @locale.translations.find(params[:id])
    @translation.destroy

    respond_to do |format|
      format.html { redirect_to(locale_translations_url) }
      format.xml  { head :ok }
    end
  end

private

  def check_for_missing_params(default_value,target_value)
    return if (default_params = default_value.scan(/\%\{(.*?)\}/).flatten).empty?
    return default_params if target_value.nil? or (target_params = target_value.scan(/\%\{(.*?)\}/).flatten).empty?
    return if (missing_params = default_params - target_params).empty?
    missing_params
  end

  def translation_stats
    @stats ||= [].tap do |stats|
      default_locale = I18n::Backend::Locale.default_locale
      stats << collect_counts(default_locale)
      I18n::Backend::Locale.non_defaults.order(:name).each{|locale| stats << collect_counts(locale)}
      max_total = stats.collect{|stat| stat[:total]}.max
      stats.each{|stat| stat[:missing] = max_total - stat[:total]}
    end
  end

  def collect_counts(locale)
    total = locale.translations.count
    translated = locale.translations.translated.count
    untranslated = total - translated
    unsourced = locale.translations.unsourced.count
    sourced = total - unsourced
    {:locale => locale, :total => total, :translated => translated, :untranslated => untranslated, :unsourced => unsourced, :sourced => sourced}
  end

  def find_locale
    session[:locale_id] = params[:locale_id] if params[:locale_id]
    @locale = I18n::Backend::Locale.find_by_code(session[:locale_id]) || I18n::Backend::Locale.default_locale
  end
end
