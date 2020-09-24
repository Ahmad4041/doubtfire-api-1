require 'test_helper'

class GroupSetsApiTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  include TestHelpers::AuthHelper
  include TestHelpers::JsonHelper

  def app
    Rails.application
  end

  def test_post_add_a_new_groupset_to_a_unit_without_authorization
    # A dummy groupSet
    newGroupSet = FactoryBot.build(:group_set)

    # Create a unit
    newUnit = FactoryBot.create(:unit)

    # Obtain a student from the unit
    studentUser = newUnit.active_projects.first.student

    # Data that we want to post
    data_to_post = {
      unit_id: newUnit.id,
      group_set: newGroupSet
    }

    # Perform the POST
    post_json with_auth_token("/api/units/#{newUnit.id}/group_sets", studentUser), data_to_post

    # Check error code
    assert_equal 403, last_response.status
  end

  def test_post_add_a_new_groupset_to_a_unit_with_authorization
    # A groupSet we want to save
    newGroupSet = FactoryBot.build(:group_set)

    # Create a unit 
    newUnit = FactoryBot.create(:unit)

    # Data that we want to post
    data_to_post = {
      unit_id: newUnit.id,
      group_set: newGroupSet,
    }

    # perform the POST
    post_json with_auth_token("/api/units/#{newUnit.id}/group_sets", newUnit.main_convenor_user), data_to_post

    # check if the POST get through
    assert_equal 201, last_response.status
    #check response
    response_keys = %w(name allow_students_to_create_groups allow_students_to_manage_groups keep_groups_in_same_class)
    responseGroupSet = GroupSet.find(last_response_body['id'])
    assert_json_matches_model(last_response_body,responseGroupSet,response_keys)
    assert_equal newUnit.id,responseGroupSet.unit.id
    assert_equal newGroupSet.name,responseGroupSet.name
    assert_equal newGroupSet.allow_students_to_create_groups,responseGroupSet.allow_students_to_create_groups
    assert_equal newGroupSet.allow_students_to_manage_groups,responseGroupSet.allow_students_to_manage_groups
    assert_equal newGroupSet.keep_groups_in_same_class,responseGroupSet.keep_groups_in_same_class
  end

  def test_post_add_a_group_to_a_group_set_of_a_unit_without_authorization
    # Create a groupSet
    newGroupSet = FactoryBot.create(:group_set)

    # Obtain a unit from group_set
    newUnit = newGroupSet.unit

    # A group that we want to save
    newGroup = FactoryBot.build(:group)

    # Obtain a tutorial from unit
    newTutorial = newUnit.tutorials.first

    # Data to post
    data_to_post = {
      unit_id: newUnit.id,
      group_set_id: newGroupSet.id,
      group: {
        name:newGroup.name,
        tutorial_id:newTutorial.id
      },
      auth_token: auth_token
    }

    # perform the POST
    post_json "/api/units/#{newUnit.id}/group_sets/#{newGroupSet.id}/groups", data_to_post

    # Check error code
    assert_equal 403, last_response.status
  end

  def test_post_add_a_group_to_a_group_set_of_a_unit_with_authorization
    # Create a groupSet
    newGroupSet = FactoryBot.create(:group_set)

    # Obtain a unit from group_set
    newUnit = newGroupSet.unit

    # A group that we want to save
    newGroup = FactoryBot.build(:group)

    # Obtain a tutorial from unit
    newTutorial = newUnit.tutorials.first

    # Data to post
    data_to_post = {
      unit_id: newUnit.id,
      group_set_id: newGroupSet.id,
      group: {
        name:newGroup.name,
        tutorial_id:newTutorial.id
      }
    }

    # perform the POST
    post_json with_auth_token("/api/units/#{newUnit.id}/group_sets/#{newGroupSet.id}/groups",newUnit.main_convenor_user), data_to_post

    # check if the POST get through
    assert_equal 201, last_response.status
    #check response
    response_keys = %w(name tutorial_id group_set_id number)
    responseGroup = Group.find(last_response_body['id'])
    assert_json_matches_model(last_response_body,responseGroup,response_keys)
    assert_equal newUnit.id, responseGroup.group_set.unit.id
    assert_equal newGroup.name, responseGroup.name
    assert_equal newGroupSet.id,responseGroup.group_set.id
    assert_equal newTutorial.id,responseGroup.group_set.unit.tutorials.first.id
  end

  def test_get_all_groups_in_unit_without_authorization
    # Create a group
    newGroup = FactoryBot.create(:group)
    # Obtain the unit of the group
    newUnit = newGroup.group_set.unit

    # Obtain student object from the unit
    studentUser = newUnit.active_projects.first.student

    get with_auth_token "/api/units/#{newUnit.id}/groups",studentUser
    # Check error code when an unauthorized user tries to get groups in a unit
    assert_equal 403, last_response.status
  end

  def test_get_all_groups_in_unit_with_authorization
    # Create a group
    newGroup = FactoryBot.create(:group)

    # Obtain the unit from the group
    newUnit = newGroup.group_set.unit

    get with_auth_token "/api/units/#{newUnit.id}/groups",newUnit.main_convenor_user

    #check returning number of groups
    assert_equal newUnit.groups.all.count, last_response_body.count

    #Check response
    response_keys = %w(id name)
    last_response_body.each do | data |
      grp = Group.find(data['id'])
      assert_json_matches_model(data, grp, response_keys)
    end
    assert_equal 200, last_response.status
  end

  def test_get_groups_in_a_group_set_without_authorization
    # Create a group
    newGroup = FactoryBot.create(:group)

    # Obtain the group_set from group
    newGroupSet = newGroup.group_set

    # Obtain the unit from the group
    newUnit = newGroup.group_set.unit

    get with_auth_token "/api/units/#{newUnit.id}/group_sets/#{newGroupSet.id}/groups"
    # Check error code
    assert_equal 403, last_response.status
  end

  def test_get_groups_in_a_group_set_with_authorization
    # Create a group
    newGroup = FactoryBot.create(:group)

    # Obtain the group_set from group
    newGroupSet = newGroup.group_set

    # Obtain the unit from the group
    newUnit = newGroup.group_set.unit

    get with_auth_token "/api/units/#{newUnit.id}/group_sets/#{newGroupSet.id}/groups",newUnit.main_convenor_user

    # Check returning number of groups
    assert_equal newGroupSet.groups.all.count,last_response_body.count

    # Check response
    response_keys = %w(id name)
    last_response_body.each do | data |
      grp = Group.find(data['id'])
      assert_json_matches_model(data, grp, response_keys)
    end
    assert_equal 200, last_response.status
  end
  
  def test_groups_unlocked_upon_creation

    unit = FactoryBot.create :unit
    unit.save!
    group_set = GroupSet.create!({name: 'test_groups_unlocked_upon_creation', unit: unit})
    group_set.save!

    # A group should be unlocked upon creation.
    data = {
      group: {
        name: 'test_groups_unlocked_upon_creation',
        tutorial_id: unit.tutorials.first.id,
        capacity_adjustment: 0,
      },
    }
    post "/api/units/#{unit.id}/group_sets/#{group_set.id}/groups", with_auth_token(data, unit.main_convenor_user)
    assert_equal false, last_response_body['locked']

    Group.find(last_response_body['id']).destroy
    group_set.destroy
    unit.destroy
  end

  def test_groups_lockable_only_by_staff
    unit = FactoryBot.create :unit
    unit.save!
    group_set = GroupSet.create!({name: 'test_groups_lockable_only_by_staff', unit: unit, allow_students_to_manage_groups: true })
    group_set.save!
    group = Group.create!({group_set: group_set, name: 'test_groups_lockable_only_by_staff', tutorial: unit.tutorials.first })
    group.save!
    group.add_member(unit.active_projects[0])
    
    url = "api/units/#{unit.id}/group_sets/#{group_set.id}/groups/#{group.id}"
    lock_data = { group: { locked: true } }
    unlock_data = { group: { locked: false } }

    # Students shouldn't be able to lock the (currently unlocked because it was just created) group, even though groups
    # within the group set are student-manageable.
    put url, with_auth_token(lock_data, group.projects.first.student)
    assert_equal 403, last_response.status
    assert_equal false, Group.find(group.id).locked

    # Main convenor should be able to lock the group.
    put url, with_auth_token(lock_data, unit.main_convenor_user)
    assert_equal 200, last_response.status
    assert_equal true, Group.find(group.id).locked

    # Students shouldn't be able to unlock the group either.
    put url, with_auth_token(unlock_data, group.projects.first.student)
    assert_equal 403, last_response.status
    assert_equal true, Group.find(group.id).locked

    # Main convenor should be able to unlock the locked group.
    put url, with_auth_token(unlock_data, unit.main_convenor_user)
    assert_equal 200, last_response.status
    assert_equal false, Group.find(group.id).locked

    group.destroy!
    group_set.destroy!
    unit.destroy!
  end

end