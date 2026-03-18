json.extract! activity, :id, :name, :activity_type, :student_delivery_date, :teacher_delivery_date, :status, :grade, :created_at, :updated_at
json.url activity_url(activity, format: :json)
