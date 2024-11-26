class SurveyFormsController < ApplicationController
  before_action :authorize_request, only: [:create, :update, :destroy]
  before_action :set_survey_form, only: [:update, :destroy]

  def create
    survey_form = @current_user.survey_forms.new(survey_form_params)
    if survey_form.save
      render json: { message: "Survey form created successfully", survey_form: SurveyFormSerializer.new(survey_form).serializable_hash }, status: :created
    else
      render json: { errors: survey_form.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    survey_form = SurveyForm.find_by(id: params[:id])
    if survey_form
      render json: SurveyFormSerializer.new(survey_form).serializable_hash, status: :ok
    else
      render json: { errors: "Survey Form not found" }, status: :unprocessable_entity
    end
  end

  def update
    if @survey_form.update(survey_form_params)
      render json: { message: "Survey form updated successfully", survey_form: SurveyFormSerializer.new(@survey_form).serializable_hash }, status: :ok
    else
      render json: { errors: @survey_form.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @survey_form.destroy
    render json: { message: "Survey form deleted successfully" }, status: :ok
  end

  private

  def set_survey_form
    @survey_form = @current_user.survey_forms.find_by(id: params[:id])

    unless @survey_form
      render json: { error: "Survey form not found" }, status: :not_found
    end
  end

  def survey_form_params
    params.require(:survey_form).permit(
      :title, :description,
      questions_attributes: [
        :id, :title, :question_type, :is_required, :_destroy,
        mcq_options_attributes: [:id, :text, :_destroy]
      ]
    )
  end
end
