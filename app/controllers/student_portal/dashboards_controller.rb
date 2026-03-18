module StudentPortal
  class DashboardsController < ApplicationController
    before_action :authenticate_student_user!
    layout 'student_portal'

    def show
      @student = current_student_user.student
      
      if @student
        @classroom = @student.classroom
        
        # --- 1. LÓGICA GERAL (Cards Superiores) ---
        @activities = @classroom ? @classroom.activities.order(created_at: :desc).limit(5) : []
        
        if @classroom
          # --- NOVIDADE: Lógica para o Filtro de Frequência por Disciplina ---
          @subjects_para_filtro = ::Subject.where(id: ::Lesson.where(classroom_id: @classroom.id).pluck(:subject_id).uniq.compact)
          @selected_subject_id = params[:subject_id]

          if @selected_subject_id.present?
            # Se houver filtro, calculamos as faltas apenas da disciplina selecionada
            aulas_filtradas_ids = ::Lesson.where(classroom_id: @classroom.id, subject_id: @selected_subject_id).pluck(:id)
            chamadas_filtradas = ::Attendance.where(student_id: @student.id, lesson_id: aulas_filtradas_ids).count
            presencas_filtradas = ::Attendance.where(student_id: @student.id, lesson_id: aulas_filtradas_ids)
                                             .where(status: ['Presente', 'present', 'Atrasado', 'late', 'Justificada', 'justified', 'Presença'])
                                             .count
            @faltas_exibir = chamadas_filtradas - presencas_filtradas
          else
            # Caso contrário, calculamos a frequência geral (total de faltas)
            total_geral_chamadas = ::Attendance.where(student_id: @student.id).count
            presencas_geral = ::Attendance.where(student_id: @student.id)
                                         .where(status: ['Presente', 'present', 'Atrasado', 'late', 'Justificada', 'justified', 'Presença'])
                                         .count
            @faltas_exibir = total_geral_chamadas - presencas_geral
          end

          # Frequência Geral (Mantida conforme solicitado para não quebrar outros componentes)
          @total_chamadas_realizadas = ::Attendance.where(student_id: @student.id).count
          presencas = ::Attendance.where(student_id: @student.id)
                                 .where(status: ['Presente', 'present', 'Atrasado', 'late', 'Justificada', 'justified', 'Presença'])
                                 .count
          
          @faltas_count = @total_chamadas_realizadas - presencas
          @percentual_presenca = @total_chamadas_realizadas > 0 ? ((presencas.to_f / @total_chamadas_realizadas) * 100).round(1) : 100.0

          # Progresso Geral de Atividades
          @total_atividades = @classroom.activities.count
          @entregues = @student.student_activities.where(status: ['Entregue', 'Entregue com Atraso', 'Corrigida']).count
          @pendentes = @total_atividades - @entregues

          # --- 2. LÓGICA POR DISCIPLINA (SUBJECT) ---
          subject_ids = ::Lesson.where(classroom_id: @classroom.id).pluck(:subject_id).uniq.compact
          subjects_da_turma = ::Subject.where(id: subject_ids)

          @disciplines_data = subjects_da_turma.map do |subject|
            # Frequência na Disciplina
            aulas_ids = ::Lesson.where(classroom_id: @classroom.id, subject_id: subject.id).pluck(:id)
            total_chamadas_sub = ::Attendance.where(student_id: @student.id, lesson_id: aulas_ids).count
            presencas_sub = ::Attendance.where(student_id: @student.id, lesson_id: aulas_ids)
                                       .where(status: ['Presente', 'present', 'Atrasado', 'late', 'Justificada', 'justified', 'Presença'])
                                       .count
            
            percentual_sub = total_chamadas_sub > 0 ? ((presencas_sub.to_f / total_chamadas_sub) * 100).round(1) : 100.0
            
            # Atividades da Disciplina
            atividades_da_materia = @classroom.activities.where(subject_id: subject.id)
            total_sub = atividades_da_materia.count
            entregues_sub = @student.student_activities.where(activity_id: atividades_da_materia.pluck(:id), status: ['Entregue', 'Entregue com Atraso', 'Corrigida']).count

            {
              instance: subject,
              percentual: percentual_sub,
              faltas: total_chamadas_sub - presencas_sub,
              total_chamadas: total_chamadas_sub,
              atividades: atividades_da_materia.order(created_at: :desc).limit(3),
              progresso_atividades: "#{entregues_sub}/#{total_sub}"
            }
          end
        else
          # Fallback caso não haja turma vinculada
          @total_chamadas_realizadas = 0
          @faltas_count = 0
          @faltas_exibir = 0
          @percentual_presenca = 0
          @total_atividades = 0
          @entregues = 0
          @pendentes = 0
          @disciplines_data = []
          @subjects_para_filtro = []
        end
      else
        redirect_to root_path, alert: "Seu usuário não está vinculado a um cadastro de aluno."
      end
    end
  end
end