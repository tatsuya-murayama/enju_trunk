require 'spec_helper'

describe "creates/index.html.erb" do
  before(:each) do
    assign(:creates, [
      stub_model(Create,
        :work_id => 1,
        :patron_id => 1
      ),
      stub_model(Create,
        :work_id => 1,
        :patron_id => 2
      )
    ])
    @ability = Object.new
    @ability.extend(CanCan::Ability)
    controller.stub(:current_ability) { @ability }
  end

  it "renders a list of creates" do
    pending("pagination") do
      render
      # Run the generator again with the --webrat flag if you want to use webrat matchers
      assert_select "tr>td", :text => Manifestation.find(1).original_title, :count => 2
    end
  end
end
