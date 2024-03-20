# frozen_string_literal: true

class ::DummyReplacer < StringReplacer::Replacer
  register_helper(:capitalize, &:capitalize)

  register_helper(:user_name) do
    @passed_data[:user_name]
  end

  register_helper(:swapcase, &:swapcase)
end

class ::DummyReplacerSubclass < DummyReplacer
end

RSpec.describe StringReplacer::Replacer do
  it 'subclasses contain parent registered helpers' do
    expect(DummyReplacerSubclass.registered_helpers.first).to be(:capitalize)
    expect(DummyReplacerSubclass.registered_helpers.last).to be(:swapcase)
  end

  it 'subclasses can call helpers' do
    expect(
      DummyReplacerSubclass.new('My name is {{capitalize(john)}}').replace
    ).to eql('My name is John')
  end

  describe '.register_helper' do
    it 'can register new helpers' do
      DummyReplacerSubclass.register_helper(:downcase, &:downcase)
      expect(DummyReplacerSubclass.registered_helpers.last).to be(:downcase)
    end
  end

  describe '.unregister_helper' do
    it 'can unregister existing helpers' do
      DummyReplacerSubclass.unregister_helper(:downcase)
      expect(DummyReplacerSubclass.registered_helpers.last).to be(:swapcase)
    end
  end

  describe '#helper_exists?' do
    it 'check for existing helpers' do
      expect(DummyReplacerSubclass.new('').helper_exists?(:capitalize)).to be(true)
      expect(DummyReplacer.new('').helper_exists?(:capitalize)).to be(true)
    end
  end

  describe '#replace' do
    it 'replacer does not modify a string without handlebars' do
      string = "I'am a simple string with $ # / & spécial characters?_"
      expect(DummyReplacer.new(string).replace).to eql(string)
    end

    it 'can call helpers inside handlebars' do
      expect(
        DummyReplacer.new('My name is {{capitalize(john)}}').replace
      ).to eql('My name is John')
    end

    it 'can call multiple helpers' do
      expect(
        DummyReplacer.new('My name is {{capitalize(john)}} {{swapcase(johnson)}}').replace
      ).to eql('My name is John JOHNSON')
    end

    it 'can call nested helpers' do
      expect(
        DummyReplacer.new('My name is {{swapcase(capitalize(john))}} {{swapcase(johnson)}}').replace
      ).to eql('My name is jOHN JOHNSON')
    end

    it 'ignores empty handlebars' do
      expect(
        DummyReplacer.new('My name is {{}}').replace
      ).to eql('My name is {{}}')
    end

    it 'ignores unknown helpers and stores errors' do
      replacer = DummyReplacer.new('My name is {{some_unknown_helper(capitalize(john))}} {{swapcase(johnson)}}')
      expect(
        replacer.replace
      ).to eql('My name is {{some_unknown_helper(capitalize(john))}} JOHNSON')
      expect(
        replacer.errors.size
      ).not_to eql(0)
    end

    it 'can pass data as hash' do
      expect(
        DummyReplacer.new('My name is {{user_name()}}').replace({user_name: 'Luke'})
      ).to eql('My name is Luke')
    end

    it 'ignores space inside handlebar' do
      expect(
        DummyReplacer.new('My name is {{     user_name()     }}').replace({user_name: 'Luke'})
      ).to eql('My name is Luke')
    end
  end

  describe '#replace!' do
    it 'raises error when encounters unknown helper' do
      expect {
        DummyReplacer.new('My name is {{some_unknown_helper(john)}}').replace!
      }.to raise_error(NoMethodError)
    end
  end

  describe 'replaceable?' do
    it 'returns true when it is replaceable' do
      expect(
        DummyReplacer.new('My name is {{some_unknown_helper(john)}}').replaceable?
      ).to be(true)
    end

    it 'returns false when it is replaceable' do
      expect(
        DummyReplacer.new('My name is {{some_unknown_helper(john) ').replaceable?
      ).to be(false)
    end
  end
end