json.extract! student, :id, :name, :registration_number, :grade, :classroom, :course, :email, :active, :created_at, :updated_at
json.url student_url(student, format: :json)
