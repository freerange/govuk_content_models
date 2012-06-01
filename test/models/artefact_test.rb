require "test_helper"
require "artefact"
require "tag_repository"

class ArtefactTest < ActiveSupport::TestCase
  test "it allows nice clean slugs" do
    a = Artefact.new(slug: "its-a-nice-day")
    a.valid?
    assert a.errors[:slug].empty?
  end

  test "it doesn't allow apostrophes in slugs" do
    a = Artefact.new(slug: "it's-a-nice-day")
    assert ! a.valid?
    assert a.errors[:slug].any?
  end

  test "it doesn't allow spaces in slugs" do
    a = Artefact.new(slug: "it is-a-nice-day")
    assert ! a.valid?
    assert a.errors[:slug].any?
  end

  test "should translate kind into internally normalised form" do
    a = Artefact.new(kind: "benefit / scheme")
    a.normalise
    assert_equal "programme", a.kind
  end

  test "should not translate unknown kinds" do
    a = Artefact.new(kind: "other")
    a.normalise
    assert_equal "other", a.kind
  end

  test "should store related artefacts in order" do
    a = Artefact.create!(slug: "a", name: "a", kind: "place", need_id: 1, owning_app: "x")
    b = Artefact.create!(slug: "b", name: "b", kind: "place", need_id: 2, owning_app: "x")
    c = Artefact.create!(slug: "c", name: "c", kind: "place", need_id: 3, owning_app: "x")

    a.related_artefacts = [b, c]
    a.save!
    a.reload

    assert_equal [b, c], a.related_artefacts
  end

  test "should raise a not found exception if the slug doesn't match" do
    assert_raise Mongoid::Errors::DocumentNotFound do
      Artefact.from_param("something-fake")
    end
  end

  test "on save update metadata with associated publication" do
    TagRepository.put(:tag_id => "test-section", :tag_type => 'section',
                        :title => "Test section")
    artefact = FactoryGirl.create(:artefact,
        slug: "foo-bar",
        kind: "answer",
        name: "Foo bar",
        primary_section: "test-section",
        sections: ["test-section"],
        department: "Test dept",
        owning_app: "publisher",
    )

    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user1, {})

    assert_equal artefact.name, edition.title
    assert_equal artefact.section, edition.section

    artefact.name = "Babar"
    artefact.save

    edition.reload
    assert_equal artefact.name, edition.title
  end

  test "should not let you edit the slug if there are any published edition" do
    artefact = FactoryGirl.create(:artefact,
        slug: "too-late-to-edit",
        kind: "answer",
        name: "Foo bar",
        owning_app: "publisher",
    )

    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user1, {})
    edition.state = "published"
    edition.save!

    assert_equal artefact.slug, edition.slug

    artefact.slug = "belated-correction"
    artefact.save

    assert_equal "too-late-to-edit", edition.slug
    assert_equal "too-late-to-edit", artefact.reload.slug
  end

  # should continue to work in the way it has been:
  # i.e. you can edit everything but the name/title for published content in panop
  test "on save title should not be applied to already published content" do
    TagRepository.put(:tag_id => "test-section", :tag_type => 'section',
                        :title => "Test section")
    artefact = FactoryGirl.create(:artefact,
        slug: "foo-bar",
        kind: "answer",
        name: "Foo bar",
        primary_section: "test-section",
        sections: ["test-section"],
        department: "Test dept",
        owning_app: "publisher",
    )

    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user1, {})
    edition.state = "published"
    edition.save!

    assert_equal artefact.name, edition.title
    assert_equal artefact.section, edition.section

    artefact.name = "Babar"
    artefact.save

    edition.reload
    assert_not_equal artefact.name, edition.title
  end

  test "should indicate when any editions have been published for this artefact" do
    artefact = FactoryGirl.create(:artefact,
        slug: "foo-bar",
        kind: "answer",
        name: "Foo bar",
        owning_app: "publisher",
    )
    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user1, {})

    assert_equal false, artefact.any_editions_published?

    edition.state = "published"
    edition.save!

    assert_equal true, artefact.any_editions_published?
  end
end
