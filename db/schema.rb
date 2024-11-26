# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_11_22_110435) do
  create_table "answers", force: :cascade do |t|
    t.text "text"
    t.integer "question_id", null: false
    t.integer "user_id", null: false
    t.integer "mcq_option_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "survey_form_id", null: false
    t.index ["mcq_option_id"], name: "index_answers_on_mcq_option_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["survey_form_id"], name: "index_answers_on_survey_form_id"
    t.index ["user_id"], name: "index_answers_on_user_id"
  end

  create_table "mcq_options", force: :cascade do |t|
    t.string "text"
    t.integer "question_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_mcq_options_on_question_id"
  end

  create_table "questions", force: :cascade do |t|
    t.string "title"
    t.integer "question_type", default: 0
    t.boolean "is_required", default: false
    t.integer "survey_form_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["survey_form_id"], name: "index_questions_on_survey_form_id"
  end

  create_table "survey_forms", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_survey_forms_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "full_phone_number"
    t.integer "country_code"
    t.bigint "phone_number"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "answers", "mcq_options"
  add_foreign_key "answers", "questions"
  add_foreign_key "answers", "survey_forms"
  add_foreign_key "answers", "users"
  add_foreign_key "mcq_options", "questions"
  add_foreign_key "questions", "survey_forms"
  add_foreign_key "survey_forms", "users"
end
