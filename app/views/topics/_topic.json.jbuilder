json.extract! topic, :id, :title, :schedule, :day_of_week, :subject_name, :created_at, :updated_at
json.url topic_url(topic, format: :json)
