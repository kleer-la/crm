class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @results = []

    if @query.length >= 2
      like = "%#{@query}%"
      prospects = Prospect.where("company_name ILIKE ?", like).limit(10).map { |r| { record: r, type: "Prospect", name: r.company_name, company: r.company_name } }
      customers = Customer.where("company_name ILIKE ?", like).limit(10).map { |r| { record: r, type: "Customer", name: r.company_name, company: r.company_name } }
      proposals = Proposal.where("title ILIKE ?", like).preload(:linkable).limit(10).map { |r|
        company = r.linkable.respond_to?(:company_name) ? r.linkable.company_name : r.linkable.title
        { record: r, type: "Proposal", name: r.title, company: company }
      }
      @results = prospects + customers + proposals
    end
  end
end
