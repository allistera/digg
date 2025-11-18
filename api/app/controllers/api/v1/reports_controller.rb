module Api
  module V1
    class ReportsController < ApplicationController
      before_action :authenticate_user!

      def index
        @reports = Report.includes(:reporter, :reportable)
                         .page(params[:page])
                         .per(params[:per_page] || 20)
                         .recent

        @reports = @reports.where(status: params[:status]) if params[:status].present?

        render json: {
          reports: @reports.as_json(
            only: [:id, :reason, :status, :created_at, :resolved_at],
            include: {
              reporter: { only: [:id, :username] },
              reportable: { only: [:id], methods: [:type] }
            }
          ),
          meta: pagination_meta(@reports)
        }
      end

      def create
        reportable = find_reportable
        return render json: { error: 'Reportable not found' }, status: :not_found unless reportable

        @report = current_user.reports.new(report_params)
        @report.reportable = reportable

        if @report.save
          render json: { message: 'Report submitted successfully' }, status: :created
        else
          render json: { errors: @report.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def report_params
        params.require(:report).permit(:reason)
      end

      def find_reportable
        case params[:reportable_type]
        when 'Article'
          Article.find_by(id: params[:reportable_id])
        when 'Comment'
          Comment.find_by(id: params[:reportable_id])
        when 'User'
          User.find_by(id: params[:reportable_id])
        end
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count
        }
      end
    end
  end
end
