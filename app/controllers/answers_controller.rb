require 'csv'

class AnswersController < ApplicationController
  before_action :authorize_request
  before_action :set_answer, only: [:destroy]
  before_action :ensure_answer_for_required_question, only: [:create, :update]
  before_action :ensure_question_id_present, only: [:create]
  before_action :set_survey_form, only: [:download_csv]
  before_action :authorize_survey_form_owner, only: [:download_csv]

	def index
    answers = Answer.includes(:question, :survey_form, :mcq_option)
                    .where(user_id: @current_user.id)
                    .order('survey_forms.title ASC, questions.title ASC')

    if answers.empty?
      render json: { message: "No answers found for the user" }, status: :not_found
      return
    end

    survey_forms_data = answers.group_by(&:survey_form).map do |survey_form, answers_for_survey|
      questions_with_answers = survey_form.questions.map do |question|
        answer = answers_for_survey.find { |ans| ans.question_id == question.id }

        {
          id: question.id,
          title: question.title,
          question_type: question.question_type,
          is_required: question.is_required,
          mcq_options: question.mcq_options.map { |opt| { id: opt.id, text: opt.text } },
          answer: answer ? format_answer(answer) : nil
        }
      end

      {
        survey_form: {
          id: survey_form.id,
          title: survey_form.title,
          description: survey_form.description,
          questions: questions_with_answers
        }
      }
    end

    render json: { survey_forms: survey_forms_data }, status: :ok
  end

	def create
    errors = []
    answers = []
    survey_form_id = params[:survey_form_id]

    begin
      ActiveRecord::Base.transaction do
        params[:answers].each do |answer_data|
          answer = @current_user.answers.new(answer_data.permit(:text, :question_id, :mcq_option_id).merge(survey_form_id: survey_form_id))

          unless answer.valid?
            errors << { question_id: answer.question_id, errors: answer.errors.full_messages }
            raise ActiveRecord::Rollback, "Error creating answers"
          end

          answer.save!
          answers << answer
        end
      end

      if errors.empty?
        render json: { message: "Answers saved successfully", answers: answers }, status: :created
      else
        render json: { errors: errors }, status: :unprocessable_entity
      end

    rescue ActiveRecord::Rollback
      render json: { errors: errors.empty? ? ['An unknown error occurred'] : errors }, status: :unprocessable_entity
    end
  end

  def show
	  survey_form_id = params[:id]
	  survey_form = SurveyForm.includes(questions: :mcq_options).find_by(id: survey_form_id)

	  if survey_form.nil?
	    render json: { error: "Survey form not found" }, status: :not_found
	    return
	  end

	  user_answers = Answer.where(survey_form_id: survey_form_id, user_id: @current_user.id)
	  questions_with_answers = survey_form.questions.map do |question|
	    {
	      id: question.id,
	      title: question.title,
	      question_type: question.question_type,
	      required: question.is_required,
	      mcq_options: question.mcq_options.map { |opt| { id: opt.id, text: opt.text } },
	      answer: user_answers.find { |answer| answer.question_id == question.id }
	    }
	  end

	  serialized_questions = questions_with_answers.map do |question_with_answer|
	    serialized_answer = question_with_answer[:answer].present? ? AnswerSerializer.new(question_with_answer[:answer]).as_json : nil
	    question_with_answer.merge(answer: serialized_answer)
	  end

	  render json: {
	    survey_form: {
	      id: survey_form.id,
	      title: survey_form.title,
	      questions: serialized_questions
	    }
	  }, status: :ok
  end

  def update
    errors = []
    updated_answers = []
    deleted_answers = []

    begin
      ActiveRecord::Base.transaction do
        params[:answers].each do |answer_data|
          answer = Answer.find_by(id: answer_data[:id], user_id: @current_user.id)

          if answer.nil?
            errors << { id: answer_data[:id], errors: ["Answer not found or not authorized to update"] }
            raise ActiveRecord::Rollback, "Answer not found"
          end
          question = Question.find_by(id: answer_data[:question_id])
          if answer_data[:deleted] == true
            if !question.is_required
              answer.destroy
              deleted_answers << answer
            end
          else
            unless answer.update(answer_data.permit(:text, :mcq_option_id))
              errors << { id: answer.id, errors: answer.errors.full_messages }
              raise ActiveRecord::Rollback, "Validation error in updating answer"
            end

            updated_answers << answer
          end
        end
      end

      if errors.empty?
        render json: { message: "Answers updated successfully", answers: updated_answers, deleted_answers: deleted_answers }, status: :ok
      else
        render json: { errors: errors }, status: :unprocessable_entity
      end

    rescue ActiveRecord::Rollback
      render json: { errors: errors.empty? ? ['An unknown error occurred'] : errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if @answer.user == @current_user
      @answer.destroy
      render json: { message: "Answer deleted successfully" }, status: :ok
    else
      render json: { error: "You are not authorized to delete this answer" }, status: :forbidden
    end
  end

  def download_csv
    answers = Answer.includes(:question, :survey_form)
                    .where(survey_form_id: @survey_form.id)
                    .order(:user_id)

    if answers.empty?
      render json: { message: "No answers found for this survey form" }, status: :not_found
      return
    end

    csv_data = generate_csv(answers)
    file_name = "#{@survey_form.title}_answers_#{Time.now.to_i}.csv"
    
    # file_path = Rails.root.join('tmp', file_name)
    # File.open(file_path, 'w') { |file| file.write(csv_data) }
    # send_file file_path, filename: file_name, type: 'text/csv', disposition: 'attachment'
    # File.delete(file_path) if File.exist?(file_path)

    send_data csv_data, filename: "#{@survey_form.title}_answers.csv", type: 'text/csv', disposition: 'attachment'
  end

  private

  def format_answer(answer)
    if answer.text.present?
      { text: answer.text }
    elsif answer.mcq_option.present?
      { mcq_option_id: answer.mcq_option.id, mcq_option_text: answer.mcq_option.text }
    else
      nil
    end
  end

  def set_answer
    @answer = Answer.find_by(id: params[:id])

    unless @answer
      render json: { error: "Answer not found" }, status: :not_found
    end
  end

	def answer_params
	  params.require(:answers).map do |answer|
	    answer.permit(:text, :question_id, :mcq_option_id, :survey_form_id)
	  end
	end

  def ensure_answer_for_required_question
    if params[:answers]
      params[:answers].each do |answer|
        question = Question.find_by(id: answer[:question_id])
        if question&.is_required == true
          unless answer[:text].present? || answer[:mcq_option_id].present?
            render json: { error: "Answer is required for question #{question.id}" }, status: :unprocessable_entity
            return
          end
        end
      end
    end
  end

  def ensure_question_id_present
    if params[:answers].any? { |answer| answer[:question_id].blank? }
      render json: { error: "Question ID must be present for all answers" }, status: :unprocessable_entity
    end
  end

  def set_survey_form
    @survey_form = SurveyForm.find_by(id: params[:survey_form_id])
    
    unless @survey_form
      render json: { error: "Survey form not found" }, status: :not_found
    end
  end

  def generate_csv(answers)
    CSV.generate(headers: true) do |csv|
      csv << ['User ID', 'Question ID', 'Question Title', 'Answer Text', 'Answer MCQ Option', 'Question Type', 'Is Required']

      answers.group_by(&:user_id).each do |user_id, user_answers|
        user_answers.each do |answer|
          row = [
            user_id,
            answer.question_id,
            answer.question.title,
            answer.text,
            answer.mcq_option&.text,
            answer.question.question_type,
            answer.question.is_required
          ]
          csv << row
        end
      end
    end
  end

  def authorize_survey_form_owner
    unless @survey_form.user_id == current_user.id
      render json: { error: 'You are not authorized to access this resource' }, status: :unauthorized
    end
  end
end
