require 'spec_helper'

describe "manifestation_types/index" do
  before(:each) do
    assign(:manifestation_types, [
      stub_model(ManifestationType,
        :name => "Name",
        :display_name => "MyText",
        :note => "MyText",
        :position => 1
      ),
      stub_model(ManifestationType,
        :name => "Name",
        :display_name => "MyText",
        :note => "MyText",
        :position => 1
      )
    ])
  end

  it "renders a list of manifestation_types" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
