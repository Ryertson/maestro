require 'csv'

class StudentsController < ApplicationController
  # 1. Primeiro declaramos as proteções padrão do sistema
  before_action :authenticate_professor!, unless: -> { request.format.json? }
  before_action :set_student, only: %i[ show edit update destroy ]
  before_action :set_teacher_context, unless: -> { request.format.json? }
  
  # 2. Agora pulamos as proteções APENAS para a busca JSON de ativação do aluno
  skip_before_action :authenticate_professor!, only: [:index], if: -> { request.format.json? }, raise: false
  skip_before_action :verify_authenticity_token, only: [:index], if: -> { request.format.json? }, raise: false

  # Trava de segurança para impedir acesso via ID na URL a alunos fora do vínculo
  before_action :authorize_student_access!, only: %i[ show edit update destroy ]

  def index
    respond_to do |format|
      # PRIORIDADE 1: INTERFACE DO PROFESSOR (HTML)
      # Adicionada trava lógica: Se houver parâmetros de busca de data ou turma, 
      # forçamos o HTML mesmo que o navegador peça JSON por engano.
      format.html do
        # 1. Configuração de Datas
        @selected_date = params[:month_year].present? ? Date.parse("#{params[:month_year]}-01") : Date.today
        @start_of_month = @selected_date.beginning_of_month
        @end_of_month = @selected_date.end_of_month

        # 2. Definição das Turmas Disponíveis (Filtro por Professor)
        if current_professor&.admin?
          @available_classrooms = Classroom.all
        elsif @teacher
          @available_classrooms = Classroom.joins(:classroom_subjects)
                                           .where(classroom_subjects: { teacher_id: @teacher.id })
                                           .distinct
        else
          @available_classrooms = Classroom.none
        end

        # 3. Persistência da Turma Selecionada
        @classroom_id = params[:classroom_id] || session[:last_classroom_id]
        
        # Validação de Segurança
        unless current_professor&.admin? || @available_classrooms.pluck(:id).include?(@classroom_id.to_i)
          @classroom_id = @available_classrooms.first&.id
        end
        session[:last_classroom_id] = @classroom_id if @classroom_id.present?

        # 4. Lógica de Busca de Alunos e Presenças
        if @classroom_id.present?
          @classroom = Classroom.find(@classroom_id)
          @students = @classroom.students.includes(:attendances).order(:name)
          
          @students = @students.where(id: params[:student_id]) if params[:student_id].present?

          @lessons_in_month = Lesson.where(classroom_id: @classroom_id, date: @start_of_month..@end_of_month)
          @planned_dates = @lessons_in_month.pluck(:date).to_set

          relevant_attendances = Attendance.where(
            classroom_id: @classroom_id, 
            date: @start_of_month..@end_of_month
          )

          # 5. Cálculos de Métricas
          @total_presents   = relevant_attendances.where(status: ['Presente', 'present']).count
          @total_absents     = relevant_attendances.where(status: ['Faltou', 'absent', 'Absent']).count
          @total_lates       = relevant_attendances.where(status: ['Atrasado', 'late', 'Late']).count
          @total_justified   = relevant_attendances.where(status: ['Justificada', 'justified', 'Justified']).count

          # 6. Cálculo da Barra de Aproveitamento Geral
          total_lessons = @planned_dates.size
          total_possible_slots = @students.count * total_lessons
          
          if total_possible_slots > 0
            positive_attendances = @total_presents + @total_lates + @total_justified
            @attendance_rate = ((positive_attendances.to_f / total_possible_slots) * 100).round(1)
          else
            @attendance_rate = 0
          end
        else
          @students = Student.none
          @planned_dates = Set.new
          @total_presents = @total_absents = @total_lates = @total_justified = @attendance_rate = 0
        end
      end

      # PRIORIDADE 2: BUSCA PARA ATIVAÇÃO DE ALUNO (JSON)
      # Só responde JSON se não houver contexto de busca do professor (month_year)
      format.json do
        if params[:month_year].blank? && params[:classroom_id].present?
          @json_students = Student.where(classroom_id: params[:classroom_id])
                                  .left_outer_joins(:student_user)
                                  .where(student_users: { id: nil })
                                  .select(:id, :name)
          render json: @json_students
        else
          render json: []
        end
      end
    end
  end

  def new
    @student = Student.new
    @students = current_professor&.admin? ? Student.order(created_at: :desc).limit(10) : Student.none
  end

  def create
    @student = Student.new(student_params)
    if @student.save
      redirect_to students_path(classroom_id: @student.classroom_id), notice: "Aluno matriculado com sucesso!"
    else
      @students = current_professor&.admin? ? Student.order(created_at: :desc).limit(10) : Student.none
      render :new, status: :unprocessable_entity
    end
  end

  def import
    return redirect_to students_path, alert: "Apenas administradores podem importar alunos." unless current_professor&.admin?
    
    file = params[:file]
    return redirect_to new_student_path, alert: "Por favor, selecione um arquivo." if file.nil?

    count = 0
    CSV.foreach(file.path, col_sep: ';', encoding: 'bom|utf-8') do |row|
      next if row[0].blank? || row[0].upcase.include?('NOME') || row[0].upcase.include?('MODELO')

      nome      = row[0]&.strip
      curso_n   = row[1]&.strip
      serie_n   = row[2]&.strip
      turma_n   = row[3]&.strip

      course = Course.where("LOWER(name) LIKE ?", "%#{curso_n.to_s.downcase}%").first
      grade = Level.find_by(name: serie_n)
      section = Section.find_by(name: turma_n)

      next unless course && grade && section

      # Atualizado: grade_id agora é level_id
      classroom = Classroom.find_by(course_id: course.id, level_id: grade.id, section_id: section.id)
      next unless classroom

      Student.create!(
        name: nome, active: true, classroom: classroom,
        grade: serie_n, section: turma_n, course: curso_n
      )
      count += 1
    end

    redirect_to students_path, notice: "Importação concluída. #{count} alunos inseridos."
  end

  def allocate_classrooms
    return redirect_to students_path, alert: "Ação restrita ao administrador." unless current_professor&.admin?
    
    count = 0
    Student.all.each do |student|
      grade = Level.find_by(name: student.grade&.strip)
      section = Section.find_by(name: student.section&.strip)
      course = Course.find_by(name: student.course&.strip)

      if grade && section && course
        # Atualizado: grade_id agora é level_id
        target = Classroom.find_by(course_id: course.id, level_id: grade.id, section_id: section.id)
        if target
          student.update_columns(classroom_id: target.id)
          count += 1
        end
      end
    end
    redirect_to students_path, notice: "#{count} alunos organizados!"
  end

  def show
    @classroom = @student.classroom
    @activities = @classroom.activities.order(date: :asc)
    @submissions = @student.student_activities.index_by(&:activity_id)

    @total_aulas = Lesson.where(classroom_id: @classroom.id).count
    presencas_count = Attendance.where(student_id: @student.id)
                                .where(status: ['Presente', 'present', 'Atrasado', 'late', 'Justificada', 'justified'])
                                .count
                                
    @faltas_count = @total_aulas - presencas_count
    
    if @total_aulas > 0
      @percentual_faltas = ((@faltas_count.to_f / @total_aulas) * 100).round(1)
      @percentual_presenca = (100 - @percentual_faltas).round(1)
    else
      @percentual_faltas = 0
      @percentual_presenca = 0
    end
  end

  def edit; end

  def update
    if @student.update(student_params)
      redirect_to classroom_path(@student.classroom), notice: "Informações do aluno atualizadas com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    classroom = @student.classroom
    @student.destroy
    redirect_to classroom_path(classroom), notice: "O aluno foi removido da turma com sucesso.", status: :see_other
  end

  def download_template
    csv_data = CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << ["NOME DO ALUNO", "CURSO", "SÉRIE", "TURMA"]
      csv << ["JOÃO SILVA", "Agroecologia", "1ª Série", "A"]
    end
    send_data csv_data, filename: "modelo_importacao.csv", type: "text/csv"
  end

  private

  def set_student
    @student = Student.find(params[:id])
  end

  def set_teacher_context
    @teacher = current_professor&.teacher
  end

  def authorize_student_access!
    return if current_professor&.admin?
    
    allowed_classroom_ids = Classroom.joins(:classroom_subjects)
                                     .where(classroom_subjects: { teacher_id: @teacher&.id })
                                     .pluck(:id)
    
    unless allowed_classroom_ids.include?(@student.classroom_id)
      redirect_to students_path, alert: "Acesso negado: Este aluno pertence a uma turma fora do seu vínculo."
    end
  end

  def student_params
    params.require(:student).permit(:name, :course, :grade, :section, :active, :classroom_id)
  end
end