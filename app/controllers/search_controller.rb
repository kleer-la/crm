class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @results = []

    if @query.length >= 2
      prospects = Prospect.search_by_name(@query).limit(10).map { |r| { record: r, type: "Prospect", name: r.company_name, company: r.company_name } }
      customers = Customer.search_by_name(@query).limit(10).map { |r| { record: r, type: "Customer", name: r.company_name, company: r.company_name } }
      proposals = Proposal.search_by_title(@query).preload(:linkable).limit(10).map { |r|
        company = r.linkable.respond_to?(:company_name) ? r.linkable.company_name : r.linkable.title
        { record: r, type: "Proposal", name: r.title, company: company }
      }
      @results = prospects + customers + proposals
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
