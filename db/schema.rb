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

ActiveRecord::Schema[8.1].define(version: 2026_05_06_181854) do
  create_table "academic_events", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.date "event_date"
    t.string "event_type"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "activities", force: :cascade do |t|
    t.string "activity_type"
    t.string "category"
    t.integer "classroom_id", null: false
    t.boolean "corrected"
    t.integer "course_id"
    t.datetime "created_at", null: false
    t.date "date"
    t.decimal "grade"
    t.integer "grade_id"
    t.integer "lesson_id", null: false
    t.string "name"
    t.integer "points"
    t.string "status"
    t.date "student_delivery_date"
    t.integer "subject_id"
    t.date "teacher_delivery_date"
    t.datetime "updated_at", null: false
    t.index ["classroom_id"], name: "index_activities_on_classroom_id"
    t.index ["lesson_id"], name: "index_activities_on_lesson_id"
    t.index ["subject_id"], name: "index_activities_on_subject_id"
  end

  create_table "attendances", force: :cascade do |t|
    t.integer "classroom_id"
    t.datetime "created_at", null: false
    t.date "date"
    t.integer "lesson_id"
    t.string "status"
    t.integer "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id"], name: "index_attendances_on_classroom_id"
    t.index ["lesson_id"], name: "index_attendances_on_lesson_id"
    t.index ["student_id"], name: "index_attendances_on_student_id"
  end

  create_table "badges", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "bimesters", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.date "end_date"
    t.string "name"
    t.date "start_date"
    t.datetime "updated_at", null: false
  end

  create_table "classroom_subjects", force: :cascade do |t|
    t.integer "classroom_id", null: false
    t.datetime "created_at", null: false
    t.integer "subject_id", null: false
    t.integer "teacher_id", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id"], name: "index_classroom_subjects_on_classroom_id"
    t.index ["subject_id"], name: "index_classroom_subjects_on_subject_id"
    t.index ["teacher_id"], name: "index_classroom_subjects_on_teacher_id"
  end

  create_table "classrooms", force: :cascade do |t|
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.integer "level_id", null: false
    t.string "section"
    t.integer "section_id", null: false
    t.integer "teacher_id"
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_classrooms_on_course_id"
    t.index ["level_id"], name: "index_classrooms_on_level_id"
    t.index ["section_id"], name: "index_classrooms_on_section_id"
    t.index ["teacher_id"], name: "index_classrooms_on_teacher_id"
  end

  create_table "courses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "disciplinas", force: :cascade do |t|
    t.string "area"
    t.integer "carga_horaria"
    t.datetime "created_at", null: false
    t.string "nome"
    t.integer "professor_id", null: false
    t.datetime "updated_at", null: false
    t.index ["professor_id"], name: "index_disciplinas_on_professor_id"
  end

  create_table "grades", force: :cascade do |t|
    t.integer "classroom_id", null: false
    t.datetime "created_at", null: false
    t.string "period"
    t.integer "student_id", null: false
    t.integer "subject_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "value"
    t.index ["classroom_id"], name: "index_grades_on_classroom_id"
    t.index ["student_id"], name: "index_grades_on_student_id"
    t.index ["subject_id"], name: "index_grades_on_subject_id"
  end

  create_table "knowledge_areas", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "lessons", force: :cascade do |t|
    t.string "class_group"
    t.integer "classroom_id"
    t.string "course"
    t.datetime "created_at", null: false
    t.date "date"
    t.string "grade_level"
    t.boolean "has_activity", default: false
    t.string "status"
    t.integer "subject_id"
    t.integer "teacher_id"
    t.string "topic_name"
    t.datetime "updated_at", null: false
    t.string "week"
    t.index ["classroom_id"], name: "index_lessons_on_classroom_id"
    t.index ["subject_id"], name: "index_lessons_on_subject_id"
    t.index ["teacher_id"], name: "index_lessons_on_teacher_id"
  end

  create_table "levels", force: :cascade do |t|
    t.integer "activity_id"
    t.integer "bimester_id"
    t.integer "classroom_id"
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "student_id"
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 5, scale: 2
    t.index ["activity_id"], name: "index_levels_on_activity_id"
    t.index ["bimester_id"], name: "index_levels_on_bimester_id"
    t.index ["classroom_id"], name: "index_levels_on_classroom_id"
    t.index ["student_id"], name: "index_levels_on_student_id"
  end

  create_table "professors", force: :cascade do |t|
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "matricula"
    t.string "name"
    t.string "nome"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.integer "view_mode", default: 0
    t.index ["email"], name: "index_professors_on_email", unique: true
    t.index ["reset_password_token"], name: "index_professors_on_reset_password_token", unique: true
  end

  create_table "sections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "student_activities", force: :cascade do |t|
    t.integer "activity_id", null: false
    t.datetime "created_at", null: false
    t.date "delivered_at"
    t.decimal "points", precision: 5, scale: 2
    t.float "score"
    t.string "status"
    t.integer "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_student_activities_on_activity_id"
    t.index ["student_id"], name: "index_student_activities_on_student_id"
  end

  create_table "student_badges", force: :cascade do |t|
    t.integer "badge_id", null: false
    t.datetime "created_at", null: false
    t.datetime "granted_at"
    t.integer "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["badge_id"], name: "index_student_badges_on_badge_id"
    t.index ["student_id"], name: "index_student_badges_on_student_id"
  end

  create_table "student_points", force: :cascade do |t|
    t.integer "activity_id", null: false
    t.datetime "created_at", null: false
    t.float "points"
    t.integer "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_student_points_on_activity_id"
    t.index ["student_id"], name: "index_student_points_on_student_id"
  end

  create_table "student_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_student_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_student_users_on_reset_password_token", unique: true
    t.index ["student_id"], name: "index_student_users_on_student_id"
  end

  create_table "students", force: :cascade do |t|
    t.boolean "active"
    t.string "classroom"
    t.integer "classroom_id", null: false
    t.string "course"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "grade"
    t.integer "level", default: 1
    t.integer "level_id"
    t.string "name"
    t.string "section"
    t.integer "student_user_id"
    t.string "title", default: "Iniciante"
    t.integer "total_xp", default: 0
    t.datetime "updated_at", null: false
    t.integer "xp", default: 0
    t.index ["classroom_id"], name: "index_students_on_classroom_id"
    t.index ["student_user_id"], name: "index_students_on_student_user_id"
  end

  create_table "subjects", force: :cascade do |t|
    t.integer "course_id"
    t.datetime "created_at", null: false
    t.integer "knowledge_area_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_subjects_on_course_id"
    t.index ["knowledge_area_id"], name: "index_subjects_on_knowledge_area_id"
  end

  create_table "subjects_teachers", id: false, force: :cascade do |t|
    t.integer "subject_id", null: false
    t.integer "teacher_id", null: false
  end

  create_table "submissions", force: :cascade do |t|
    t.integer "activity_id", null: false
    t.datetime "created_at", null: false
    t.string "status"
    t.integer "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_submissions_on_activity_id"
    t.index ["student_id"], name: "index_submissions_on_student_id"
  end

  create_table "teacher_assignments", force: :cascade do |t|
    t.integer "classroom_id"
    t.integer "course_id"
    t.datetime "created_at", null: false
    t.integer "subject_id"
    t.integer "teacher_id", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id"], name: "index_teacher_assignments_on_classroom_id"
    t.index ["course_id"], name: "index_teacher_assignments_on_course_id"
    t.index ["subject_id"], name: "index_teacher_assignments_on_subject_id"
    t.index ["teacher_id"], name: "index_teacher_assignments_on_teacher_id"
  end

  create_table "teachers", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "phone"
    t.integer "professor_id"
    t.string "status"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["professor_id"], name: "index_teachers_on_professor_id"
    t.index ["user_id"], name: "index_teachers_on_user_id"
  end

  create_table "terms", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.date "end_date"
    t.string "name"
    t.date "start_date"
    t.datetime "updated_at", null: false
  end

  create_table "topics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "day_of_week"
    t.integer "schedule"
    t.string "subject_name"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "activities", "classrooms"
  add_foreign_key "activities", "lessons"
  add_foreign_key "activities", "subjects"
  add_foreign_key "attendances", "classrooms"
  add_foreign_key "attendances", "lessons"
  add_foreign_key "attendances", "students"
  add_foreign_key "classroom_subjects", "classrooms"
  add_foreign_key "classroom_subjects", "subjects"
  add_foreign_key "classroom_subjects", "teachers"
  add_foreign_key "classrooms", "courses"
  add_foreign_key "classrooms", "levels"
  add_foreign_key "classrooms", "sections"
  add_foreign_key "classrooms", "teachers"
  add_foreign_key "disciplinas", "professors"
  add_foreign_key "grades", "classrooms"
  add_foreign_key "grades", "students"
  add_foreign_key "grades", "subjects"
  add_foreign_key "lessons", "classrooms"
  add_foreign_key "lessons", "subjects"
  add_foreign_key "lessons", "teachers"
  add_foreign_key "levels", "activities"
  add_foreign_key "levels", "bimesters"
  add_foreign_key "levels", "classrooms"
  add_foreign_key "levels", "students"
  add_foreign_key "student_activities", "activities"
  add_foreign_key "student_activities", "students"
  add_foreign_key "student_badges", "badges"
  add_foreign_key "student_badges", "students"
  add_foreign_key "student_points", "activities"
  add_foreign_key "student_points", "students"
  add_foreign_key "student_users", "students"
  add_foreign_key "students", "classrooms"
  add_foreign_key "students", "student_users"
  add_foreign_key "subjects", "courses"
  add_foreign_key "subjects", "knowledge_areas"
  add_foreign_key "submissions", "activities"
  add_foreign_key "submissions", "students"
  add_foreign_key "teacher_assignments", "classrooms"
  add_foreign_key "teacher_assignments", "courses"
  add_foreign_key "teacher_assignments", "subjects"
  add_foreign_key "teacher_assignments", "teachers"
  add_foreign_key "teachers", "professors"
end
